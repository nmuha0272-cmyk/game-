extends Node
## Global script (autoload) that remembers who is in the game: their names
## and which character each person picked. The host owns the real list and
## sends a copy to everyone whenever it changes.

signal players_changed
signal game_started
## The whole team went down: main.gd reloads the level from the checkpoint.
signal restart_requested
signal journal_changed

## Player network ID -> {"name": String, "character": Characters.Id}
var players := {}
var game_in_progress := false
## The name typed on the main menu.
var local_player_name := "Player"
## If the host refused to let us in, this says why.
var rejection_reason := ""
## True while a menu (pause, journal, settings) is open on this computer,
## so the player doesn't walk around or use things behind it.
var menu_open := false

## The last checkpoint reached (the host decides; used when restarting).
var checkpoint_name := ""
var checkpoint_order := 0
## Everyone's gear when the checkpoint was reached (network ID -> slots).
var checkpoint_inventories := {}
## Host only: what the team has already done in this chapter (doors opened,
## locks undone, puzzles solved). A wipe reloads the level, then this puts
## it all back, so nothing has to be done twice. Key: the node's path inside
## the level. Cleared when a new chapter (or a new game) starts.
var level_progress := {}
## Lore entry IDs the team has found. Shared by everyone.
var journal: Array = []
## Whether flashlight batteries drain (Chapter 1 turns this on in the stairwell).
var flashlight_drain := true

signal chapter_completed(text: String)
## The next chapter starts (path of its level scene).
signal next_chapter_requested(path: String)


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
	checkpoint_name = ""
	checkpoint_order = 0
	checkpoint_inventories = {}
	level_progress = {}
	journal = []
	menu_open = false
	players_changed.emit()


func get_character(id: int) -> int:
	return players[id].character if players.has(id) else Characters.Id.NONE


func get_player_name(id: int) -> String:
	return players[id].name if players.has(id) else "Player %d" % id


## True if someone in the team plays this character. Puzzles use this to
## turn on backup solutions when a character is missing.
func team_has(character: int) -> bool:
	return get_owner_of(character) != 0


## Who has picked this character (0 if nobody).
func get_owner_of(character: int) -> int:
	for id in players:
		if players[id].character == character:
			return id
	return 0


## Subject Zero plays solo or online co-op: 1 to 4 players. Puzzles that
## would need two people get solo-friendly behaviour when is_solo().
const MIN_PLAYERS := 1


func has_enough_players() -> bool:
	return players.size() >= MIN_PLAYERS


## True when there is only one player in the game.
func is_solo() -> bool:
	return players.size() == 1


func can_start() -> bool:
	if not multiplayer.is_server() or not has_enough_players() or game_in_progress:
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



# --- Checkpoints and restarting -------------------------------------------

## Host only: the team reached a checkpoint. Save everyone's gear.
func server_reach_checkpoint(checkpoint: Checkpoint) -> void:
	checkpoint_name = checkpoint.name
	checkpoint_order = checkpoint.order
	checkpoint_inventories.clear()
	for player: Player in get_tree().get_nodes_in_group("players"):
		checkpoint_inventories[player.name.to_int()] = player.inventory.slots.duplicate(true)
	_announce.rpc("Checkpoint reached.")


## Host only: remember that a door/lock/puzzle in the level is done (or not
## any more, e.g. a door someone closed again). `node` must have a
## server_restore() method that puts it back in its "done" state.
func server_save_progress(node: Node, done: bool) -> void:
	if not multiplayer.is_server() or not node.is_inside_tree():
		return
	var level := _level_of(node)
	if level == null:
		return
	var key := str(level.get_path_to(node))
	if done:
		level_progress[key] = true
	else:
		level_progress.erase(key)


## Host only, after a wipe reloaded the level: put back everything the team
## had already done. Puzzle gates go first, so the pieces that feed them
## don't announce "solved!" a second time.
func server_restore_progress(level: Node) -> void:
	if not multiplayer.is_server() or level == null:
		return
	var nodes: Array[Node] = []
	for key: String in level_progress.keys():
		var node := level.get_node_or_null(NodePath(key))
		if node and node.has_method("server_restore"):
			nodes.append(node)
	nodes.sort_custom(func(a: Node, b: Node) -> bool: return a is PuzzleGate and not b is PuzzleGate)
	for node in nodes:
		node.server_restore()


func _level_of(node: Node) -> Node:
	# The level is the child of Main's "Level" node.
	while node and not (node.get_parent() and node.get_parent().name == "Level"):
		node = node.get_parent()
	return node


## Host only: everyone is down. Fade out on every screen, then restart.
func server_team_wiped(text := "Everyone is down...\nBack to the last checkpoint.") -> void:
	_show_wipe.rpc(text)
	await get_tree().create_timer(3.0).timeout
	restart_requested.emit()


@rpc("authority", "call_local", "reliable")
func _show_wipe(text: String) -> void:
	get_tree().call_group("screen_fader", "fade_out", text)


@rpc("authority", "call_local", "reliable")
func _announce(text: String) -> void:
	get_tree().call_group("player_hud", "show_message", text)


# --- Journal (lore) -------------------------------------------------------

## Host only: someone found a lore entry. Everyone gets it in their journal.
func server_unlock_lore(entry_id: String, finder_id: int) -> void:
	if not multiplayer.is_server() or entry_id in journal:
		return
	_unlock_lore.rpc(entry_id, finder_id)


@rpc("authority", "call_local", "reliable")
func _unlock_lore(entry_id: String, finder_id: int) -> void:
	if entry_id in journal:
		return
	journal.append(entry_id)
	journal_changed.emit()
	var entry := Lore.get_entry(entry_id)
	if entry:
		get_tree().call_group("player_hud", "show_message", "%s found: %s  (J to read)" % [
				get_player_name(finder_id), entry.title])



# --- Chapter flow --------------------------------------------------------

## Host only: turn flashlight battery drain on or off for everyone.
func server_set_flashlight_drain(value: bool) -> void:
	if multiplayer.is_server():
		_set_flashlight_drain.rpc(value)


@rpc("authority", "call_local", "reliable")
func _set_flashlight_drain(value: bool) -> void:
	flashlight_drain = value
	if value:
		get_tree().call_group("player_hud", "show_message", "Your flashlight is draining. Share batteries.")


## Host only: the chapter is over (main.gd goes back to the lobby).
## Host only: straight on to the next chapter (everyone keeps playing).
func server_next_chapter(path: String) -> void:
	if multiplayer.is_server():
		_next_chapter.rpc(path)


@rpc("authority", "call_local", "reliable")
func _next_chapter(path: String) -> void:
	checkpoint_name = ""
	checkpoint_order = 0
	checkpoint_inventories = {}
	level_progress = {}
	next_chapter_requested.emit(path)


func server_complete_chapter(text: String) -> void:
	if multiplayer.is_server():
		_complete_chapter.rpc(text)


@rpc("authority", "call_local", "reliable")
func _complete_chapter(text: String) -> void:
	chapter_completed.emit(text)
