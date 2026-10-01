extends MenuBase
## Settings: volume, mouse sensitivity and brightness. Saved automatically.

var _volume: HSlider
var _sensitivity: HSlider
var _brightness: HSlider


func _ready() -> void:
	var box := make_panel(Vector2(460, 300))
	make_title(box, "SETTINGS")
	_volume = _add_slider(box, "Volume", 0.0, 1.0, Settings.volume, Settings.set_volume)
	_sensitivity = _add_slider(box, "Mouse sensitivity", 0.0005, 0.006, Settings.mouse_sensitivity,
			Settings.set_mouse_sensitivity)
	_brightness = _add_slider(box, "Brightness", 0.5, 1.8, Settings.brightness, Settings.set_brightness)
	make_button(box, "Back", close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


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
