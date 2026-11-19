extends Node
## Decides what's on screen: home screen (the Deepwell car, where everyone
## picks their character and the team talks) -> the car stops at the gate ->
## opening cutscene -> game level.
## Only the host loads the level. The LevelSpawner then copies it
## to everyone.

## The game is story-based: pressing Start always begins the story, and
## chapters follow one after another. Chapter 1 is the first.
## DEVELOPERS: to test the test room or Puzzle Lab with friends, temporarily
## change this to "res://scenes/test_room/test_room.tscn" or
## "res://scenes/test_room/puzzle_lab.tscn" (don't commit that change).
const STORY_START := "res://scenes/chapters/chapter_1/chapter_1.tscn"

## The start screen: a car on a night road; Host/Join, then pick your
## character in the car, then it drives up to the station. The old 2D menu
## ($MainMenu) is kept hidden (the playtest harness still uses it).
const HOME_SCENE := preload("res://scenes/main_menu/deepwell/main_menu_car.tscn")
## The car's seats -> the game's characters.
const HOME_CHARACTERS := {
	"eli": Characters.Id.SON, "cole": Characters.Id.GUARD,
	"nora": Characters.Id.JOURNALIST, "walter": Characters.Id.ENGINEER,
}

var _current_level := STORY_START
var home: Node3D
var _lobby_for_car_select := false
## Network ids of the players whose car has reached the gate.
var _arrived_ids := {}
## Where the host's opening is: "menu", "road", "meeting" or "select".
var _opening_phase := "menu"
## Host: who voted to skip the cutscene that's playing (network id -> true).
var _skip_votes := {}
## Client: the host put us into the opening (we joined while it was playing).
var _joined_opening := false

@onready var level_root: Node = $Level
@onready var opening_cutscene = $OpeningCutscene
@onready var menu = $MainMenu
@onready var lobby = $Lobby
@onready var settings_menu: MenuBase = $Menus/Settings


func _ready() -> void:
	# Show main menu right away (the studio logo plays on top of it first).
	_show_main_menu()
	StudioLogo.play_on(self)
	
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)
	menu.solo_requested.connect(_on_solo_requested)
	lobby.start_requested.connect(_on_lobby_start)
	lobby.leave_requested.connect(_on_leave_requested)
	$Menus/PauseMenu.leave_requested.connect(_on_leave_requested)
	menu.settings_requested.connect(settings_menu.open)
	GameState.players_changed.connect(_update_home_taken)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	GameState.game_started.connect(_on_game_started)
	GameState.restart_requested.connect(_restart_level)
	GameState.chapter_completed.connect(_on_chapter_completed)
	GameState.next_chapter_requested.connect(_on_next_chapter)
	GameState.load_requested.connect(_load_saved_level)
	$Menus/PauseMenu.save_requested.connect(_quick_save)
	$Menus/PauseMenu.load_requested.connect(_quick_load)
	
	# Connect cutscene finished signal
	if opening_cutscene:
		opening_cutscene.finished.connect(_on_opening_finished)


func _on_opening_finished() -> void:
	# After cutscene, load the actual game level
	if multiplayer.is_server():
		# CONTINUE on the home screen: start from the save instead.
		if GameState.continue_on_start:
			GameState.continue_on_start = false
			if GameState.server_load_game():
				return
		_current_level = STORY_START
		GameState.current_level = STORY_START
		# (The team's car is parked by the main building in chapter_1.tscn.)
		level_root.add_child(load(STORY_START).instantiate())


func _show_main_menu(message := "") -> void:
	menu.hide()
	_open_home(message)


# ---------------------------------------------------------------- home screen

func _open_home(message := "") -> void:
	_close_home()
	_arrived_ids.clear()
	home = HOME_SCENE.instantiate()
	home.embedded = true
	add_child(home)
	var ui: Control = home.get_menu_ui()
	ui.host_requested.connect(_on_home_host)
	ui.continue_requested.connect(_on_home_continue)
	ui.join_requested.connect(_on_home_join)
	ui.settings_requested.connect(settings_menu.open)
	home.character_confirmed.connect(_on_home_character)
	home.arrived.connect(_on_home_arrived)
	home.step_started.connect(_on_home_step)
	home.skip_vote.connect(_on_home_skip_vote)
	home.pick_requested.connect(_on_home_pick)
	home.ready_toggled.connect(GameState.request_set_ready)
	home.start_requested.connect(_on_home_start)
	home.follow = multiplayer.has_multiplayer_peer() and not multiplayer.is_server()
	if not message.is_empty():
		ui.show_status(message, true)


func _close_home() -> void:
	if is_instance_valid(home):
		home.queue_free()
	home = null


func _home_status(text: String, is_error := false) -> void:
	if is_instance_valid(home):
		home.get_menu_ui().show_status(text, is_error)


func _on_home_host(_port: int) -> void:
	# Pressing Esc in the car goes back to the title; hosting again starts fresh.
	if NetworkManager.is_online():
		NetworkManager.leave_game()
	var error := NetworkManager.host_game_enet()
	if error != OK:
		_home_status("Could not host (error %d). Is another copy already hosting?" % error, true)
		return
	GameState.local_player_name = _typed_name()
	GameState.start_hosting()
	get_window().title = "Subject Zero (Host)"
	_lobby_for_car_select = true
	_show_lobby()
	lobby.set_car_select_mode(true)


## CONTINUE: host (alone, or friends can join), pick characters, then the save loads.
func _on_home_continue() -> void:
	_on_home_host(0)
	if NetworkManager.is_online():
		GameState.continue_on_start = true


func _on_home_join(ip: String, port: int) -> void:
	if NetworkManager.is_online():
		NetworkManager.leave_game()
	GameState.local_player_name = _typed_name()
	var error := NetworkManager.join_game_enet(ip, port)
	if error != OK:
		_home_status("Could not start connecting (error %d)." % error, true)


func _on_home_character(id: String) -> void:
	if HOME_CHARACTERS.has(id):
		GameState.request_character(HOME_CHARACTERS[id])


## The car stopped outside the gate. The car is the only place a character
## is picked, so there is no lobby: once every car has arrived, the host
## starts the chapter and the gate cutscene follows the drive, as one
## continuous opening.
func _on_home_arrived(_id: String) -> void:
	_close_home()
	_arrived_ids[multiplayer.get_unique_id()] = true
	if multiplayer.is_server():
		_start_when_ready()
	else:
		_report_arrived.rpc_id(1)


## Host only: record that a client's car has reached the gate.
@rpc("any_peer", "reliable")
func _report_arrived() -> void:
	if multiplayer.is_server():
		_arrived_ids[multiplayer.get_remote_sender_id()] = true


## Host only: start when every player's car has arrived and everyone has a
## character. Wait up to 30s for a slow computer, then start anyway so a
## stalled player can't hold the team up. If someone never picked a
## character, fall back to the lobby so they still can.
func _start_when_ready() -> void:
	var waited := 0.0
	while waited < 30.0:
		if GameState.can_start() and _everyone_arrived():
			GameState.start_game()
			return
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if GameState.can_start():
		GameState.start_game()
	else:
		lobby.show()
		lobby.refresh()


func _everyone_arrived() -> bool:
	for id: int in GameState.players:
		if not _arrived_ids.has(id):
			return false
	return true


## Tells the trunk screen who picked whom (PLAYER 1, 2...), who's ready, and
## whether the host can start. Characters other players picked show TAKEN.
func _update_home_taken() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and not _skip_votes.is_empty():
		# Someone left: drop their vote, and maybe everyone left has voted.
		for id: int in _skip_votes.keys():
			if not GameState.players.has(id):
				_skip_votes.erase(id)
		if not _skip_votes.is_empty() and _skip_votes.size() >= GameState.players.size() and is_instance_valid(home):
			_skip_votes.clear()
			home.skip_scene()
		_send_skip_count()
	if not is_instance_valid(home):
		return
	var mine := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var team := {}
	var number := 0
	for id: int in GameState.players:
		number += 1
		var character: int = GameState.players[id].character
		for seat: String in HOME_CHARACTERS:
			if HOME_CHARACTERS[seat] == character:
				team[seat] = {"player": number, "mine": id == mine, "ready": GameState.players[id].get("ready", false)}
	var is_host := not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	home.set_team(team, is_host and GameState.can_start() and GameState.all_ready(), is_host)


# ---------------------------------------------------------------- the opening, together

## Host: its cutscene moved on; every other screen shows the same step.
func _on_home_step(index: int) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server() or not is_instance_valid(home):
		return
	var phase: String = home.scene_of(index)
	if phase != _opening_phase:
		_opening_phase = phase
		_skip_votes.clear()
		_send_skip_count()
	_home_step.rpc(index)


@rpc("authority", "reliable")
func _home_step(index: int) -> void:
	if is_instance_valid(home):
		home.net_step(index)


## Someone held the skip button. The host's vote skips right away; otherwise
## it skips when every player has voted.
func _on_home_skip_vote(_voting: bool) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_count_skip_vote(1)
	else:
		_send_skip_vote.rpc_id(1)


@rpc("any_peer", "reliable")
func _send_skip_vote() -> void:
	if multiplayer.is_server():
		_count_skip_vote(multiplayer.get_remote_sender_id())


func _count_skip_vote(id: int) -> void:
	_skip_votes[id] = true
	if (id == 1 or _skip_votes.size() >= maxi(GameState.players.size(), 1)) and is_instance_valid(home):
		_skip_votes.clear()
		home.skip_scene()
	_send_skip_count()


func _send_skip_count() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_skip_count.rpc(_skip_votes.size(), maxi(GameState.players.size(), 1))


@rpc("authority", "call_local", "reliable")
func _skip_count(count: int, total: int) -> void:
	if is_instance_valid(home):
		home.set_skip_votes(count, total)


## Picked someone at the trunk ("" = put them back).
func _on_home_pick(seat: String) -> void:
	GameState.request_character(HOME_CHARACTERS.get(seat, Characters.Id.NONE))


## Host pressed Start at the trunk: everyone fades to black, then Chapter 1.
func _on_home_start() -> void:
	if multiplayer.is_server() and GameState.can_start() and GameState.all_ready():
		_begin_from_trunk.rpc()


@rpc("authority", "call_local", "reliable")
func _begin_from_trunk() -> void:
	GameState.opening_played = true
	if is_instance_valid(home):
		home.fade_to_black(1.0)
	if multiplayer.is_server():
		await get_tree().create_timer(1.3).timeout
		GameState.start_game()


## Host: someone joined. If the opening is already playing, they wait on a
## "Joining..." screen and meet the team at the trunk.
func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server() or _opening_phase == "menu" or GameState.game_in_progress:
		return
	_sync_join.rpc_id(id, _opening_phase)


@rpc("authority", "reliable")
func _sync_join(phase: String) -> void:
	_joined_opening = true
	_lobby_for_car_select = false
	lobby.hide()
	menu.hide()
	_open_home()
	home.follow = true
	if phase == "select":
		home.enter_select_now()
	else:
		home.show_joining()
	_update_home_taken()


func _on_host_requested() -> void:
	var error := NetworkManager.host_game_enet()
	if error != OK:
		menu.show_status("Could not host (error %d). Is another copy already hosting?" % error)
		return
	GameState.local_player_name = _typed_name()
	GameState.start_hosting()
	get_window().title = "Subject Zero (Host)"
	_show_lobby()


## Solo mode: host alone, but still show the lobby so you pick your character.
func _on_solo_requested() -> void:
	var error := NetworkManager.host_game_enet()
	if error != OK:
		menu.show_status("Could not start (error %d)." % error)
		return
	GameState.local_player_name = _typed_name()
	GameState.start_hosting()
	get_window().title = "Subject Zero (Solo)"
	_show_lobby()


func _on_join_requested(address: String) -> void:
	GameState.local_player_name = _typed_name()
	var error := NetworkManager.join_game_enet(address)
	if error != OK:
		menu.show_status("Could not start connecting (error %d)." % error)
		return
	menu.set_buttons_enabled(false)
	menu.show_status("Connecting...")


func _on_connected_to_server() -> void:
	get_window().title = "Subject Zero (Player %d)" % multiplayer.get_unique_id()
	if _joined_opening:
		return  # the host already put us into the opening
	if is_instance_valid(home):
		# Wait in the lobby with the others until the host presses Play.
		_lobby_for_car_select = true
		_show_lobby()
		lobby.set_car_select_mode(true)
		return
	_show_lobby()
	# The player list arrives from the host a moment later.


func _on_lobby_start() -> void:
	if _lobby_for_car_select:
		_lobby_for_car_select = false
		lobby.set_car_select_mode(false)
		_open_opening_talk.rpc()
	else:
		_on_start_requested()


@rpc("authority", "call_local", "reliable")
func _open_opening_talk() -> void:
	lobby.hide()
	menu.hide()
	_open_home()
	_opening_phase = "road"
	_skip_votes.clear()
	if is_instance_valid(home):
		home.enter_opening()
		_update_home_taken()
		_send_skip_count()


@rpc("authority", "call_local", "reliable")
func _set_lobby_normal() -> void:
	lobby.set_car_select_mode(false)


func _on_start_requested() -> void:
	_lobby_for_car_select = false
	GameState.start_game()


func _on_game_started() -> void:
	_lobby_for_car_select = false
	_opening_phase = "menu"
	if GameState.opening_played:
		# From the trunk: black, then fade in at the gate once the level is there.
		$ScreenFader.fade_out("", 0.01)
		get_tree().create_timer(1.4).timeout.connect(func() -> void: $ScreenFader.fade_in(1.6))
	_close_home()
	lobby.hide()
	menu.hide()
	# The story opens in the car now (the team talks while Eli drives, on the
	# home screen), so the old newspaper intro is skipped: straight to the level.
	if opening_cutscene:
		opening_cutscene.hide()
	_on_opening_finished()


## Host only: the whole team went down. Reload the level; players appear at
## the last checkpoint with the gear they had there.
func _restart_level() -> void:
	if not multiplayer.is_server():
		return
	for child in level_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	var level: Node = load(_current_level).instantiate()
	level_root.add_child(level)
	# Put back the doors and puzzles the team already did, once every
	# player's copy of the level has loaded.
	await get_tree().create_timer(0.5).timeout
	GameState.server_restore_progress(level)
	_fade_in_everyone.rpc()


@rpc("authority", "call_local", "reliable")
func _fade_in_everyone() -> void:
	get_tree().call_group("screen_fader", "fade_in")


## On to the next chapter: the host swaps the level (that reaches everyone).
func _on_next_chapter(path: String) -> void:
	if not multiplayer.is_server():
		return
	for child in level_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_current_level = path
	GameState.current_level = path
	level_root.add_child(load(path).instantiate())
	await get_tree().create_timer(1.0).timeout
	_fade_in_everyone.rpc()


# ---------------------------------------------------------------- saving

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.game_in_progress or GameState.menu_open or level_root.get_child_count() == 0:
		return
	if event.is_action_pressed("quick_save"):
		_quick_save()
	elif event.is_action_pressed("quick_load"):
		_quick_load()


func _message(text: String) -> void:
	get_tree().call_group("player_hud", "show_message", text)


## F5 (or Save Game in the pause menu). Only the host saves.
func _quick_save() -> void:
	if not multiplayer.is_server():
		_message("Only the host can save the game.")
	elif GameState.server_save_game():
		GameState.server_announce("Game saved.")
	else:
		_message("The game couldn't be saved.")


## F9 (or Load Last Save): everyone goes back to the save together.
func _quick_load() -> void:
	if not multiplayer.is_server():
		_message("Only the host can load the game.")
	elif not GameState.has_save():
		_message("There's no save yet. Press F5 to save.")
	elif not GameState.server_load_game():
		_message("The save couldn't be loaded.")


## Host: load the saved level, put back what the team did, and put everyone
## where they were standing (with the gear they had: see player_spawner.gd).
func _load_saved_level(path: String) -> void:
	if not multiplayer.is_server():
		return
	await get_tree().create_timer(0.6).timeout  # (let "Loading..." fade in)
	_current_level = path
	GameState.current_level = path
	await _restart_level()
	for player: Player in get_tree().get_nodes_in_group("players"):
		var at: Variant = GameState.pending_positions.get(player.name.to_int())
		if at is Vector3:
			player.downed._teleport.rpc_id(player.get_multiplayer_authority(), at)
	GameState.pending_positions = {}
	GameState.server_announce("Game loaded.")


## The chapter ended: everyone goes back to the lobby (Chapter 2 comes later).
func _on_chapter_completed(text: String) -> void:
	# Only the host removes the level; that removal reaches everyone.
	if multiplayer.is_server():
		for child in level_root.get_children():
			child.queue_free()
	GameState.game_in_progress = false
	_lobby_for_car_select = false
	GameState.checkpoint_name = ""
	GameState.checkpoint_order = 0
	GameState.checkpoint_inventories = {}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$ScreenFader.fade_in(1.0)
	if multiplayer.is_server():
		_set_lobby_normal.rpc()
	else:
		lobby.set_car_select_mode(false)
	lobby.show()
	lobby.refresh()
	get_tree().call_group("lobby_message", "show_message", text)


func _on_leave_requested() -> void:
	NetworkManager.leave_game()
	_return_to_menu("")


func _on_connection_failed() -> void:
	_home_status("Could not connect. Check the IP address and that the host is running.", true)
	menu.set_buttons_enabled(true)
	menu.show_status("Could not connect. Check the IP address and that the host is running. The game might also be full (4 players max).")


func _on_server_disconnected() -> void:
	var reason: String = GameState.rejection_reason
	if reason.is_empty():
		reason = "Lost connection to the host."
	_return_to_menu(reason)


func _show_lobby() -> void:
	_close_home()
	menu.hide()
	lobby.show()


func _return_to_menu(message: String) -> void:
	for child in level_root.get_children():
		child.queue_free()
	for open_menu in get_tree().get_nodes_in_group("menus"):
		open_menu.hide()
	$ScreenFader.fade_in(0.1)
	GameState.reset()
	_lobby_for_car_select = false
	_opening_phase = "menu"
	_skip_votes.clear()
	_joined_opening = false
	get_window().title = "Subject Zero"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lobby.hide()
	lobby.set_car_select_mode(false)
	menu.set_buttons_enabled(true)
	menu.show_status(message)
	_show_main_menu(message)


func _typed_name() -> String:
	var typed: String = menu.get_player_name()
	return typed if not typed.is_empty() else "Player"
