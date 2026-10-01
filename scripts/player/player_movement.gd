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
## Extra slow-down from abilities, e.g. 0.6 while the Guard moves something heavy.
var speed_multiplier := 1.0
## True while this player's flashlight is on (monsters spot you more easily).
var flashlight_on: bool:
	get:
		return flashlight != null and flashlight.visible
## True if knocked down (see downed_state.gd).
var is_downed: bool:
	get:
		return downed != null and downed.is_downed

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
@onready var downed: DownedState = $Downed
@onready var flashlight: Flashlight = $Head/Camera3D/Flashlight
@onready var inventory: Inventory = $Inventory


## Finds the player with this network ID (or null).
static func find(tree: SceneTree, id: int) -> Player:
	for player in tree.get_nodes_in_group("players"):
		if player.name == str(id):
			return player
	return null


func _enter_tree() -> void:
	# The player's name is the network ID of the person who controls it.
	var id := name.to_int()
	if id > 0:
		set_multiplayer_authority(id)


func _ready() -> void:
	add_to_group("players")
	_apply_character_color()
	_head_stand_y = head.position.y
	_apply_crouch_shape()
	downed.changed.connect(_apply_crouch_shape)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var carrier := downed.get_carrier()
	if carrier:
		_follow_carrier(carrier, delta)
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	_update_crouch(delta)

	if is_downed:
		# Downed players can't move. They just lie there.
		is_sprinting = false
		stamina.draining = false
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		is_grounded = is_on_floor()
		return

	# Input.get_vector gives x = left/right, y = forward/back (forward is negative).
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if GameState.menu_open:
		input = Vector2.ZERO
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	var moving_forward := input.y < -0.1
	# Nobody but the Guard can sprint while carrying something heavy.
	var too_heavy := inventory.speed_multiplier() < 1.0
	is_sprinting = Input.is_action_pressed("sprint") and moving_forward \
			and not is_crouching and not too_heavy and stamina.can_sprint()
	stamina.draining = is_sprinting

	var speed := walk_speed
	if is_crouching:
		speed = crouch_speed
	elif is_sprinting:
		speed = sprint_speed
	speed *= Characters.get_value(character, "speed_multiplier", 1.0) * speed_multiplier
	speed *= inventory.speed_multiplier()
	speed *= _dragging_speed_multiplier()

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
	if is_downed:
		target_y = 0.35
	elif is_crouching:
		target_y -= stand_height - crouch_height
	head.position.y = lerpf(head.position.y, target_y,
			clampf(crouch_transition_speed * delta, 0.0, 1.0))


## Shrinks or grows the body. Runs automatically when crouching or downed changes.
func _apply_crouch_shape() -> void:
	var height := crouch_height if (is_crouching or is_downed) else stand_height
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = height
	# Keep the bottom of the capsule on the floor.
	collision_shape.position.y = height / 2.0
	if is_downed:
		# Lie on the floor.
		body_mesh.scale.y = 1.0
		body_mesh.rotation_degrees = Vector3(0, 0, 90)
		body_mesh.position.y = 0.35
	else:
		body_mesh.rotation_degrees = Vector3.ZERO
		body_mesh.scale.y = height / stand_height
		body_mesh.position.y = height / 2.0


## True if there is room above our head to stand back up.
func _can_stand_up() -> bool:
	return not test_move(global_transform, Vector3.UP * (stand_height - crouch_height))


## While being carried, ride on the carrier's back instead of moving ourselves.
func _follow_carrier(carrier: Player, delta: float) -> void:
	global_transform = carrier.global_transform.translated_local(Vector3(0.0, 0.5, 0.6))
	velocity = carrier.velocity
	is_grounded = false
	head.position.y = lerpf(head.position.y, 0.4, clampf(crouch_transition_speed * delta, 0.0, 1.0))


# Teammates can look at a downed player and hold E to help them up.
# (The Interactor calls these, just like on doors and switches.)
func can_interact(by: Player) -> bool:
	return downed.can_be_helped(by)


func get_hold_time(_by: Player) -> float:
	return DownedState.HELP_UP_TIME


func get_prompt(by: Player) -> String:
	return downed.get_help_prompt(by)


func interact(by: Player) -> void:
	downed.request_help_up(by)


## Tints the placeholder body in the character's main color (from the concept art).
func _apply_character_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Characters.get_value(character, "color", Color(0.5, 0.5, 0.5))
	body_mesh.material_override = material


## Dragging heavy furniture without being the Guard (the backup) is very slow.
## Also stops us bumping into the thing we're dragging.
func _dragging_speed_multiplier() -> float:
	var multiplier := 1.0
	for heavy: HeavyObject in get_tree().get_nodes_in_group("heavy_objects"):
		if heavy.mover_id == name.to_int():
			add_collision_exception_with(heavy)
			if character != Characters.Id.GUARD:
				multiplier = 0.4
		elif heavy in get_collision_exceptions():
			remove_collision_exception_with(heavy)
	return multiplier
