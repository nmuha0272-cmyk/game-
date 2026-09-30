extends Node
## Global script (autoload) that remembers who is in the game: their names
## and which character each person picked. The host owns the real list and
## sends a copy to everyone whenever it changes.

signal players_changed
signal game_started

## Player network ID -> {"name": String, "character": Characters.Id}
var players := {}
var game_in_progress := false
## The name typed on the main menu.
var local_player_name := "Player"
## If the host refused to let us in, this says why.
var rejection_reason := ""


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


## Host only: start a fresh list with just the host in it.
func start_hosting() -> void:
	reset()
	players[1] = {"name": local_player_name, "character": Characters.Id.NONE}
	players_changed.emit()


func reset() -> void:
	players.clear()
	game_in_progress = false
	rejection_reason = ""
	players_changed.emit()


func get_character(id: int) -> int:
	return players[id].character if players.has(id) else Characters.Id.NONE


func get_player_name(id: int) -> String:
	return players[id].name if players.has(id) else "Player %d" % id


## Who has picked this character (0 if nobody).
func get_owner_of(character: int) -> int:
	for id in players:
		if players[id].character == character:
			return id
	return 0


func can_start() -> bool:
	if not multiplayer.is_server() or players.is_empty() or game_in_progress:
		return false
	for id in players:
		if players[id].character == Characters.Id.NONE:
			return false
	return true


## Ask the host for a character. The host decides if we get it.
func request_character(character: int) -> void:
	if multiplayer.is_server():
		_try_pick(1, character)
	else:
		_request_character.rpc_id(1, character)


## Host only: start the game once everyone has picked.
func start_game() -> void:
	if can_start():
		_start_game.rpc()


# --- Networking below. Clients ask, the host decides. ---

func _on_connected_to_server() -> void:
	_register.rpc_id(1, local_player_name)


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server() and players.has(id):
		players.erase(id)
		_send_players_to_everyone()


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if game_in_progress:
		_reject.rpc_id(id, "That game has already started.")
		# Give the message a moment to arrive before disconnecting them.
		get_tree().create_timer(0.5).timeout.connect(
				func() -> void: multiplayer.multiplayer_peer.disconnect_peer(id))
		return
	player_name = player_name.strip_edges().left(20)
	if player_name.is_empty():
		player_name = "Player %d" % (players.size() + 1)
	players[id] = {"name": player_name, "character": Characters.Id.NONE}
	_send_players_to_everyone()


@rpc("any_peer", "reliable")
func _request_character(character: int) -> void:
	if multiplayer.is_server():
		_try_pick(multiplayer.get_remote_sender_id(), character)


func _try_pick(id: int, character: int) -> void:
	if game_in_progress or not players.has(id):
		return
	if character != Characters.Id.NONE:
		if not Characters.INFO.has(character):
			return
		var owner_id := get_owner_of(character)
		if owner_id != 0 and owner_id != id:
			return  # Someone else already has it.
	players[id].character = character
	_send_players_to_everyone()


func _send_players_to_everyone() -> void:
	_receive_players.rpc(players)
	players_changed.emit()


@rpc("authority", "reliable")
func _receive_players(new_players: Dictionary) -> void:
	players = new_players
	players_changed.emit()


@rpc("authority", "reliable")
func _reject(reason: String) -> void:
	rejection_reason = reason


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	game_in_progress = true
	game_started.emit()
