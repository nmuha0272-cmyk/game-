extends Node
class_name WebRTCSignaling
## Simple WebRTC signaling for internet multiplayer without Steam.
## Uses public STUN servers and a basic HTTP signaling server.
## For production, deploy your own signaling server.

signal offer_created(offer: String)
signal answer_created(answer: String)
signal ice_candidate(candidate: Dictionary)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed(reason: String)
signal data_received(data: Array)  # [sender_peer_id, packet_data]
signal invite_code_ready(code: String)  # Short code for sharing
signal invite_code_received(code: String)  # When someone joins via code

@export var stun_servers: Array[String] = [
	"stun:stun.l.google.com:19302",
	"stun:stun1.l.google.com:19302",
	"stun:stun2.l.google.com:19302",
	"stun:stun3.l.google.com:19302",
	"stun:stun4.l.google.com:19302",
]

@export var signaling_server: String = "https://your-signaling-server.com"  # Replace with your own

var _peer: WebRTCPeerConnection
var _data_channel: WebRTCDataChannel
var _is_host: bool = false
var _connected_peers: Dictionary = {}  # peer_id -> WebRTCDataChannel
var _pending_offer: String = ""
var _pending_ice: Array = []
var _invite_code: String = ""

func _ready() -> void:
	_peer = WebRTCPeerConnection.new()
	_peer.initialize(_build_rtc_config())
	
	_peer.session_description_created.connect(_on_session_description)
	_peer.ice_candidate_created.connect(_on_ice_candidate)
	_peer.connection_state_changed.connect(_on_connection_state_changed)
	
	# For host: create data channel for each connecting peer
	_peer.data_channel_received.connect(_on_data_channel_received)

func _build_rtc_config() -> Dictionary:
	var ice_servers: Array[Dictionary] = []
	for server in stun_servers:
		ice_servers.append({"urls": [server]})
	return {"iceServers": ice_servers}

## Host a game - creates offer that others can use to join
func host_game(max_peers: int = 3) -> void:
	_is_host = true
	_connected_peers.clear()
	_pending_offer = ""
	_pending_ice.clear()
	
	# Create data channel for reliable ordered messaging (like ENet)
	var channel_config = WebRTCPeerConnection.DataChannelConfiguration.new()
	channel_config.ordered = true
	channel_config.reliable = true
	channel_config.id = 0
	
	_data_channel = _peer.create_data_channel("game", channel_config)
	_setup_data_channel(_data_channel)
	
	# Create offer
	_peer.create_offer()

## Generate a short invite code from the current offer
func generate_invite_code() -> String:
	if _pending_offer.is_empty():
		return ""
	
	# Compress offer SDP into a shorter code
	var compressed = _compress_sdp(_pending_offer)
	_invites_code = compressed
	invite_code_ready.emit(compressed)
	return compressed

## Join using an invite code (short code from host)
func join_with_invite_code(code: String) -> void:
	if code.is_empty():
		connection_failed.emit("Invalid invite code")
		return
	
	var offer_sdp = _decompress_sdp(code)
	if offer_sdp.is_empty():
		connection_failed.emit("Invalid invite code format")
		return
	
	_is_host = false
	_connected_peers.clear()
	_pending_ice.clear()
	
	var offer = WebRTCPeerConnection.SessionDescription.new()
	offer.type = WebRTCPeerConnection.SessionDescription.TYPE_OFFER
	offer.sdp = offer_sdp
	_peer.set_remote_description(offer)
	
	# Create answer
	_peer.create_answer()
	
	invite_code_received.emit(code)

## Join a game using an offer (from host)
func join_game(offer_sdp: String) -> void:
	_is_host = false
	_connected_peers.clear()
	_pending_ice.clear()
	
	var offer = WebRTCPeerConnection.SessionDescription.new()
	offer.type = WebRTCPeerConnection.SessionDescription.TYPE_OFFER
	offer.sdp = offer_sdp
	_peer.set_remote_description(offer)
	
	# Create answer
	_peer.create_answer()

## Compress SDP into short invite code
func _compress_sdp(sdp: String) -> String:
	# Extract just the important parts and base64 encode
	var lines = sdp.split("\n")
	var essential = []
	for line in lines:
		if line.begins_with("v=") or line.begins_with("o=") or line.begins_with("s=") \
		   or line.begins_with("t=") or line.begins_with("a=ice-") \
		   or line.begins_with("a=fingerprint:") or line.begins_with("a=setup:") \
		   or line.begins_with("a=mid:") or line.begins_with("a=sendrecv") \
		   or line.begins_with("m=application") or line.begins_with("c="):
			essential.append(line)
	
	var compressed = "\n".join(essential)
	var bytes = compressed.to_utf8_buffer()
	var encoded = bytes.encode_base64()
	
	# Split into groups of 4 for readability
	var result = ""
	for i in range(0, encoded.length(), 4):
		if i > 0:
			result += "-"
		result += encoded.substr(i, 4)
	
	return "DW-" + result  # Deepwell prefix

## Decompress invite code back to SDP
func _decompress_sdp(code: String) -> String:
	if not code.begins_with("DW-"):
		return ""
	
	var encoded = code.substr(3).replace("-", "")
	var bytes = encoded.decode_base64()
	if bytes.size() == 0:
		return ""
	
	var compressed = bytes.get_string_from_utf8()
	
	# Reconstruct minimal valid SDP
	var base_sdp = """v=0
o=- 0 0 IN IP4 127.0.0.1
s=Deepwell
t=0 0
a=group:BUNDLE data
a=msid-semantic: WMS
""" + compressed + """
"""
	return base_sdp
	
	# TODO: Implement HTTP polling to signaling server
	# For now, manual SDP exchange
	connection_failed.emit("Automatic matchmaking not implemented. Use manual SDP exchange.")

## Send game data to all connected peers
func send_game_data(data: Array) -> void:
	var json = JSON.stringify(data)
	for peer_id in _connected_peers:
		var channel = _connected_peers[peer_id]
		if channel.ready_state == WebRTCDataChannel.STATE_OPEN:
			var err = channel.put_packet(json.to_utf8_buffer())
			if err != OK:
				push_error("Failed to send to peer %d: %s" % [peer_id, err])

## Send to specific peer
func send_to_peer(peer_id: int, data: Array) -> void:
	if _connected_peers.has(peer_id):
		var channel = _connected_peers[peer_id]
		if channel.ready_state == WebRTCDataChannel.STATE_OPEN:
			var json = JSON.stringify(data)
			channel.put_packet(json.to_utf8_buffer())

func _setup_data_channel(channel: WebRTCDataChannel) -> void:
	channel.message_received.connect(_on_data_message.bind(channel))
	channel.closed.connect(_on_data_channel_closed.bind(channel))
	
	var peer_id = _generate_peer_id()
	_connected_peers[peer_id] = channel
	peer_connected.emit(peer_id)

func _generate_peer_id() -> int:
	var id := 1
	while _connected_peers.has(id):
		id += 1
	return id

# --- WebRTC Callbacks ---

func _on_session_description(type: int, sdp: String) -> void:
	if type == WebRTCPeerConnection.SessionDescription.TYPE_OFFER:
		offer_created.emit(sdp)
	elif type == WebRTCPeerConnection.SessionDescription.TYPE_ANSWER:
		answer_created.emit(sdp)

func _on_ice_candidate(mid_name: String, index: int, sdp: String) -> void:
	ice_candidate.emit({"mid": mid_name, "index": index, "sdp": sdp})

func _on_connection_state_changed(state: int) -> void:
	# WebRTCPeerConnection.STATE_CONNECTED = 2
	# WebRTCPeerConnection.STATE_FAILED = 4
	# WebRTCPeerConnection.STATE_CLOSED = 5
	if state == 4:
		connection_failed.emit("WebRTC connection failed")
	elif state == 5:
		for peer_id in _connected_peers:
			peer_disconnected.emit(peer_id)
		_connected_peers.clear()

func _on_data_channel_received(channel: WebRTCDataChannel) -> void:
	_setup_data_channel(channel)

func _on_data_message(data: PackedByteArray, channel: WebRTCDataChannel) -> void:
	var text = data.get_string_from_utf8()
	var json = JSON.parse_string(text)
	if json is Array:
		# Find sender peer ID
		var sender_id = 0
		for pid in _connected_peers:
			if _connected_peers[pid] == channel:
				sender_id = pid
				break
		# Emit signal for WebRTCMultiplayerPeer: [sender_id, packet_data]
		data_received.emit([sender_id, json])

func _on_data_channel_closed(channel: WebRTCDataChannel) -> void:
	for peer_id in _connected_peers:
		if _connected_peers[peer_id] == channel:
			peer_disconnected.emit(peer_id)
			_connected_peers.erase(peer_id)
			break

## Add ICE candidate from remote peer
func add_ice_candidate(candidate: Dictionary) -> void:
	_peer.add_ice_candidate(candidate.mid, candidate.index, candidate.sdp)

## Set remote answer (for host)
func set_remote_answer(answer_sdp: String) -> void:
	var answer = WebRTCPeerConnection.SessionDescription.new()
	answer.type = WebRTCPeerConnection.SessionDescription.TYPE_ANSWER
	answer.sdp = answer_sdp
	_peer.set_remote_description(answer)

## Clean up
func close() -> void:
	for peer_id in _connected_peers:
		_connected_peers[peer_id].close()
	_connected_peers.clear()
	_peer.close()
	_is_host = false