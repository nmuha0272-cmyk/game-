extends Node
## Decides what's on screen: main menu -> lobby -> game level.
## Only the host loads the level. The LevelSpawner then copies it
## to everyone in the lobby.

## The game is story-based: pressing Start always begins the story, and
## chapters follow one after another. Chapter 1 is the first.
## DEVELOPERS: to test the test room or Puzzle Lab with friends, temporarily
## change this to "res://scenes/test_room/test_room.tscn" or
## "res://scenes/test_room/puzzle_lab.tscn" (don't commit that change).
const STORY_START := "res://scenes/chapters/chapter_1/chapter_1.tscn"

var _current_level := STORY_START

@onready var level_root: Node = $Level
@onready var menu = $MainMenu
@onready var lobby = $Lobby
@onready var settings_menu: MenuBase = $Menus/Settings


func _ready() -> void:
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)
	lobby.start_requested.connect(_on_start_requested)
	lobby.leave_requested.connect(_on_leave_requested)
	$Menus/PauseMenu.leave_requested.connect(_on_leave_requested)
	menu.settings_requested.connect(settings_menu.open)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	GameState.game_started.connect(_on_game_started)
	GameState.restart_requested.connect(_restart_level)
	GameState.chapter_completed.connect(_on_chapter_completed)


func _on_host_requested() -> void:
	var error := NetworkManager.host_game()
	if error != OK:
		menu.show_status("Could not host (error %d). Is another copy already hosting?" % error)
		return
	GameState.local_player_name = _typed_name()
	GameState.start_hosting()
	get_window().title = "Subject Zero (Host)"
	_show_lobby()


func _on_join_requested(address: String) -> void:
	GameState.local_player_name = _typed_name()
	var error := NetworkManager.join_game(address)
	if error != OK:
		menu.show_status("Could not start connecting (error %d)." % error)
		return
	menu.set_buttons_enabled(false)
	menu.show_status("Connecting...")


func _on_connected_to_server() -> void:
	get_window().title = "Subject Zero (Player %d)" % multiplayer.get_unique_id()
	_show_lobby()
	# The player list arrives from the host a moment later.


func _on_start_requested() -> void:
	GameState.start_game()


func _on_game_started() -> void:
	lobby.hide()
	if multiplayer.is_server():
		_current_level = STORY_START
		level_root.add_child(load(STORY_START).instantiate())


## Host only: the whole team went down. Reload the level; players appear at
## the last checkpoint with the gear they had there.
func _restart_level() -> void:
	if not multiplayer.is_server():
		return
	for child in level_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	level_root.add_child(load(_current_level).instantiate())
	_fade_in_everyone.rpc()


@rpc("authority", "call_local", "reliable")
func _fade_in_everyone() -> void:
	get_tree().call_group("screen_fader", "fade_in")


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
	menu.set_buttons_enabled(true)
	menu.show_status("Could not connect. Check the IP address and that the host is running. The game might also be full (4 players max).")


func _on_server_disconnected() -> void:
	var reason: String = GameState.rejection_reason
	if reason.is_empty():
		reason = "Lost connection to the host."
	_return_to_menu(reason)


func _show_lobby() -> void:
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
	menu.show()


func _typed_name() -> String:
	var typed: String = menu.get_player_name()
	return typed if not typed.is_empty() else "Player"
