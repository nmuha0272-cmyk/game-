extends MenuBase
## The terminal, big on your screen: a 3x3 grid of tiles. Click a tile to
## flip it and its neighbours; light every tile to bring the terminal online.
## Every press goes to the real terminal, so everyone sees the same board.

const COUNT := 9

var terminal: Node
var _grid: GridContainer
var _status: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	var box := make_panel(Vector2(360, 430))
	make_title(box, "TERMINAL")
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 20)
	box.add_child(_status)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_grid)
	for i in COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(84, 84)
		button.add_theme_font_size_override("font_size", 22)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_press.bind(i))
		_grid.add_child(button)
		_buttons.append(button)
	var hint := Label.new()
	hint.text = "Light every panel. Each press flips it and its neighbours."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(hint)
	make_button(box, "Close (Esc)", close)


func open_for(target: Node) -> void:
	terminal = target
	open()
	_refresh()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if terminal == null or not is_instance_valid(terminal):
		return
	var board: PackedByteArray = terminal.board
	for i in _buttons.size():
		if i >= board.size():
			continue
		var lit := board[i] == 1
		_buttons[i].text = "ON" if lit else ""
		_buttons[i].modulate = Color(0.4, 1, 0.5) if lit else Color(0.35, 0.35, 0.42)
	_status.text = "ONLINE" if terminal.is_active else "ENTER SEQUENCE"
	_status.add_theme_color_override("font_color",
			Color(0.4, 1, 0.5) if terminal.is_active else Color(0.9, 0.8, 0.3))
	if terminal.is_active:
		close.call_deferred()


func _press(index: int) -> void:
	if terminal and is_instance_valid(terminal):
		terminal.request_press(index)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
