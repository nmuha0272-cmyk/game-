extends Node
## Everything you see and hear from the monster: twitching when stunned,
## breathing, heavy footsteps and shrieks, crawling on all fours, and the
## jump scare when it catches you. Runs on every computer, using the state
## and position the host sends.

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
## The all-fours body (optional: a monster without one just walks).
@onready var _crawl: Node3D = monster.get_node_or_null("CrawlBody")
@onready var _crawl_head: Node3D = _crawl.get_node_or_null("HeadPivot") if _crawl else null
var _crawl_phase := 0.0
var _speed := 0.0

const JUMP_SCARE_SOUND := preload("res://assets/audio/monster_screech.wav")


func _ready() -> void:
	monster.get_node("SenseGlow").visible = false
	_last_position = monster.global_position


## Every few seconds the head snaps to a new angle, then settles. (Each
## computer twitches on its own; it's just for looks.)
func _update_head(delta: float) -> void:
	var head := _crawl_head if monster.is_crawling() else _head
	if head == null:
		return
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = randf_range(1.5, 5.0) * (0.4 if monster.state == Monster.State.CHASE else 1.0)
		_head_roll = randf_range(-35.0, 35.0) if randf() < 0.6 else 14.0
		head.rotation_degrees.z = _head_roll  # the snap
	head.rotation_degrees.z = lerpf(head.rotation_degrees.z, _head_roll * 0.8, clampf(delta * 2.0, 0.0, 1.0))


## Switches between standing and crawling, and moves the arms and legs like
## a spider: left arm with right leg, then right arm with left leg.
func _update_crawl(delta: float) -> void:
	if _crawl == null:
		return
	var crawling := monster.is_crawling()
	_crawl.visible = crawling
	body.visible = not crawling
	if not crawling:
		return
	_crawl_phase += delta * clampf(_speed, 0.0, 6.0) * 2.4
	var swing := sin(_crawl_phase) * clampf(_speed / 2.0, 0.0, 1.0) * 24.0
	var lift := maxf(0.0, cos(_crawl_phase)) * clampf(_speed / 2.0, 0.0, 1.0) * 14.0
	_crawl.get_node("ArmL").rotation_degrees = Vector3(swing + lift, 0, 0)
	_crawl.get_node("LegR").rotation_degrees = Vector3(swing - lift, 0, 0)
	_crawl.get_node("ArmR").rotation_degrees = Vector3(-swing + lift, 0, 0)
	_crawl.get_node("LegL").rotation_degrees = Vector3(-swing - lift, 0, 0)
	_crawl.position.y = absf(sin(_crawl_phase)) * 0.05 * clampf(_speed / 2.0, 0.0, 1.0)


## Only on the caught player's computer: its face lunges at your screen,
## a screech, a red flash, the screen shakes.
func play_jump_scare() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var source: Node3D = _crawl_head if (monster.is_crawling() and _crawl_head) else _head
	if source == null:
		source = body
	var face: Node3D = source.duplicate()
	face.transform = Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 1.5), Vector3(0, -0.05, -1.6))
	face.rotation_degrees.z = randf_range(-25.0, 25.0)
	camera.add_child(face)
	# A pale light from below so you see every detail of it.
	var light := OmniLight3D.new()
	light.light_color = Color(0.85, 0.9, 1.0)
	light.light_energy = 2.5
	light.omni_range = 2.0
	light.position = Vector3(0, -0.35, -0.3)
	camera.add_child(light)
	var sound := AudioStreamPlayer.new()
	sound.stream = JUMP_SCARE_SOUND
	sound.volume_db = 6.0
	sound.pitch_scale = 0.8
	camera.add_child(sound)
	sound.play()
	var layer := CanvasLayer.new()
	layer.layer = 40
	var flash := ColorRect.new()
	flash.color = Color(0.7, 0.0, 0.0, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(face, "position", Vector3(0, -0.1, -0.8), 0.12).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.45)
	# Shake while it's in your face.
	for i in 12:
		tween.tween_property(face, "position", Vector3(randf_range(-0.05, 0.05), -0.1 + randf_range(-0.04, 0.04), -0.8), 0.04)
	tween.tween_property(face, "position", Vector3(0, -0.3, -0.45), 0.15)
	await tween.finished
	face.queue_free()
	light.queue_free()
	layer.queue_free()
	await get_tree().create_timer(1.5).timeout
	sound.queue_free()


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
	_update_crawl(delta)
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
	_speed = lerpf(_speed, moved.length() / maxf(delta, 0.001), clampf(delta * 8.0, 0.0, 1.0))
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
