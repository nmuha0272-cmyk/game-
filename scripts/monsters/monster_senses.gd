class_name MonsterSenses
extends Node3D
## The monster's eyes and ears. Sits at eye height and faces the same way
## as the monster. Only the host uses it.
##
## Tips for players (this is what the numbers below mean):
## - A flashlight makes you visible from much further away.
## - Crouching in the dark is the best way to hide.
## - Sprinting is loud. The Guard is louder than everyone else.

## How far it can see a normal player.
@export var sight_range := 12.0
## How far it can see a player whose flashlight is on.
@export var flashlight_sight_range := 22.0
## How far it can see a crouching player with their flashlight off.
@export var crouch_sight_range := 5.0
## How wide its vision is (degrees to each side of straight ahead).
@export var view_angle := 60.0
## It always notices players this close, even behind it.
@export var feel_range := 2.0

@export_group("Hearing")
## How far away footsteps can be heard (through walls too).
@export var walk_noise := 5.0
@export var sprint_noise := 14.0
@export var crouch_noise := 1.0
## The Guard's footsteps carry this many times further.
@export var guard_noise_multiplier := 1.6


## Nearest player it can see right now (or null).
func find_visible_player() -> Player:
	return _nearest(func(player: Player) -> bool: return can_see(player))


## Nearest player whose footsteps it can hear right now (or null).
func find_heard_player() -> Player:
	return _nearest(func(player: Player) -> bool:
		return _is_target(player) and \
				global_position.distance_to(player.global_position) <= noise_radius(player))


func can_see(player: Player) -> bool:
	if not _is_target(player):
		return false
	var head := player.global_position + Vector3.UP * (0.8 if player.is_crouching else 1.4)
	var to_player := head - global_position
	var distance := to_player.length()

	var max_range := sight_range
	if player.flashlight_on:
		max_range = flashlight_sight_range
	elif player.is_crouching:
		max_range = crouch_sight_range
	if distance > max_range:
		return false

	if distance > feel_range:
		var forward := -global_basis.z
		var flat := Vector3(to_player.x, 0.0, to_player.z)
		if rad_to_deg(Vector3(forward.x, 0.0, forward.z).angle_to(flat)) > view_angle:
			return false
	return _has_line_of_sight(head, player)


## How far away this player's footsteps can be heard right now.
func noise_radius(player: Player) -> float:
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	if speed < 0.5 or not player.is_grounded:
		return 0.0
	var radius := walk_noise
	if player.is_sprinting:
		radius = sprint_noise
	elif player.is_crouching:
		radius = crouch_noise
	if player.character == Characters.Id.GUARD:
		radius *= guard_noise_multiplier
	return radius


## Downed and carried players are left alone.
func _is_target(player: Player) -> bool:
	return is_instance_valid(player) and not player.is_downed


func _has_line_of_sight(point: Vector3, player: Player) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, point)
	query.exclude = [owner.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player


func _nearest(test: Callable) -> Player:
	var best: Player = null
	var best_distance := INF
	for player: Player in get_tree().get_nodes_in_group("players"):
		if test.call(player):
			var distance := global_position.distance_to(player.global_position)
			if distance < best_distance:
				best = player
				best_distance = distance
	return best
