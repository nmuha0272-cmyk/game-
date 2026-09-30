class_name Player
extends CharacterBody3D
## Moves the player around: walking, sprinting (uses stamina) and crouching.
## Only the computer that owns this player runs the movement. Everyone else
## receives the position through the MultiplayerSynchronizer.

@export var walk_speed := 3.5
@export var sprint_speed := 6.0
@export var crouch_speed := 1.8
## How quickly the player speeds up and slows down. Higher = snappier.
@export var acceleration := 10.0

@export_group("Crouch")
@export var stand_height := 1.8
@export var crouch_height := 1.0
## How fast the camera slides down/up when crouching.
@export var crouch_transition_speed := 10.0

## Which character this is (see characters.gd). Set by the spawner.
var character: int = Characters.Id.NONE

# These are synced over the network so other players see/hear us correctly.
var is_sprinting := false
var is_grounded := true
var is_crouching := false:
	set(value):
		is_crouching = value
		if is_node_ready():
			_apply_crouch_shape()

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _head_stand_y := 0.0

@onready var stamina: Stamina = $Stamina
@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh


func _enter_tree() -> void:
	# The player's name is the network ID of the person who controls it.
	var id := name.to_int()
	if id > 0:
		set_multiplayer_authority(id)


func _ready() -> void:
	_head_stand_y = head.position.y
	_apply_crouch_shape()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	_update_crouch(delta)

	# Input.get_vector gives x = left/right, y = forward/back (forward is negative).
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	var moving_forward := input.y < -0.1
	is_sprinting = Input.is_action_pressed("sprint") and moving_forward \
			and not is_crouching and stamina.can_sprint()
	stamina.draining = is_sprinting

	var speed := walk_speed
	if is_crouching:
		speed = crouch_speed
	elif is_sprinting:
		speed = sprint_speed

	var weight := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, direction.x * speed, weight)
	velocity.z = lerpf(velocity.z, direction.z * speed, weight)

	move_and_slide()
	is_grounded = is_on_floor()


func _update_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch and not is_crouching:
		is_crouching = true
	elif not wants_crouch and is_crouching and _can_stand_up():
		is_crouching = false

	# Slide the head smoothly to its new height.
	var target_y := _head_stand_y
	if is_crouching:
		target_y -= stand_height - crouch_height
	head.position.y = lerpf(head.position.y, target_y,
			clampf(crouch_transition_speed * delta, 0.0, 1.0))


## Shrinks or grows the body. Runs automatically when is_crouching changes.
func _apply_crouch_shape() -> void:
	var height := crouch_height if is_crouching else stand_height
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = height
	# Keep the bottom of the capsule on the floor.
	collision_shape.position.y = height / 2.0
	body_mesh.scale.y = height / stand_height
	body_mesh.position.y = height / 2.0


## True if there is room above our head to stand back up.
func _can_stand_up() -> bool:
	return not test_move(global_transform, Vector3.UP * (stand_height - crouch_height))
