extends Node
## Global script (autoload) that hosts or joins online games.
## Supports ENet (LAN/direct IP) and WebRTC (internet via STUN).

signal connected_to_server
signal connection_failed
signal server_disconnected
signal webrtc_offer_created(offer: String)
signal webrtc_answer_created(answer: String)
signal webrtc_ice_candidate(candidate: Dictionary)
signal webrtc_remote_offer_received(offer: String)
signal webrtc_remote_answer_received(answer: String)

enum Backend { ENET, WEBRTC }

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var current_backend: Backend = Backend.ENET
var _webrtc_signaling: WebRTCSignaling
var _pending_ice_candidates: Array = []

func _ready() -> void:
	_webrtc_signaling = WebRTCSignaling.new()
	add_child(_webrtc_signaling)
	
	_webrtc_signaling.offer_created.connect(_on_webrtc_offer_created)
	_webrtc_signaling.answer_created.connect(_on_webrtc_answer_created)
	_webrtc_signaling.ice_candidate.connect(_on_webrtc_ice_candidate)
	_webrtc_signaling.peer_connected.connect(_on_webrtc_peer_connected)
	_webrtc_signaling.peer_disconnected.connect(_on_webrtc_peer_disconnected)
	_webrtc_signaling.connection_failed.connect(_on_webrtc_connection_failed)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Host a game using ENet (LAN / direct IP with port forwarding)
func host_game_enet(port := DEFAULT_PORT) -> Error:
	current_backend = Backend.ENET
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK

## Join a game using ENet (LAN / direct IP)
func join_game_enet(address: String, port := DEFAULT_PORT) -> Error:
	current_backend = Backend.ENET
	if address.strip_edges().is_empty():
		address = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK

## Host a game using WebRTC (internet play via STUN)
## Returns the offer SDP that must be shared with joining players
func host_game_webrtc() -> String:
	current_backend = Backend.WEBRTC
	_pending_ice_candidates.clear()
	_webrtc_signaling.host_game(MAX_PLAYERS - 1)
	
	# Create WebRTCMultiplayerPeer for Godot's high-level multiplayer
	var peer = WebRTCMultiplayerPeer.new()
	peer.create_from_signaling(_webrtc_signaling)
	multiplayer.multiplayer_peer = peer
	
	# The offer will be emitted via signal
	return ""  # Offer comes via webrtc_offer_created signal

## Join a game using WebRTC (internet play)
## Requires the host's offer SDP
func join_game_webrtc(offer_sdp: String) -> void:
	current_backend = Backend.WEBRTC
	_pending_ice_candidates.clear()
	_webrtc_signaling.join_game(offer_sdp)
	
	var peer = WebRTCMultiplayerPeer.new()
	peer.create_from_signaling(_webrtc_signaling)
	multiplayer.multiplayer_peer = peer

## Join a game using an invite code (short code like DW-ABCD-1234)
func join_game_webrtc_with_code(code: String) -> void:
	current_backend = Backend.WEBRTC
	_pending_ice_candidates.clear()
	_webrtc_signaling.join_with_invite_code(code)
	
	var peer = WebRTCMultiplayerPeer.new()
	peer.create_from_signaling(_webrtc_signaling)
	multiplayer.multiplayer_peer = peer

## Call this when you receive an offer from the host (via chat, Discord, etc.)
func receive_webrtc_offer(offer_sdp: String) -> void:
	if current_backend != Backend.WEBRTC:
		return
	webrtc_remote_offer_received.emit(offer_sdp)

## Call this when you receive an answer from a joining player
func receive_webrtc_answer(answer_sdp: String) -> void:
	if current_backend != Backend.WEBRTC:
		return
	webrtc_remote_answer_received.emit(answer_sdp)
	_webrtc_signaling.set_remote_answer(answer_sdp)

## Call this when you receive an ICE candidate
func receive_webrtc_ice_candidate(candidate: Dictionary) -> void:
	if current_backend != Backend.WEBRTC:
		_pending_ice_candidates.append(candidate)
		return
	_webrtc_signaling.add_ice_candidate(candidate)

## Disconnect and go back to offline
func leave_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_webrtc_signaling.close()
	current_backend = Backend.ENET

func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer

func get_backend_name() -> String:
	return "ENET" if current_backend == Backend.ENET else "WebRTC"

# --- Internal WebRTC Signal Handlers ---

func _on_webrtc_offer_created(offer: String) -> void:
	webrtc_offer_created.emit(offer)

func _on_webrtc_answer_created(answer: String) -> void:
	webrtc_answer_created.emit(answer)

func _on_webrtc_ice_candidate(candidate: Dictionary) -> void:
	webrtc_ice_candidate.emit(candidate)

func _on_webrtc_peer_connected(peer_id: int) -> void:
	# Process pending ICE candidates
	for candidate in _pending_ice_candidates:
		_webrtc_signaling.add_ice_candidate(candidate)
	_pending_ice_candidates.clear()
	connected_to_server.emit()

func _on_webrtc_peer_disconnected(peer_id: int) -> void:
	server_disconnected.emit()

func _on_webrtc_connection_failed(reason: String) -> void:
	leave_game()
	connection_failed.emit(reason)

# --- For WebRTCMultiplayerPeer to receive messages ---
func _on_webrtc_message(data: Array) -> void:
	# This is called from WebRTCSignaling when data arrives
	# The WebRTCMultiplayerPeer handles this internally
	pass

# --- Existing ENet Callbacks ---

func _on_connected_to_server() -> void:
	connected_to_server.emit()

func _on_connection_failed() -> void:
	leave_game()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	leave_game()
	server_disconnected.emit()