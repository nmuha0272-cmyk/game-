extends CanvasLayer
## Fades the screen to black with a message (like "Everyone is down..."),
## then back. Lives in the main scene so it stays during level restarts.

var _rect: ColorRect
var _label: Label


func _ready() -> void:
	layer = 50
	add_to_group("screen_fader")
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.25))
	_rect.add_child(_label)


func fade_out(text: String, seconds := 1.5) -> void:
	_label.text = text
	create_tween().tween_property(_rect, "modulate:a", 1.0, seconds)


func fade_in(seconds := 1.5) -> void:
	create_tween().tween_property(_rect, "modulate:a", 0.0, seconds)


func is_black() -> bool:
	return _rect.modulate.a > 0.99
