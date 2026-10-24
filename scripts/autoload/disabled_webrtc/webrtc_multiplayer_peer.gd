extends MultiplayerPeer
class_name WebRTCMultiplayerPeer

## Custom MultiplayerPeer that uses WebRTC data channels for networking.
## Works with WebRTCSignaling for NAT traversal.

signal peer_connected(id: int)
signal peer_disconnected(id: int)

var _signaling: WebRTCSignaling
var _peer_id: int = 1  # Host is always 1
var _connected_peers: Dictionary = {}  # peer_id -> WebRTCDataChannel
var _packet_queue: Array = []  # Queue of (peer_id, packet) for polling
var _target_peer: int = 0  # 0 = broadcast, else specific peer
var _transfer_mode: int = 0  # 0 = unreliable, 1 = reliable, 2 = unreliable ordered
var _is_server: bool = false
var _refusing_new_connections: bool = false

func _ready() -> void:
	# Find the signaling instance
	_signaling = get_node_or_null("/root/WebRTCSignaling") or get_node_or_null("../WebRTCSignaling")
	if not _signaling:
		push_error("WebRTCSignaling not found! Make sure it's in the scene tree.")

func create_from_signaling(signaling: WebRTCSignaling) -> void:
	_signaling = signaling
	
	_signaling.peer_connected.connect(_on_peer_connected)
	_signaling.peer_disconnected.connect(_on_peer_disconnected)
	
	# Set up packet receive callback
	_signaling.connect("data_received", _on_data_received)

## Called by NetworkManager when hosting
func _setup_as_host() -> void:
	_is_server = true
	_peer_id = 1
	_refusing_new_connections = false

## Called by NetworkManager when joining
func _setup_as_client() -> void:
	_is_server = false
	_peer_id = 1  # Will be assigned by host

# --- MultiplayerPeer Interface ---

func set_target_peer(id: int) -> void:
	_target_peer = id

func set_transfer_mode(mode: int) -> void:
	_transfer_mode = mode

func get_packet() -> PackedByteArray:
	if _packet_queue.is_empty():
		return PackedByteArray()
	var packet = _packet_queue.pop_front()
	return packet[1]  # Return just the data

func get_packet_peer() -> int:
	if _packet_queue.is_empty():
		return 0
	return _packet_queue[0][0]  # Return peer_id

func put_packet(data: PackedByteArray) -> Error:
	if not _signaling:
		return ERR_UNCONFIGURED
	
	if _target_peer == 0:
		# Broadcast to all
		_signaling.send_game_data(data)
	else:
		# Send to specific peer
		_signaling.send_to_peer(_target_peer, data)
	return OK

func get_available_packet_count() -> int:
	return _packet_queue.size()

# --- Connection Management ---

func _on_peer_connected(peer_id: int) -> void:
	_connected_peers[peer_id] = true
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_connected_peers.erase(peer_id)
	peer_disconnected.emit(peer_id)

func _on_data_received(data: Array) -> void:
	# data format: [sender_id, packet_data]
	if data.size() >= 2:
		var sender_id = data[0]
		var packet_data = data[1]
		if packet_data is PackedByteArray:
			_packet_queue.append([sender_id, packet_data])
		elif packet_data is Array:
			_packet_queue.append([sender_id, PackedByteArray(packet_data)])

# --- Required Virtual Methods ---

func _get_unique_id() -> int:
	return _peer_id

func _get_connected_peers() -> Array[int]:
	var peers = _connected_peers.keys()
	peers.sort()
	return peers

func _get_connection_status() -> ConnectionStatus:
	if _signaling and _connected_peers.size() > 0:
		return ConnectionStatus.CONNECTED
	elif _signaling and _is_server:
		return ConnectionStatus.CONNECTING
	return ConnectionStatus.DISCONNECTED

func _poll() -> void:
	# WebRTC is event-driven, nothing to poll
	pass

func _close() -> void:
	_connected_peers.clear()
	_packet_queue.clear()
	if _signaling:
		_signaling.close()
	_is_server = false