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
## The real model with bones (optional). When it's there, the old sculpted
## bodies are hidden and its bones are moved instead.
@onready var _rig := body.get_node_or_null("Rig") as LongManRig
var _crawl_amount := 0.0
var _roll := 0.0
var _look_yaw := 0.0

const JUMP_SCARE_SOUND := preload("res://assets/audio/monster_screech.wav")
const NECK_CRACK := preload("res://assets/audio/neck_crack.wav")
const SKITTER := preload("res://assets/audio/skitter.wav")
var _crack: AudioStreamPlayer3D
var _skitter: AudioStreamPlayer3D


func _ready() -> void:
	monster.get_node("SenseGlow").visible = false
	if _rig:
		for part in ["Sculpt", "HeadPivot"]:
			if body.has_node(part):
				body.get_node(part).visible = false
		if _crawl:
			_crawl.visible = false
	_last_position = monster.global_position
	_crack = AudioStreamPlayer3D.new()
	_crack.stream = NECK_CRACK
	_crack.unit_size = 6.0
	_crack.position = Vector3(0, 2.4, -0.3)
	monster.add_child.call_deferred(_crack)
	_skitter = AudioStreamPlayer3D.new()
	_skitter.stream = SKITTER
	_skitter.unit_size = 5.0
	_skitter.position = Vector3(0, 0.2, -0.8)
	monster.add_child.call_deferred(_skitter)


## Every few seconds the head snaps to a new angle, then settles. (Each
## computer twitches on its own; it's just for looks.)
func _update_head(delta: float) -> void:
	if _rig:
		_update_rig_head(delta)
		return
	var head := _crawl_head if monster.is_crawling() else _head
	if head == null:
		return
	if monster.state == Monster.State.STARE:
		# Staring at you: the head slowly tips over sideways. Wrong.
		head.rotation_degrees.z = lerpf(head.rotation_degrees.z, 75.0, clampf(delta * 1.2, 0.0, 1.0))
		_twitch_timer = 0.3
		return
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = randf_range(1.5, 5.0) * (0.4 if monster.state == Monster.State.CHASE else 1.0)
		_head_roll = randf_range(-35.0, 35.0) if randf() < 0.6 else 14.0
		head.rotation_degrees.z = _head_roll  # the snap
		if randf() < 0.6 and _crack and _crack.is_inside_tree():
			_crack.pitch_scale = randf_range(0.8, 1.2)
			_crack.play()
	head.rotation_degrees.z = lerpf(head.rotation_degrees.z, _head_roll * 0.8, clampf(delta * 2.0, 0.0, 1.0))


## Same twitching as below, for the model with bones.
func _update_rig_head(delta: float) -> void:
	if monster.state == Monster.State.STARE:
		_roll = lerpf(_roll, 75.0, clampf(delta * 1.2, 0.0, 1.0))
		_twitch_timer = 0.3
		return
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = randf_range(1.5, 5.0) * (0.4 if monster.state == Monster.State.CHASE else 1.0)
		_head_roll = randf_range(-35.0, 35.0) if randf() < 0.6 else 14.0
		_roll = _head_roll  # the snap
		if randf() < 0.6 and _crack and _crack.is_inside_tree():
			_crack.pitch_scale = randf_range(0.8, 1.2)
			_crack.play()
	_roll = lerpf(_roll, _head_roll * 0.8, clampf(delta * 2.0, 0.0, 1.0))


## Bends the model with bones: walking, or down on all fours.
func _update_rig(delta: float) -> void:
	var target := 1.0 if monster.is_crawling() else 0.0
	_crawl_amount = lerpf(_crawl_amount, target, clampf(delta * 4.0, 0.0, 1.0))
	var amount := clampf(_speed / 2.0, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	# Broken, uneven steps: the pace keeps jerking faster and slower.
	var stutter := 1.0 + 0.7 * sin(t * 3.1) * sin(t * 1.7)
	_crawl_phase += delta * clampf(_speed, 0.0, 6.0) * (2.4 if target > 0.5 else 1.6) * maxf(stutter, 0.15)
	var breath := sin(t * (5.0 if monster.state == Monster.State.CHASE else 2.0))
	_look_yaw = lerpf(_look_yaw, _yaw_to_nearest_player(), clampf(delta * 3.0, 0.0, 1.0))
	_rig.set_pose(_crawl_phase, amount, _crawl_amount, _roll, breath, 0.0, _look_yaw, t)


## How far (degrees, + = his left) he has to turn his head to look at the
## closest player. 0 when nobody is near.
func _yaw_to_nearest_player() -> float:
	var best := 15.0
	var yaw := 0.0
	for player: Node3D in get_tree().get_nodes_in_group("players"):
		var d := monster.global_position.distance_to(player.global_position)
		if d < best:
			best = d
			var local := monster.to_local(player.global_position)
			yaw = rad_to_deg(atan2(-local.x, -local.z))
	return clampf(yaw, -70.0, 70.0)


## Switches between standing and crawling, and moves the arms and legs like
## a spider: left arm with right leg, then right arm with left leg.
func _update_crawl(delta: float) -> void:
	if _rig:
		_update_rig(delta)
		return
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
	if _rig:
		_grab_and_slash(camera)
		return
	var face: Node3D
	var source: Node3D = _crawl_head if (monster.is_crawling() and _crawl_head) else _head
	if source == null:
		source = body
	face = source.duplicate()
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
	var sound := _scare_sound(camera, 0.8)
	var layer := _scare_layer()
	var flash := _red_flash(layer, 0.4)
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


## The jump scare with the real model: he lunges, GRABS you and lifts you
## up to his face (your view rises and shakes), screams, then rakes his
## claws across you: three red claw marks rip across the screen, a red
## flash... and black.
func _grab_and_slash(camera: Camera3D) -> void:
	var face := (load(_rig.scene_file_path) as PackedScene).instantiate()
	face.set_script(_rig.get_script())
	var rig_face := face as LongManRig
	camera.add_child(face)
	var roll := randf_range(-30.0, 30.0)
	rig_face.set_grab_pose(0.0, 0.0, roll, 0.0)
	face.transform = Transform3D(Basis.from_scale(Vector3.ONE * 1.4), Vector3.ZERO)  # already faces you
	var offset: Vector3 = -(face.transform.basis * rig_face.head_position()) + Vector3(0, 0.12, 0)
	face.position = offset + Vector3(0, -0.05, -1.7)
	var light := OmniLight3D.new()
	light.light_color = Color(0.85, 0.9, 1.0)
	light.light_energy = 1.4
	light.omni_range = 2.5
	light.position = Vector3(0, -0.35, -0.3)
	camera.add_child(light)
	var sound := _scare_sound(camera, 0.8)
	var layer := _scare_layer()
	var flash := _red_flash(layer, 0.35)
	var camera_rest := camera.position
	var t := 0.0
	var slashed := false
	# 0 - 0.2 s: the lunge. 0.2 - 1.3 s: grabbed and lifted. 1.3 - 1.6 s: the slash.
	while t < 1.75 and is_instance_valid(face):
		var dt := get_process_delta_time()
		t += dt
		var lunge := clampf(t / 0.2, 0.0, 1.0)
		var raise := clampf((t - 0.15) / 0.45, 0.0, 1.0)
		var slash := clampf((t - 1.3) / 0.12, 0.0, 1.0)
		rig_face.set_grab_pose(raise, slash, roll, t)
		var shake := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * (0.02 + 0.03 * raise)
		face.position = offset + Vector3(0, -0.05, lerpf(-1.7, -0.55, lunge)) + shake
		# You're lifted off the ground: the view rises and tips.
		camera.position = camera_rest + Vector3(0, 0.7 * raise, 0)
		camera.rotation.z = sin(t * 9.0) * 0.06 * raise
		flash.color.a = maxf(flash.color.a - dt * 1.2, 0.0)
		if slash > 0.0 and not slashed:
			slashed = true
			_claw_marks(layer)
			flash.color = Color(0.75, 0.0, 0.0, 0.85)
			var swipe := _scare_sound(camera, 1.5)
			swipe.volume_db = 10.0
		await get_tree().process_frame
	# Black.
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	if is_instance_valid(face):
		face.queue_free()
	light.queue_free()
	camera.position = camera_rest
	camera.rotation.z = 0.0
	await get_tree().create_timer(1.6).timeout
	layer.queue_free()
	sound.queue_free()


func _scare_sound(camera: Camera3D, pitch: float) -> AudioStreamPlayer:
	var sound := AudioStreamPlayer.new()
	sound.stream = JUMP_SCARE_SOUND
	sound.volume_db = 6.0
	sound.pitch_scale = pitch
	camera.add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)
	return sound


func _scare_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	return layer


func _red_flash(layer: CanvasLayer, alpha: float) -> ColorRect:
	var flash := ColorRect.new()
	flash.color = Color(0.7, 0.0, 0.0, alpha)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	return flash


## Three claw marks torn diagonally across the screen.
func _claw_marks(layer: CanvasLayer) -> void:
	var size := get_viewport().get_visible_rect().size
	for k in 3:
		var mark := ColorRect.new()
		mark.color = Color(0.45, 0.0, 0.0, 0.95)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size = Vector2(size.length() * 0.9, size.y * 0.035)
		mark.pivot_offset = Vector2(0, mark.size.y / 2)
		mark.position = Vector2(-size.x * 0.05, size.y * (0.12 + k * 0.17))
		mark.rotation = deg_to_rad(28.0)
		mark.scale = Vector2(0.0, 1.0)
		layer.add_child(mark)
		var tween := create_tween()
		tween.tween_interval(k * 0.05)
		tween.tween_property(mark, "scale:x", 1.0, 0.09)


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
	var crawling := monster.is_crawling()
	if _walked >= (stride * 0.45 if crawling else stride):
		_walked = 0.0
		if crawling and _skitter and _skitter.is_inside_tree():
			# Fast, dry taps of bony hands and feet on concrete.
			_skitter.pitch_scale = randf_range(0.8, 1.35)
			_skitter.play()
		else:
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
		Monster.State.STARE:
			breath.pitch_scale = 0.6
			breath.volume_db = 4.0
		Monster.State.STUNNED:
			screech.play()
