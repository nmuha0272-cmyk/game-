extends Node
## Decides what's on screen: the main menu, or the game level.
## Only the host loads the level. The LevelSpawner then copies it
## to everyone who joins.

const LEVEL_SCENE := preload("res://scenes/test_room/test_room.tscn")

@onready var level_root: Node = $Level
@onready var menu = $MainMenu


func _ready() -> void:
	menu.host_requested.connect(_on_host_requested)
	menu.join_requested.connect(_on_join_requested)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)


func _on_host_requested() -> void:
	var error := NetworkManager.host_game()
	if error != OK:
		menu.show_status("Could not host (error %d). Is another copy already hosting?" % error)
		return
	get_window().title = "Subject Zero (Host)"
	menu.hide()
	level_root.add_child(LEVEL_SCENE.instantiate())


func _on_join_requested(address: String) -> void:
	var error := NetworkManager.join_game(address)
	if error != OK:
		menu.show_status("Could not start connecting (error %d)." % error)
		return
	menu.set_buttons_enabled(false)
	menu.show_status("Connecting...")


func _on_connected_to_server() -> void:
	get_window().title = "Subject Zero (Player %d)" % multiplayer.get_unique_id()
	menu.hide()
	# Nothing else to do: the host's LevelSpawner sends us the level.


func _on_connection_failed() -> void:
	menu.set_buttons_enabled(true)
	menu.show_status("Could not connect. Check the IP address and that the host is running. The game might also be full (4 players max).")


func _on_server_disconnected() -> void:
	_unload_level()
	get_window().title = "Subject Zero"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.set_buttons_enabled(true)
	menu.show_status("Lost connection to the host.")
	menu.show()


func _unload_level() -> void:
	for child in level_root.get_children():
		child.queue_free()
