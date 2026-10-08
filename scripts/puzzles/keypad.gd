extends Node3D
## A number keypad. The HOST picks a secret code; typing it and pressing
## ENT makes the keypad active. Something else in the level shows the code
## (a monitor, a developed photo, a blinking signal light...), usually in a
## different room so two players have to talk.
## With rotate_every set, the code changes every few seconds, so one player
## can't just memorise it and run over alone.

signal active_changed(active: bool)
signal code_changed(code: String)

@export var code_length := 4
## Seconds between new codes (0 = the code never changes).
@export var rotate_every := 0.0

var is_active := false
var code := ""
var entered := ""

var _rotate_timer := 0.0
var _wrong_timer := 0.0

@onready var display: Label3D = $Display


func _ready() -> void:
	if multiplayer.is_server():
		_set_code(_random_code())
		_rotate_timer = rotate_every
	else:
		# The level may have loaded after the host picked the code: ask for it.
		_request_state.rpc_id(1)
	_update_display()


func get_display_code() -> String:
	return code


## Opens the big keypad on this player's screen (they type the code there).
func open_ui() -> void:
	var menu: Node = null
	for m in get_tree().get_nodes_in_group("keypad_menu"):
		menu = m
	if menu == null:
		var layer := CanvasLayer.new()
		layer.layer = 30
		get_tree().root.add_child(layer)
		menu = Control.new()
		menu.set_script(load("res://scripts/ui/keypad_menu.gd"))
		menu.add_to_group("keypad_menu")
		layer.add_child(menu)
		menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.open_for(self)


## Any computer: press a key (the host decides what happens).
func request_press(key: String) -> void:
	if multiplayer.is_server():
		server_press(key)
	else:
		_request_press.rpc_id(1, key)


@rpc("any_peer", "reliable")
func _request_press(key: String) -> void:
	if multiplayer.is_server() and key in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "ENT"]:
		server_press(key)


## Host only: a key was pressed.
func server_press(key: String) -> void:
	if not multiplayer.is_server() or is_active:
		return
	match key:
		"CLR":
			_set_entered.rpc("")
		"ENT":
			if entered == code:
				_set_active.rpc(true)
			else:
				_show_wrong.rpc()
		_:
			if entered.length() < code_length:
				_set_entered.rpc(entered + key)


func _process(delta: float) -> void:
	if _wrong_timer > 0.0:
		_wrong_timer -= delta
		if _wrong_timer <= 0.0:
			_update_display()
	if multiplayer.is_server() and rotate_every > 0.0 and not is_active:
		_rotate_timer -= delta
		if _rotate_timer <= 0.0:
			_rotate_timer = rotate_every
			_set_code.rpc(_random_code())


func _random_code() -> String:
	var text := ""
	for i in code_length:
		text += str(randi() % 10)
	return text


@rpc("any_peer", "reliable")
func _request_state() -> void:
	if multiplayer.is_server():
		var id := multiplayer.get_remote_sender_id()
		_set_code.rpc_id(id, code)
		_set_entered.rpc_id(id, entered)
		if is_active:
			_set_active.rpc_id(id, true)


@rpc("authority", "call_local", "reliable")
func _set_code(new_code: String) -> void:
	code = new_code
	code_changed.emit(code)


@rpc("authority", "call_local", "reliable")
func _set_entered(text: String) -> void:
	entered = text
	_update_display()


@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	is_active = value
	_update_display()
	active_changed.emit(value)


@rpc("authority", "call_local", "reliable")
func _show_wrong() -> void:
	entered = ""
	_wrong_timer = 1.0
	display.text = "WRONG"
	display.modulate = Color(1, 0.2, 0.1)


func _update_display() -> void:
	if is_active:
		display.text = "OPEN"
		display.modulate = Color(0.2, 1, 0.3)
	else:
		display.text = entered + "_".repeat(code_length - entered.length())
		display.modulate = Color(0.9, 0.8, 0.3)
