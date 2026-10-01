extends Node3D
## Mouse look. Moving the mouse left/right turns the whole body,
## up/down tilts only the head. Clicking the game captures the mouse.
## (Esc opens the pause menu, see pause_menu.gd.) Sensitivity comes from
## the Settings menu.

@export var max_look_angle := 85.0

@onready var body: Node3D = get_parent()


func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and captured and not GameState.menu_open:
		var sensitivity: float = Settings.mouse_sensitivity
		body.rotate_y(-event.relative.x * sensitivity)
		rotate_x(-event.relative.y * sensitivity)
		var limit := deg_to_rad(max_look_angle)
		rotation.x = clampf(rotation.x, -limit, limit)
	elif event is InputEventMouseButton and event.pressed and not captured and not GameState.menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
