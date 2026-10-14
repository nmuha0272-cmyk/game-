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
## BLOCKED (it pounds on the door, then gives up). A locked door does too.
## A burning flare puts it in DISTRACTED: it stares at the flare and ignores
## players until it burns out. Catching a player downs them.
## STARE: when it first spots you, it rises up to its full height and stares
## for a moment... then drops to all fours and charges.

enum State { DORMANT, PATROL, INVESTIGATE, CHASE, SEARCH, STUNNED, BLOCKED, DISTRACTED, STARE }

## Every monster type has its own way of dealing with a player who hides in a
## locker. This is set per monster scene (see scenes/monsters/*.tscn):
##  - DRAG (the Long Man): if he saw you climb in, or he is searching right
##    where you vanished and the locker is nearby, he rips the door open and
##    drags you out.
##  - OVERLOAD (the Wired): it feels the current in your body. It notices a
##    hidden player from further away and floods the locker, knocking you out.
##  - NONE: this monster ignores lockers completely.
enum HidingCounter { NONE, DRAG, OVERLOAD }

## Marker3D points it walks between while patrolling.
@export var patrol_points: Node3D
## Seconds after the level loads before it starts moving.
@export var start_delay := 8.0

@export_group("Hiding")
## How this monster counters players who hide in lockers (above).
@export var hiding_counter: HidingCounter = HidingCounter.DRAG
## How close it must come to a locker to check it while searching (meters).
## OVERLOAD senses hiders from twice this far.
@export var hiding_check_radius := 2.5

@export_group("Combat")
## How much gunfire it takes before it is driven off (it then recovers).
@export var max_health := 100.0
## The Long Man: while he is close, he jumbles the Son's Sense (false echoes).
@export var scrambles_sense := false
## The Wired: while it is close, it reverses the Engineer's repairs.
@export var sabotages_repair := false

@export_group("Speed")
@export var patrol_speed := 1.6
@export var investigate_speed := 2.6
## Faster than walking (3.5), slower than sprinting (6), so stamina matters.
## Even Frank (slower, 5.1 sprint) can pull away for a few seconds.
@export var chase_speed := 4.2
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
## Seconds after catching someone during which it ignores everyone.
@export var catch_cooldown := 6.0
## The Long Man hates light: flash stuns last this many times longer.
@export var light_sensitivity := 1.5
## How long it stares at you after spotting you, before it charges.
@export var stare_time := 1.4

## Synced to everyone so they can play the right sounds.
var state: State = State.DORMANT
var _hide_spot: HidingSpot = null
var target: Player = null
## Current health (host-side). Reset to max_health when driven off.
var health := 0.0

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
var _ignore_players_time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var senses: MonsterSenses = $Senses
@onready var door_probe: RayCast3D = $DoorProbe


func _ready() -> void:
	add_to_group("monsters")
	_timer = start_delay
	health = max_health


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
		State.DISTRACTED:
			if _timer <= 0.0:
				_start_search(_last_known_position)
			return
		State.STARE:
			_think_stare()
			return

	if _ignore_players_time > 0.0:
		_ignore_players_time -= delta
		_think_wander()
		return

	# Seeing someone always wins. Stick with the current target if we still see them.
	if target and senses.can_see(target):
		_chase(target)
	else:
		var seen := senses.find_visible_player()
		if seen:
			if state == State.CHASE:
				_chase(seen)
			else:
				_start_stare(seen)

	match state:
		State.CHASE:
			_think_chase(delta)
		State.PATROL, State.INVESTIGATE, State.SEARCH:
			var heard := senses.find_heard_player()
			if heard:
				_investigate(heard.global_position)
			_think_wander()


## Standing tall, staring at the player it just found. Then the chase begins.
func _think_stare() -> void:
	if not is_instance_valid(target) or target.is_downed:
		_start_search(_last_known_position)
		return
	_last_known_position = target.global_position
	var to_target := target.global_position - global_position
	rotation.y = lerp_angle(rotation.y, atan2(-to_target.x, -to_target.z), 0.15)
	if _timer <= 0.0:
		_chase(target)


func _start_stare(player: Player) -> void:
	state = State.STARE
	target = player
	_timer = stare_time
	_last_known_position = player.global_position
	velocity = Vector3.ZERO


func _think_chase(delta: float) -> void:
	if not is_instance_valid(target) or target.is_downed:
		_start_search(_last_known_position)
		return
	# It knows which locker they climbed into: straight there to flush them out.
	if _hide_spot and is_instance_valid(_hide_spot) and HidingSpot.is_hidden(target):
		_go_to_hiding_spot(_hide_spot)
		return
	_hide_spot = null
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
		_jump_scare.rpc_id(target.name.to_int())
		_wander_off()


## Host only: walk to a locker and, once there, force the player inside out.
func _go_to_hiding_spot(spot: HidingSpot) -> void:
	if spot.occupant == 0:
		_hide_spot = null
		return
	var front: Vector3 = spot.global_transform * Vector3(0, 0, 0.9)
	nav.target_position = front
	if global_position.distance_to(front) <= catch_distance + 0.6:
		_flush_hider(spot)


## Host only: the counter. DRAG hauls them out; OVERLOAD floods the locker.
func _flush_hider(spot: HidingSpot) -> void:
	var caught: Player = spot.server_drag_out()
	_hide_spot = null
	if caught and not caught.is_downed:
		caught.downed.server_set_downed(true)
		if hiding_counter == HidingCounter.OVERLOAD:
			_overload_scare.rpc_id(caught.name.to_int())
		else:
			_jump_scare.rpc_id(caught.name.to_int())
	_wander_off()


## Host only: is there somebody hiding in a locker near this point? How far
## it can sense them depends on the monster's counter.
func _find_hiding_spot_near(point: Vector3) -> HidingSpot:
	var reach := _sweep_radius()
	if reach <= 0.0:
		return null
	var best: HidingSpot = null
	var best_distance := reach
	for node in get_tree().get_nodes_in_group("hiding_spots"):
		var spot := node as HidingSpot
		if spot == null or spot.occupant == 0:
			continue
		var distance := point.distance_to(spot.global_position)
		if distance <= best_distance:
			best = spot
			best_distance = distance
	return best


func _sweep_radius() -> float:
	match hiding_counter:
		HidingCounter.DRAG:
			return hiding_check_radius
		HidingCounter.OVERLOAD:
			return hiding_check_radius * 2.0
	return 0.0


func _think_wander() -> void:
	match state:
		State.PATROL:
			if nav.is_navigation_finished():
				_next_patrol_point()
		State.INVESTIGATE:
			if nav.is_navigation_finished():
				_start_search(_last_known_position)
		State.SEARCH:
			# On the way to search, it also checks lockers near where it lost you.
			var spot: HidingSpot = _find_hiding_spot_near(_last_known_position) if _timer > 0.0 else null
			if spot:
				_go_to_hiding_spot(spot)
			elif _timer <= 0.0:
				_start_patrol()
			elif nav.is_navigation_finished():
				_wander_near(_last_known_position)


func _think_blocked(delta: float) -> void:
	if not is_instance_valid(_blocked_door) or _blocked_door.is_open \
			or not (_blocked_door.is_held() or _blocked_door.is_locked()):
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


## Host only: chase this player right now, no staring (the final chase).
func server_force_chase(player: Player) -> void:
	if not multiplayer.is_server():
		return
	_ignore_players_time = 0.0
	_start_stare(player)
	_timer = stare_time


## Host only: someone is climbing into a locker. If it can see them doing it,
## it remembers which one. OVERLOAD (the Wired) also feels them climb in from
## close range even without a clear line of sight.
func server_saw_hide(player: Player, spot: HidingSpot) -> void:
	if not multiplayer.is_server() or state in [State.DORMANT, State.STUNNED, State.DISTRACTED]:
		return
	var distance := global_position.distance_to(player.global_position)
	var noticed := senses.can_see(player) and distance < 14.0
	if hiding_counter == HidingCounter.OVERLOAD and distance < hiding_check_radius:
		noticed = true
	if noticed:
		_hide_spot = spot
		_chase(player)


func _investigate(position_to_check: Vector3) -> void:
	state = State.INVESTIGATE
	_last_known_position = position_to_check
	nav.target_position = position_to_check


func _chase(player: Player) -> void:
	state = State.CHASE
	target = player
	_unseen_time = 0.0
	_last_known_position = player.global_position


## After catching someone it stalks off to the far end of its patrol, giving
## the others a chance to help them up (instead of camping the body).
func _wander_off() -> void:
	state = State.PATROL
	target = null
	_ignore_doors_time = 0.0
	_patrol_index = _farthest_patrol_point_from(global_position)
	nav.target_position = _patrol_position(_patrol_index)
	_ignore_players_time = catch_cooldown


func _start_search(around: Vector3) -> void:
	state = State.SEARCH
	target = null
	_timer = search_time
	_last_known_position = around
	nav.target_position = around


## Host only: something made a loud noise (a door, a flash, a heavy object).
func hear_noise(noise_position: Vector3, radius: float) -> void:
	if not multiplayer.is_server() or _ignore_players_time > 0.0:
		return
	if state in [State.PATROL, State.INVESTIGATE, State.SEARCH] \
			and global_position.distance_to(noise_position) <= radius:
		_investigate(noise_position)


## Host only: wake up (if asleep) and hunt this player. Used by chase
## triggers, like the Long Man bursting out of his cell.
## stare_seconds > 0: it first stands and stares at them that long.
func wake(target_player: Player, stare_seconds := 0.0) -> void:
	if not multiplayer.is_server():
		return
	if state == State.DORMANT and is_instance_valid(target_player):
		if stare_seconds > 0.0:
			_start_stare(target_player)
			_timer = stare_seconds
		else:
			_chase(target_player)


## Host only: a burning flare nearby. Go stare at it until it burns out.
func distract(flare_position: Vector3, seconds: float) -> void:
	if not multiplayer.is_server() or state in [State.DORMANT, State.STUNNED]:
		return
	if state != State.DISTRACTED:
		nav.target_position = flare_position
	state = State.DISTRACTED
	target = null
	_last_known_position = flare_position
	_timer = seconds


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


## Host only: a gunshot hit us. Enough damage drives it off for a while.
func take_damage(amount: float, from: Node = null) -> void:
	if not multiplayer.is_server() or amount <= 0.0:
		return
	if state == State.DORMANT and from is Player:
		_chase(from as Player)
	health -= amount
	_hit_flash.rpc()
	if health <= 0.0:
		health = max_health
		_drive_off()


## Host only: a tranquilizer dart. Stuns for a flat time (no light bonus),
## but it doesn't do damage.
func take_stun(seconds: float) -> void:
	if not multiplayer.is_server():
		return
	_last_known_position = target.global_position if target else global_position
	target = null
	state = State.STUNNED
	_timer = seconds
	velocity = Vector3.ZERO


## Host only: hurt too badly — it flees to recover instead of being killed
## (so a chase can always come back later).
func _drive_off() -> void:
	_last_known_position = global_position
	target = null
	state = State.STUNNED
	_timer = 4.0
	velocity = Vector3.ZERO
	_ignore_players_time = catch_cooldown


## Sent by the host when a shot lands, so everyone hears it.
@rpc("authority", "call_local", "reliable")
func _hit_flash() -> void:
	if has_node("Screech"):
		$Screech.play()


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
		State.DISTRACTED: return investigate_speed
	return 0.0


## A closed door in front of us: open it, or pound on it if someone holds it.
func _check_for_door() -> void:
	if _ignore_doors_time > 0.0:
		_ignore_doors_time -= get_physics_process_delta_time()
		return
	var door := door_probe.get_collider() as Door
	if door == null or door.is_open:
		return
	if door.is_held() or door.is_locked():
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

## True while it's on all fours (hunting). It stands up while waiting,
## pounding on a door, or flashed.
func is_crawling() -> bool:
	return has_node("CrawlBody") and not (state in [State.DORMANT, State.BLOCKED, State.STUNNED, State.STARE])


## The point the camera flash aims at (its head).
func get_aim_point() -> Vector3:
	return global_position + Vector3(0.0, 1.1 if is_crawling() else 2.3, 0.0)


## Sent by the host to the player it just caught.
@rpc("authority", "call_local", "reliable")
func _jump_scare() -> void:
	$Visuals.play_jump_scare()


## Sent by the host to a player it just flushed out of a hiding spot. The Wired
## floods the locker with current: a hard blue flash as they go down.
@rpc("authority", "call_local", "reliable")
func _overload_scare() -> void:
	$Visuals.play_jump_scare()
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.55, 0.75, 1.0)
	flash.light_energy = 8.0
	flash.omni_range = 7.0
	flash.position.y = 1.6
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.45)
	tween.tween_callback(flash.queue_free)


## Only the Son's computer calls this, so only he sees the glow.
func set_sensed(sensed: bool) -> void:
	$SenseGlow.visible = sensed
