extends Node
## Decides what's on screen: home screen (the Deepwell car) -> lobby ->
## opening cutscene -> game level.
## Only the host loads the level. The LevelSpawner then copies it
## to everyone in the lobby.

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

@onready var level_root: Node = $Level
@onready var opening_cutscene = $OpeningCutscene
@onready var menu = $MainMenu
@onready var lobby = $Lobby
@onready var settings_menu: MenuBase = $Menus/Settings


func _ready() -> void:
	# Show main menu right away
	_show_main_menu()
	
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)
	menu.solo_requested.connect(_on_solo_requested)
	lobby.start_requested.connect(_on_start_requested)
	lobby.leave_requested.connect(_on_leave_requested)
	$Menus/PauseMenu.leave_requested.connect(_on_leave_requested)
	menu.settings_requested.connect(settings_menu.open)
	GameState.players_changed.connect(_update_home_taken)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	GameState.game_started.connect(_on_game_started)
	GameState.restart_requested.connect(_restart_level)
	GameState.chapter_completed.connect(_on_chapter_completed)
	GameState.next_chapter_requested.connect(_on_next_chapter)
	
	# Connect cutscene finished signal
	if opening_cutscene:
		opening_cutscene.finished.connect(_on_opening_finished)


func _on_opening_finished() -> void:
	# After cutscene, load the actual game level
	if multiplayer.is_server():
		_current_level = STORY_START
		level_root.add_child(load(STORY_START).instantiate())


func _show_main_menu(message := "") -> void:
	menu.hide()
	_open_home(message)


# ---------------------------------------------------------------- home screen

func _open_home(message := "") -> void:
	_close_home()
	home = HOME_SCENE.instantiate()
	home.embedded = true
	add_child(home)
	var ui: Control = home.get_menu_ui()
	ui.host_requested.connect(_on_home_host)
	ui.join_requested.connect(_on_home_join)
	ui.settings_requested.connect(settings_menu.open)
	home.character_confirmed.connect(_on_home_character)
	home.arrived.connect(_on_home_arrived)
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
	home.enter_select()


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


## The car reached the station: on to the lobby (the host presses Start there).
func _on_home_arrived(_id: String) -> void:
	_close_home()
	lobby.show()
	lobby.refresh()


## Seats other players already picked show as TAKEN in the car.
func _update_home_taken() -> void:
	if not is_instance_valid(home):
		return
	var mine := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	for seat: String in HOME_CHARACTERS:
		var is_taken := false
		for id: int in GameState.players:
			if id != mine and GameState.players[id].character == HOME_CHARACTERS[seat]:
				is_taken = true
		home.set_character_taken(seat, is_taken)


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
	if is_instance_valid(home):
		home.enter_select()
		return
	_show_lobby()
	# The player list arrives from the host a moment later.


func _on_start_requested() -> void:
	GameState.start_game()


func _on_game_started() -> void:
	_close_home()
	lobby.hide()
	menu.hide()
	# Play the opening cutscene before starting the game
	if opening_cutscene:
		opening_cutscene.show()
		opening_cutscene.play_cutscene()


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
	level_root.add_child(load(path).instantiate())
	await get_tree().create_timer(1.0).timeout
	_fade_in_everyone.rpc()


## The chapter ended: everyone goes back to the lobby (Chapter 2 comes later).
func _on_chapter_completed(text: String) -> void:
	# Only the host removes the level; that removal reaches everyone.
	if multiplayer.is_server():
		for child in level_root.get_children():
			child.queue_free()
	GameState.game_in_progress = false
	GameState.checkpoint_name = ""
	GameState.checkpoint_order = 0
	GameState.checkpoint_inventories = {}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$ScreenFader.fade_in(1.0)
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
	get_window().title = "Subject Zero"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lobby.hide()
	menu.set_buttons_enabled(true)
	menu.show_status(message)
	_show_main_menu(message)


func _typed_name() -> String:
	var typed: String = menu.get_player_name()
	return typed if not typed.is_empty() else "Player"
