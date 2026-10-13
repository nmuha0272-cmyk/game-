class_name Terminal
extends PuzzleInput
## An old computer terminal. Press E and a small grid puzzle opens on your
## screen ("lights out"): each press flips a tile and its neighbours, so you
## have to light the whole board. Solve it and the terminal switches on, which
## can reveal a code on a nearby monitor, turn on lights or open a door.
## The HOST runs the board, so every player's screen shows the same thing.

signal board_changed(board: PackedByteArray)

const SIZE := 3
const COUNT := SIZE * SIZE
## Which tiles flip when a tile is pressed (itself plus its neighbours).
const NEIGHBOURS := [
	[0, 1, 3], [1, 0, 2, 4], [2, 1, 5],
	[3, 0, 4, 6], [4, 1, 3, 5, 7], [5, 2, 4, 8],
	[6, 3, 7], [7, 4, 6, 8], [8, 5, 7],
]

## 1 = lit, 0 = dark. The host owns this; it is copied to everyone.
var board := PackedByteArray()

@onready var _screen: Label3D = get_node_or_null("Screen")


func _ready() -> void:
	super()
	board.resize(COUNT)
	if multiplayer.is_server():
		_scramble()
		_sync_board.rpc(board)
	else:
		_request_state.rpc_id(1)
	_update_screen()


func can_interact(_by: Player) -> bool:
	return enabled and not is_active


func get_prompt(by: Player) -> String:
	return "Terminal online." if is_active else super(by)


## Runs on the computer of the player who pressed E: the puzzle pops up on
## their screen (like the keypad, this is local).
func interact(by: Player) -> void:
	if can_interact(by):
		open_ui()


func open_ui() -> void:
	var menu: Node = null
	for m in get_tree().get_nodes_in_group("terminal_menu"):
		menu = m
	if menu == null:
		var layer := CanvasLayer.new()
		layer.layer = 30
		get_tree().root.add_child(layer)
		menu = Control.new()
		menu.set_script(load("res://scripts/ui/terminal_menu.gd"))
		menu.add_to_group("terminal_menu")
		layer.add_child(menu)
		menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.open_for(self)


## Any computer: press a tile (the host decides what happens).
func request_press(index: int) -> void:
	if multiplayer.is_server():
		server_press(index)
	else:
		_request_press.rpc_id(1, index)


@rpc("any_peer", "reliable")
func _request_press(index: int) -> void:
	if multiplayer.is_server():
		server_press(index)


## Host only: a tile was pressed.
func server_press(index: int) -> void:
	if not multiplayer.is_server() or is_active or index < 0 or index >= COUNT:
		return
	_apply(index)
	_sync_board.rpc(board)
	if _is_solved():
		server_set_active(true)


func _is_solved() -> bool:
	for value in board:
		if value == 0:
			return false
	return true


func _apply(index: int) -> void:
	for n in NEIGHBOURS[index]:
		board[n] = 1 - board[n]


func _scramble() -> void:
	board.fill(1)
	var presses := 0
	while presses < 5 or _is_solved():
		_apply(randi() % COUNT)
		presses += 1
		if presses > 40:
			break


@rpc("any_peer", "reliable")
func _request_state() -> void:
	if multiplayer.is_server():
		var id := multiplayer.get_remote_sender_id()
		_sync_board.rpc_id(id, board)
		if is_active:
			_set_active.rpc_id(id, true)


@rpc("authority", "call_local", "reliable")
func _sync_board(new_board: PackedByteArray) -> void:
	board = new_board
	board_changed.emit(board)
	_update_screen()


func _on_active_changed(_active: bool) -> void:
	_update_screen()


func _update_screen() -> void:
	if _screen == null:
		return
	if is_active:
		_screen.text = "ONLINE"
		_screen.modulate = Color(0.4, 1, 0.5)
	else:
		_screen.text = "ENTER SEQUENCE"
		_screen.modulate = Color(0.9, 0.8, 0.3)
