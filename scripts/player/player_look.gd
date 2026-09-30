extends Node3D
## Mouse look. Moving the mouse left/right turns the whole body,
## up/down tilts only the head. Esc frees the mouse, clicking captures it again.

@export var mouse_sensitivity := 0.002
@export var max_look_angle := 85.0

@onready var body: Node3D = get_parent()


func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and captured:
		body.rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_x(-event.relative.y * mouse_sensitivity)
		var limit := deg_to_rad(max_look_angle)
		rotation.x = clampf(rotation.x, -limit, limit)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
