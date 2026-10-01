extends Node
## Everything you see and hear from the monster: twitching when stunned,
## breathing, heavy footsteps and shrieks. Runs on every computer, using the
## state and position the host sends.

@export var monster: Monster
@export var body: Node3D
@export var breath: AudioStreamPlayer3D
@export var shriek: AudioStreamPlayer3D
@export var screech: AudioStreamPlayer3D
@export var footsteps: AudioStreamPlayer3D
## Meters between heavy footsteps.
@export var stride := 1.1
## BACKUP for when there's no Son (who can sense monsters): it clicks now
## and then, so players can track it by ear instead.
@export var click: AudioStreamPlayer3D
@export var click_every := 2.5

var _last_state := -1
var _last_position := Vector3.ZERO
var _walked := 0.0
var _click_timer := 0.0
var _fold := 0.0
var _twitch_timer := 2.0
var _head_roll := 14.0
@onready var _head: Node3D = body.get_node_or_null("HeadPivot")


func _ready() -> void:
	monster.get_node("SenseGlow").visible = false
	_last_position = monster.global_position


## Every few seconds the head snaps to a new angle, then settles. (Each
## computer twitches on its own; it's just for looks.)
func _update_head(delta: float) -> void:
	if _head == null:
		return
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = randf_range(1.5, 5.0) * (0.4 if monster.state == Monster.State.CHASE else 1.0)
		_head_roll = randf_range(-35.0, 35.0) if randf() < 0.6 else 14.0
		_head.rotation_degrees.z = _head_roll  # the snap
	_head.rotation_degrees.z = lerpf(_head.rotation_degrees.z, _head_roll * 0.8, clampf(delta * 2.0, 0.0, 1.0))


## The Long Man doesn't fit in the tunnels. Under a low ceiling he folds
## over (shorter and hunched forward).
func _update_folding(delta: float) -> void:
	var from := monster.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * 2.3)
	query.exclude = [monster.get_rid()]
	var low_ceiling := not monster.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	var fold := 1.0 if low_ceiling else 0.0
	_fold = lerpf(_fold, fold, clampf(delta * 3.0, 0.0, 1.0))
	body.scale = Vector3(1.0, lerpf(1.0, 0.8, _fold), 1.0)
	body.rotation_degrees.x = lerpf(0.0, -22.0, _fold)


func _process(delta: float) -> void:
	_update_folding(delta)
	if monster.state != _last_state:
		_on_state_changed(monster.state)
		_last_state = monster.state

	_update_head(delta)

	# Twitch while stunned.
	if monster.is_stunned:
		body.position = Vector3(randf_range(-0.04, 0.04), 0.0, randf_range(-0.04, 0.04))
	else:
		body.position = Vector3.ZERO

	# Footsteps from how far it actually moved (works on every computer).
	var moved := monster.global_position - _last_position
	moved.y = 0.0
	_last_position = monster.global_position
	if moved.length() < 1.0:  # ignore teleports
		_walked += moved.length()
	if _walked >= stride:
		_walked = 0.0
		footsteps.pitch_scale = randf_range(0.55, 0.7)
		footsteps.play()

	if click and not GameState.team_has(Characters.Id.SON) and monster.state != Monster.State.DORMANT:
		_click_timer -= delta
		if _click_timer <= 0.0:
			_click_timer = click_every
			click.play()

	# Breathing gets faster and louder during a chase.
	var chasing := monster.state == Monster.State.CHASE
	breath.pitch_scale = lerpf(breath.pitch_scale, 1.35 if chasing else 0.9, delta * 2.0)
	breath.volume_db = lerpf(breath.volume_db, 2.0 if chasing else -6.0, delta * 2.0)


func _on_state_changed(new_state: int) -> void:
	match new_state:
		Monster.State.CHASE:
			shriek.play()
		Monster.State.STUNNED:
			screech.play()
