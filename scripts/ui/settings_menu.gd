extends MenuBase
## Settings: volume, mouse sensitivity, brightness, flashlight brightness,
## graphics and controls.
## Saved automatically, so they stay the same next time the game starts.

var _volume: HSlider
var _sensitivity: HSlider
var _brightness: HSlider
## One button per changeable control. Click it, then press the new key.
var _key_buttons: Dictionary = {}
## The control we are waiting for a new key for ("" when not rebinding).
var _listening_action := ""


func _ready() -> void:
	var box := make_panel(Vector2(560, 620))
	make_title(box, "SETTINGS")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_volume = _add_slider(content, "Volume", 0.0, 1.0, Settings.volume, Settings.set_volume)
	_sensitivity = _add_slider(content, "Mouse sensitivity", 0.0005, 0.006, Settings.mouse_sensitivity,
			Settings.set_mouse_sensitivity)
	_brightness = _add_slider(content, "Brightness", 0.5, 1.8, Settings.brightness, Settings.set_brightness)
	_add_slider(content, "Flashlight brightness", 0.4, 2.0, Settings.flashlight_brightness,
			Settings.set_flashlight_brightness)
	
	# Voice chat settings
	var voice_heading := Label.new()
	voice_heading.text = "\nVoice Chat"
	content.add_child(voice_heading)
	
	var mode_picker := OptionButton.new()
	mode_picker.add_item("Push-to-talk (V)")
	mode_picker.add_item("Open mic")
	mode_picker.selected = Settings.voice_chat_mode
	mode_picker.item_selected.connect(Settings.set_voice_chat_mode)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 12)
	content.add_child(mode_row)
	var mode_label := Label.new()
	mode_label.text = "Mode"
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(mode_label)
	mode_row.add_child(mode_picker)
	
	_add_slider(content, "Mic sensitivity", 0.1, 10.0, Settings.mic_sensitivity,
			Settings.set_mic_sensitivity)
	_add_slider(content, "Noise gate", 0.0, 0.5, Settings.noise_gate_threshold,
			Settings.set_noise_gate_threshold)
	
	_add_graphics_picker(content)
	_add_controls(content)
	make_button(box, "Back", close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_listening_action = ""
		close()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# While rebinding, the next key press (or mouse click) becomes the control.
	if not visible or _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode != KEY_ESCAPE:
			Settings.set_action_key(_listening_action, event)
		_stop_listening()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		Settings.set_action_key(_listening_action, event)
		_stop_listening()
		get_viewport().set_input_as_handled()


func _add_graphics_picker(parent: Control) -> void:
	var label := Label.new()
	label.text = "Graphics (lower it if the game is slow)"
	parent.add_child(label)
	var picker := OptionButton.new()
	for quality_name in Settings.GRAPHICS_NAMES:
		picker.add_item(quality_name)
	picker.selected = Settings.graphics
	picker.item_selected.connect(Settings.set_graphics)
	parent.add_child(picker)


func _add_controls(parent: Control) -> void:
	var heading := Label.new()
	heading.text = "\nControls  (click a key, then press the new one)"
	parent.add_child(heading)
	for pair in Settings.REMAP_ACTIONS:
		var action: String = pair[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		parent.add_child(row)
		var name_label := Label.new()
		name_label.text = pair[1]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(160, 0)
		button.text = Settings.action_key_text(action)
		button.pressed.connect(_start_listening.bind(action))
		row.add_child(button)
		_key_buttons[action] = button
	var reset := Button.new()
	reset.text = "Reset controls to defaults"
	reset.pressed.connect(_reset_controls)
	parent.add_child(reset)


func _start_listening(action: String) -> void:
	if _listening_action != "":
		_refresh_key_button(_listening_action)
	_listening_action = action
	_key_buttons[action].text = "Press a key..."


func _stop_listening() -> void:
	var action := _listening_action
	_listening_action = ""
	_refresh_key_button(action)


func _refresh_key_button(action: String) -> void:
	if _key_buttons.has(action):
		_key_buttons[action].text = Settings.action_key_text(action)


func _reset_controls() -> void:
	_listening_action = ""
	Settings.reset_controls()
	for action in _key_buttons:
		_refresh_key_button(action)


func _add_slider(parent: Control, text: String, low: float, high: float, value: float,
		on_change: Callable) -> HSlider:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = (high - low) / 100.0
	slider.value = value
	slider.value_changed.connect(on_change)
	parent.add_child(slider)
	return slider
