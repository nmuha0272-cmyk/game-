extends Node
## Global script (autoload) that hosts or joins online games.
## Anyone can reach it from any script by typing `NetworkManager`.

signal connected_to_server
signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Start a game on this computer that others can join. Returns OK on success.
func host_game(port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	# The host is a player too, so only MAX_PLAYERS - 1 others can join.
	var error := peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Try to join a host at this IP address. The result arrives later as the
## `connected_to_server` or `connection_failed` signal.
func join_game(address: String, port := DEFAULT_PORT) -> Error:
	if address.strip_edges().is_empty():
		address = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Disconnect and go back to playing offline.
func leave_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func _on_connected_to_server() -> void:
	connected_to_server.emit()


func _on_connection_failed() -> void:
	leave_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	leave_game()
	server_disconnected.emit()
