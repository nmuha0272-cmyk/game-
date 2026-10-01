class_name Monster
extends CharacterBody3D
## Subject 7, "the Long Man" (and the base for later monsters).
##
## The host runs all of the thinking and moving. Everyone else just sees the
## result through the MultiplayerSynchronizer (position, rotation, state).
##
##   PATROL ──hears something──> INVESTIGATE ──sees someone──> CHASE
##     ^                              │                          │
##     └────────── SEARCH <───────────┴────loses them────────────┘
## A camera flash puts it in STUNNED. A door the Guard is holding puts it in
## BLOCKED (it pounds on the door, then gives up). Catching a player downs them.

enum State { DORMANT, PATROL, INVESTIGATE, CHASE, SEARCH, STUNNED, BLOCKED }

## Marker3D points it walks between while patrolling.
@export var patrol_points: Node3D
## Seconds after the level loads before it starts moving.
@export var start_delay := 8.0

@export_group("Speed")
@export var patrol_speed := 1.6
@export var investigate_speed := 2.6
## Faster than walking (3.5), slower than sprinting (6), so stamina matters.
@export var chase_speed := 4.4
@export var search_speed := 2.0
@export var turn_speed := 6.0

@export_group("Behaviour")
@export var catch_distance := 1.4
## Seconds without seeing its target before it gives up the chase.
@export var lose_target_time := 3.0
## Seconds it spends searching before going back to patrolling.
@export var search_time := 10.0
## How far from the last known spot it wanders while searching.
@export var search_radius := 5.0
## Seconds it pounds on a held door before giving up.
@export var give_up_on_door_time := 6.0
## The Long Man hates light: flash stuns last this many times longer.
@export var light_sensitivity := 1.5

## Synced to everyone so they can play the right sounds.
var state: State = State.DORMANT
var target: Player = null

var is_stunned: bool:
	get:
		return state == State.STUNNED

var _timer := 0.0
var _unseen_time := 0.0
var _last_known_position := Vector3.ZERO
var _patrol_index := 0
var _blocked_door: Door = null
var _state_before_block: State = State.PATROL
var _pound_timer := 0.0
## After giving up on a held door, ignore doors for a moment so we can walk away.
var _ignore_doors_time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var senses: MonsterSenses = $Senses
@onready var door_probe: RayCast3D = $DoorProbe


func _ready() -> void:
	add_to_group("monsters")
	_timer = start_delay


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	_think(delta)
	_move(delta)


# ---------------------------------------------------------------- thinking

func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.DORMANT:
			if _timer <= 0.0:
				_start_patrol()
			return
		State.STUNNED:
			if _timer <= 0.0:
				_start_search(_last_known_position)
			return
		State.BLOCKED:
			_think_blocked(delta)
			return

	# Seeing someone always wins. Stick with the current target if we still see them.
	if target and senses.can_see(target):
		_chase(target)
	else:
		var seen := senses.find_visible_player()
		if seen:
			_chase(seen)

	match state:
		State.CHASE:
			_think_chase(delta)
		State.PATROL, State.INVESTIGATE, State.SEARCH:
			var heard := senses.find_heard_player()
			if heard:
				_investigate(heard.global_position)
			_think_wander()


func _think_chase(delta: float) -> void:
	if not is_instance_valid(target) or target.is_downed:
		_start_search(_last_known_position)
		return
	if senses.can_see(target):
		_unseen_time = 0.0
		_last_known_position = target.global_position
	else:
		_unseen_time += delta
		if _unseen_time > lose_target_time:
			_start_search(_last_known_position)
			return
	nav.target_position = _last_known_position
	if global_position.distance_to(target.global_position) <= catch_distance:
		target.downed.server_set_downed(true)
		_start_search(global_position)


func _think_wander() -> void:
	match state:
		State.PATROL:
			if nav.is_navigation_finished():
				_next_patrol_point()
		State.INVESTIGATE:
			if nav.is_navigation_finished():
				_start_search(_last_known_position)
		State.SEARCH:
			if _timer <= 0.0:
				_start_patrol()
			elif nav.is_navigation_finished():
				_wander_near(_last_known_position)


func _think_blocked(delta: float) -> void:
	if not is_instance_valid(_blocked_door) or not _blocked_door.is_held() or _blocked_door.is_open:
		# Nobody is holding it any more: open it and carry on.
		if is_instance_valid(_blocked_door):
			_blocked_door.server_force_open()
		state = _state_before_block
		return
	_pound_timer -= delta
	if _pound_timer <= 0.0:
		_pound_timer = 1.0
		_blocked_door.pound()
	if _timer <= 0.0:
		# Give up and go somewhere far from this door.
		_blocked_door = null
		_ignore_doors_time = 3.0
		_patrol_index = _farthest_patrol_point_from(global_position)
		state = State.PATROL
		nav.target_position = _patrol_position(_patrol_index)


# ---------------------------------------------------------------- state changes

func _start_patrol() -> void:
	state = State.PATROL
	target = null
	_patrol_index = _nearest_patrol_point()
	nav.target_position = _patrol_position(_patrol_index)


func _investigate(position_to_check: Vector3) -> void:
	state = State.INVESTIGATE
	_last_known_position = position_to_check
	nav.target_position = position_to_check


func _chase(player: Player) -> void:
	state = State.CHASE
	target = player
	_unseen_time = 0.0
	_last_known_position = player.global_position


func _start_search(around: Vector3) -> void:
	state = State.SEARCH
	target = null
	_timer = search_time
	_last_known_position = around
	nav.target_position = around


## Host only: something made a loud noise (a door, a flash, a heavy object).
func hear_noise(noise_position: Vector3, radius: float) -> void:
	if not multiplayer.is_server():
		return
	if state in [State.PATROL, State.INVESTIGATE, State.SEARCH] \
			and global_position.distance_to(noise_position) <= radius:
		_investigate(noise_position)


## Host only: the Journalist's flash hit us.
func stun(seconds: float) -> void:
	if not multiplayer.is_server():
		return
	if target:
		_last_known_position = target.global_position
	target = null
	state = State.STUNNED
	_timer = seconds * light_sensitivity
	velocity = Vector3.ZERO


# ---------------------------------------------------------------- moving

func _move(delta: float) -> void:
	var speed := _current_speed()
	var direction := Vector3.ZERO
	if speed > 0.0:
		if state == State.CHASE and target and senses.can_see(target):
			# Close enough to see them: go straight for them.
			direction = target.global_position - global_position
		elif not nav.is_navigation_finished():
			direction = nav.get_next_path_position() - global_position
	direction.y = 0.0

	if direction.length() > 0.05:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var wanted_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, wanted_yaw, clampf(turn_speed * delta, 0.0, 1.0))
		_check_for_door()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	move_and_slide()


func _current_speed() -> float:
	match state:
		State.PATROL: return patrol_speed
		State.INVESTIGATE: return investigate_speed
		State.CHASE: return chase_speed
		State.SEARCH: return search_speed
	return 0.0


## A closed door in front of us: open it, or pound on it if someone holds it.
func _check_for_door() -> void:
	if _ignore_doors_time > 0.0:
		_ignore_doors_time -= get_physics_process_delta_time()
		return
	var door := door_probe.get_collider() as Door
	if door == null or door.is_open:
		return
	if door.is_held():
		_blocked_door = door
		_state_before_block = state
		state = State.BLOCKED
		_timer = give_up_on_door_time
		_pound_timer = 0.0
		velocity = Vector3.ZERO
	else:
		door.server_force_open()


# ---------------------------------------------------------------- patrol helpers

func _patrol_position(index: int) -> Vector3:
	if not patrol_points or patrol_points.get_child_count() == 0:
		return global_position
	return patrol_points.get_child(index % patrol_points.get_child_count()).global_position


func _next_patrol_point() -> void:
	if patrol_points and patrol_points.get_child_count() > 0:
		_patrol_index = (_patrol_index + 1) % patrol_points.get_child_count()
	nav.target_position = _patrol_position(_patrol_index)


func _nearest_patrol_point() -> int:
	var best := 0
	if patrol_points:
		for i in patrol_points.get_child_count():
			if global_position.distance_to(_patrol_position(i)) \
					< global_position.distance_to(_patrol_position(best)):
				best = i
	return best


func _farthest_patrol_point_from(point: Vector3) -> int:
	var best := 0
	if patrol_points:
		for i in patrol_points.get_child_count():
			if point.distance_to(_patrol_position(i)) > point.distance_to(_patrol_position(best)):
				best = i
	return best


func _wander_near(center: Vector3) -> void:
	var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * search_radius
	var map := get_world_3d().navigation_map
	nav.target_position = NavigationServer3D.map_get_closest_point(map, center + offset)


# ---------------------------------------------------------------- used by abilities

## The point the camera flash aims at (its head).
func get_aim_point() -> Vector3:
	return global_position + Vector3(0.0, 2.3, 0.0)


## Only the Son's computer calls this, so only he sees the glow.
func set_sensed(sensed: bool) -> void:
	$SenseGlow.visible = sensed
