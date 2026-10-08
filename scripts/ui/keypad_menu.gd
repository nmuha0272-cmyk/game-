extends MenuBase
## The keypad, big on your screen: click the numbers or type them on your
## keyboard (0-9, Backspace to clear, Enter to try the code, Esc to close).
## Every press goes to the real keypad, so everyone sees the same thing.

var keypad: Node
var _display: Label


func _ready() -> void:
	var box := make_panel(Vector2(340, 470))
	make_title(box, "KEYPAD")
	_display = Label.new()
	_display.add_theme_font_size_override("font_size", 44)
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_display.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	box.add_child(_display)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "0", "ENT"]:
		var button := Button.new()
		button.text = key
		button.custom_minimum_size = Vector2(96, 62)
		button.add_theme_font_size_override("font_size", 26)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_press.bind(key))
		grid.add_child(button)
	var hint := Label.new()
	hint.text = "Type the code: 0-9, Backspace, Enter.  Esc to close."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(hint)
	make_button(box, "Close (Esc)", close)


func open_for(target: Node) -> void:
	keypad = target
	open()
	_refresh()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if keypad == null or not is_instance_valid(keypad):
		return
	_display.text = keypad.display.text
	_display.modulate = keypad.display.modulate
	if keypad.is_active:
		close.call_deferred()


func _press(key: String) -> void:
	if keypad and is_instance_valid(keypad):
		keypad.request_press(key)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_0 and k <= KEY_9:
			_press(str(k - KEY_0))
		elif k >= KEY_KP_0 and k <= KEY_KP_9:
			_press(str(k - KEY_KP_0))
		elif k == KEY_BACKSPACE or k == KEY_DELETE:
			_press("CLR")
		elif k == KEY_ENTER or k == KEY_KP_ENTER:
			_press("ENT")
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()
