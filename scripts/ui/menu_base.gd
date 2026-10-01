class_name MenuBase
extends Control
## Shared behaviour for in-game menus (journal, pause, settings):
## showing the mouse, blocking the player's controls while open, and
## capturing the mouse again on close.

signal closed


func open() -> void:
	show()
	GameState.menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	hide()
	GameState.menu_open = _any_other_menu_open()
	if not GameState.menu_open and _in_game():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _in_game() -> bool:
	return not get_tree().get_nodes_in_group("player_hud").is_empty()


func _any_other_menu_open() -> bool:
	for menu in get_tree().get_nodes_in_group("menus"):
		if menu != self and menu.visible:
			return true
	return false


## A dark panel in the middle of the screen, filled by child menus.
func make_panel(size: Vector2) -> VBoxContainer:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_to_group("menus")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	hide()
	return box


func make_title(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func make_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button
