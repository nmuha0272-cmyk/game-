extends Node
## Plays the opening dialogue when the team arrives at the weather station
## as an ANIMATED CUTSCENE: black bars come down, the camera cuts to whoever
## is talking and slowly pushes in, the speaker acts the line (hand gestures,
## head nods) while the rest of the team turns to watch them. The line
## appears as a small caption at the bottom — there is no dialogue box,
## the characters are the scene.
## Nobody can move or look around while it plays. The host runs the timing,
## so every screen shows the same shot at the same time. TAP Space moves on
## to the next line, HOLD Space to skip the rest of the scene.
## Characters nobody picked get stand-in bodies for the scene only, so the
## whole team is on screen even in solo play.

@export var auto_play := true
## Seconds to wait after the intro cutscene before the characters talk.
@export var delay := 2.0

const SKIP_HOLD_TIME := 1.5
const CAMERA_FOV := 45.0
## Where the camera stands when someone speaks: in front of their face.
const SHOT_FORWARD := 2.5
const SHOT_SIDE := 0.8
const SHOT_UP := 0.15
## How far the camera creeps toward the speaker while the line plays.
const PUSH_DISTANCE := 0.7
const PUSH_TIME := 3.5
## How long a line stays up: reading time, with a floor and a ceiling.
const MIN_LINE_TIME := 2.5
const MAX_LINE_TIME := 9.0
const SECONDS_PER_CHAR := 0.055
## Eye height of a stand-in body (the camera aims here).
const STAND_IN_HEIGHT := 1.62
## Where the stand-ins stand, relative to the anchored player: an arc
## right in front of them, facing back.
const STAND_IN_OFFSETS := [
	Vector3(-1.8, 0.0, -2.4),
	Vector3(0.0, 0.0, -2.7),
	Vector3(1.8, 0.0, -2.4),
]

var played := false
var _camera: Camera3D = null
var _bars: CanvasLayer = null
var _caption_name: Label = null
var _caption_text: Label = null
var _caption_tween: Tween = null
## Stand-in bodies for characters nobody picked: character id -> Node3D.
var _stand_ins := {}
## Set when the host's continue key is pressed for the current line.
var _continue := false
var _skip_hold := 0.0
## The shot the camera is slowly pushing in along.
var _shot_pos := Vector3.ZERO
var _shot_look := Vector3.ZERO
var _shot_time := 0.0
## Yaw my own body is turning to while someone else talks (NAN = not turning).
var _body_turn_to := NAN

# The opening conversation when the team arrives at the weather station
const DIALOGUE := [
	{"character": "Journalist", "text": "There it is. The Blackwater Weather Station. Or what's left of it."},
	{"character": "Guard", "text": "Sixteen years since they sealed this place. And seven people have walked in since August."},
	{"character": "Engineer", "text": "I remember the night they locked it down... Said it was a gas leak. They lied."},
	{"character": "Son", "text": "My mom and dad died in there. Now Marcus and Jenna are in there too. I'm not losing anyone else."},
	{"character": "Journalist", "text": "My source went in a month ago. If anyone's still alive, they're underground."},
	{"character": "Guard", "text": "Then we'd better find a way in. Stay close. And keep your flashlights ready."},
	{"character": "Engineer", "text": "Something tells me we're not going to like what we find down there..."},
]

## Line speaker names -> character ids, so the camera can find that
## character's body among the players (or the stand-ins) in the level.
var SPEAKER_IDS := {
	"Journalist": Characters.Id.JOURNALIST,
	"Guard": Characters.Id.GUARD,
	"Engineer": Characters.Id.ENGINEER,
	"Son": Characters.Id.SON,
}


func _ready() -> void:
	if not auto_play or GameState.checkpoint_order != 0 or not multiplayer.is_server():
		return
	await _wait_for_intro()
	_trigger_dialogue.rpc()


## The host decides when the characters talk: first everyone has to be in the
## level, then the intro cutscene has to be off the screen so the two never
## overlap. If the team restarted at a checkpoint the cutscene was already
## seen and is skipped, so that part returns right away.
func _wait_for_intro() -> void:
	var waited := 0.0
	while waited < 8.0 and get_tree().get_nodes_in_group("players").size() < GameState.players.size():
		await get_tree().create_timer(0.2).timeout
		waited += 0.2

	var intro := get_node_or_null("../Cutscenes/Intro") as Cutscene
	if intro:
		waited = 0.0
		while not intro.is_done() and waited < 30.0:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
	await get_tree().create_timer(delay).timeout


@rpc("authority", "call_local", "reliable")
func _trigger_dialogue() -> void:
	if played:
		return

	# Ask each player for their perspective preference before the cutscene.
	# (Clear old answers first: an answer can arrive right away.)
	_perspective_choices.clear()
	_prompt_perspective.rpc()

	# Wait for all players to choose (host waits, clients respond).
	if multiplayer.is_server():
		await _wait_for_perspective_choices()

	played = true

	# The characters act while nobody can move or look around.
	get_tree().call_group("players", "set_movement_enabled", false)
	GameState.menu_open = true
	get_tree().call_group("player_hud", "hide")
	_set_nameplates(true)
	_set_bodies_visible(true)
	_spawn_stand_ins()
	_make_camera()
	_make_bars()

	if multiplayer.is_server():
		_run_lines()


## Host only: show each line in turn and wait out its reading time (or the
## player tapping Space to move on early).
func _run_lines() -> void:
	for i in range(DIALOGUE.size()):
		_play_line.rpc(i)
		if not await _wait_line(i):
			break  # held Space: skip the rest of the scene
	_end_dialogue.rpc()


## Host only: how long line i stays on screen.
func _line_time(i: int) -> float:
	var text: String = DIALOGUE[i].get("text", "")
	return clampf(MIN_LINE_TIME + text.length() * SECONDS_PER_CHAR,
			MIN_LINE_TIME, MAX_LINE_TIME)


## Host only: waits out the line's reading time. Returns false when the
## player held the key to skip the rest of the scene; a tap moves on early.
func _wait_line(i: int) -> bool:
	_continue = false
	_skip_hold = 0.0
	var waited := 0.0
	var budget := _line_time(i)
	while waited < budget:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		waited += delta
		if _continue:
			return true
		if Input.is_action_just_pressed("ui_accept"):
			_continue = true
		if Input.is_action_pressed("ui_accept"):
			_skip_hold += delta
			if _skip_hold >= SKIP_HOLD_TIME:
				return false
		else:
			_skip_hold = 0.0
	return true


@rpc("authority", "call_local", "reliable")
func _play_line(index: int) -> void:
	_aim_camera(index)
	_caption_line(index)
	_act_line(index)


@rpc("authority", "call_local", "reliable")
func _end_dialogue() -> void:
	if _camera:
		_camera.queue_free()
		_camera = null
	if _bars:
		_bars.queue_free()
		_bars = null
	_caption_name = null
	_caption_text = null
	_caption_tween = null
	for id: int in _stand_ins:
		_stand_ins[id].queue_free()
	_stand_ins.clear()
	_shot_look = Vector3.ZERO
	_body_turn_to = NAN
	for p in get_tree().get_nodes_in_group("players"):
		var model := (p as Player).get_node_or_null("BodyMesh") as CharacterModel
		if model:
			model.clear_acting()
	GameState.menu_open = false
	get_tree().call_group("player_hud", "show")
	_set_nameplates(false)
	_set_bodies_visible(false)
	get_tree().call_group("players", "set_movement_enabled", true)
	var me := Player.find(get_tree(), multiplayer.get_unique_id())
	if me and not me.downed.is_out:
		var my_camera := me.get_node_or_null("Head/Camera3D") as Camera3D
		if my_camera:
			my_camera.current = true


## The shot for this line: close on the speaker's face (or a wide shot of
## the team if that character isn't here), which _process then creeps
## along while the line plays.
func _aim_camera(index: int) -> void:
	if _camera == null:
		return
	var speaker_name: String = DIALOGUE[index].get("character", "")
	var speaker := _find_speaker_body(speaker_name)
	if speaker:
		var origin := _head_position(speaker)
		# Stand in front of their face, slightly off to one side.
		var forward := -speaker.global_transform.basis.z
		var right := speaker.global_transform.basis.x
		_shot_pos = origin + forward * SHOT_FORWARD + right * SHOT_SIDE
		_shot_pos.y += SHOT_UP
		_shot_look = origin
	else:
		# Nobody playing this character: wide shot of the whole team.
		var players := get_tree().get_nodes_in_group("players")
		if players.is_empty():
			return
		var center := Vector3.ZERO
		for p in players:
			center += (p as Node3D).global_position
		center /= players.size()
		center.y += 1.4
		_shot_pos = center + Vector3(0, 1.0, 6.0)
		_shot_look = center
	_shot_time = 0.0
	_camera.look_at_from_position(_shot_pos, _shot_look)


func _process(delta: float) -> void:
	# Slow push toward whoever is talking while their line plays.
	if _camera and not _shot_look.is_equal_approx(Vector3.ZERO):
		_shot_time += delta
		var k := smoothstep(0.0, 1.0, clampf(_shot_time / PUSH_TIME, 0.0, 1.0))
		var push := (_shot_look - _shot_pos).normalized() * PUSH_DISTANCE * k
		_camera.look_at_from_position(_shot_pos + push, _shot_look)
	# My own body turns to face whoever is talking (the others' bodies turn
	# on their own computer, and the turn is synced over the network).
	if not is_nan(_body_turn_to):
		var me := Player.find(get_tree(), multiplayer.get_unique_id())
		if me:
			me.rotation.y = lerp_angle(me.rotation.y, _body_turn_to,
					clampf(4.0 * delta, 0.0, 1.0))
	# Stand-ins turn in place too (every computer does the same maths, so
	# they all end up facing the same way).
	for id: int in _stand_ins:
		var body: Node3D = _stand_ins[id]
		var target: float = body.get_meta("turn_to", body.rotation.y)
		if is_nan(target):
			continue
		body.rotation.y = lerp_angle(body.rotation.y, target, clampf(4.0 * delta, 0.0, 1.0))


## Who is acting on this line: the speaker gestures and nods, everyone else
## (players and stand-ins) turns their head to watch them.
func _act_line(index: int) -> void:
	var speaker_name: String = DIALOGUE[index].get("character", "")
	var speaker := _find_speaker_body(speaker_name)
	var head := _head_position(speaker) if speaker else Vector3.ZERO

	for p in get_tree().get_nodes_in_group("players"):
		var player := p as Player
		var model := player.get_node_or_null("BodyMesh") as CharacterModel
		if model == null:
			continue
		if player == speaker:
			model.set_acting(1.0)
			model.set_glance(0.0)
			_body_turn_to = NAN
		else:
			model.set_acting(0.0)
			if speaker:
				model.glance_toward(head)
			else:
				model.set_glance(0.0)
		# Only my own body: its rotation is what I send to the others.
		if player.is_multiplayer_authority() and speaker and player != speaker:
			_body_turn_to = _yaw_toward(player.global_position, head)
		elif player.is_multiplayer_authority():
			_body_turn_to = NAN

	for id: int in _stand_ins:
		var body: Node3D = _stand_ins[id]
		var model := body.get_node_or_null("Model") as CharacterModel
		if model == null:
			continue
		if body == speaker:
			model.set_acting(1.0)
			model.set_glance(0.0)
		else:
			model.set_acting(0.0)
			if speaker:
				model.glance_toward(head)
			else:
				model.set_glance(0.0)
		if speaker and body != speaker:
			body.set_meta("turn_to", _yaw_toward(body.global_position, head))


## Yaw (radians) that makes a body at `from` face `toward`.
func _yaw_toward(from: Vector3, toward: Vector3) -> float:
	var dir := toward - from
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return NAN
	return atan2(-dir.x, -dir.z)


## The body that says this line: a real player, or a stand-in (in solo
## play only one of the four characters exists).
func _find_speaker_body(speaker_name: String) -> Node3D:
	if not SPEAKER_IDS.has(speaker_name):
		return null
	var wanted: int = SPEAKER_IDS[speaker_name]
	for p in get_tree().get_nodes_in_group("players"):
		if p is Player and p.character == wanted:
			return p
	if _stand_ins.has(wanted):
		return _stand_ins[wanted]
	return null


## Where a body's head is (the camera and the others look at this point).
func _head_position(body: Node3D) -> Vector3:
	if body is Player:
		var head := (body as Player).get_node_or_null("Head") as Node3D
		if head:
			return head.global_position
	return body.global_position + Vector3.UP * STAND_IN_HEIGHT


## Fills the team out: for every character nobody picked, a body stands in
## for them in front of the anchored player (lowest network id, so every
## computer builds the identical scene). Cutscene-only: freed at the end.
func _spawn_stand_ins() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var anchor: Player = players[0]
	for p in players:
		if (p as Player).name.to_int() < anchor.name.to_int():
			anchor = p
	var taken := {}
	for p in players:
		taken[(p as Player).character] = true
	var missing: Array = []
	for id in [Characters.Id.SON, Characters.Id.JOURNALIST,
			Characters.Id.ENGINEER, Characters.Id.GUARD]:
		if not taken.has(id):
			missing.append(id)
	for i in missing.size():
		var id: int = missing[i]
		var root := Node3D.new()
		root.name = "StandIn_%d" % id
		get_parent().add_child(root)
		root.global_position = anchor.global_transform * STAND_IN_OFFSETS[i]
		root.look_at(anchor.global_position + Vector3.UP * 1.4, Vector3.UP)
		var model := CharacterModel.new()
		model.name = "Model"
		root.add_child(model)
		model.setup(id, false)
		_stand_ins[id] = root


## The small caption at the bottom: who is talking, then the line itself.
func _caption_line(index: int) -> void:
	if _caption_name == null or _caption_text == null:
		return
	var line: Dictionary = DIALOGUE[index]
	var speaker_name: String = line.get("character", "")
	var id: int = SPEAKER_IDS.get(speaker_name, Characters.Id.NONE)
	_caption_name.text = Characters.display_name(id).to_upper()
	_caption_text.text = line.get("text", "")
	if _caption_tween:
		_caption_tween.kill()
	for label: Label in [_caption_name, _caption_text]:
		label.modulate.a = 0.0
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption_name, "modulate:a", 1.0, 0.3)
	_caption_tween.parallel().tween_property(_caption_text, "modulate:a", 1.0, 0.35)


## Nameplates would spoil the shot (the caption already says who is
## talking), so they are hidden for the scene and the normal rule —
## visible on other people, hidden on your own — comes back after.
func _set_nameplates(hidden: bool) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		var plate := (p as Player).get_node_or_null("Nameplate") as Label3D
		if plate == null:
			continue
		if hidden:
			plate.visible = false
		else:
			plate.set_force_visible(false)


## Your own model is normally shadow-only (the camera sits inside your
## head). Show every model fully so the whole team is in frame — only the
## shadow flag is toggled, the models themselves are untouched.
func _set_bodies_visible(full: bool) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		var player := p as Player
		var body := player.get_node_or_null("BodyMesh")
		if body == null:
			continue
		var shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if not full and player.is_multiplayer_authority():
			# Third person keeps the body drawn (perspective.gd owns that).
			var persp := player.get_node_or_null("Perspective") as Perspective
			if persp == null or not persp.third_person:
				shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		for part in body.find_children("*", "MeshInstance3D", true, false):
			part.cast_shadow = shadow


func _make_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	add_child(_camera)
	_camera.current = true


func _make_bars() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 19
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.88
		bar.anchor_bottom = 0.12 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(bar)

	_caption_name = Label.new()
	_caption_name.anchor_left = 0.15
	_caption_name.anchor_right = 0.85
	_caption_name.anchor_top = 0.895
	_caption_name.anchor_bottom = 0.935
	_caption_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_name.add_theme_font_size_override("font_size", 16)
	_caption_name.add_theme_color_override("font_color", Color(0.62, 0.58, 0.5))
	_caption_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_caption_name)

	_caption_text = Label.new()
	_caption_text.anchor_left = 0.12
	_caption_text.anchor_right = 0.88
	_caption_text.anchor_top = 0.935
	_caption_text.anchor_bottom = 0.995
	_caption_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_text.add_theme_font_size_override("font_size", 24)
	_caption_text.add_theme_color_override("font_color", Color(0.88, 0.86, 0.8))
	_caption_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_caption_text)

	var hint := Label.new()
	hint.text = "Hold [Space] to skip"
	hint.anchor_left = 0.85
	hint.anchor_right = 0.99
	hint.anchor_top = 0.02
	hint.anchor_bottom = 0.1
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	layer.add_child(hint)
	add_child(layer)
	_bars = layer


## Each player chooses first/third person before the chapter starts.
## Runs on all clients; host waits for all to respond.
@rpc("authority", "call_local", "reliable")
func _prompt_perspective() -> void:
	# In playtest mode, auto-choose first person so the test can proceed.
	if OS.get_cmdline_user_args().has("--playtest"):
		var me_test := Player.find(get_tree(), multiplayer.get_unique_id())
		if me_test:
			var persp_test := me_test.get_node_or_null("Perspective") as Perspective
			if persp_test:
				persp_test.third_person = false
		# Directly append since we're on the host in playtest.
		_perspective_choices.append(false)
		return

	var me := Player.find(get_tree(), multiplayer.get_unique_id())
	if me == null:
		_report_perspective_choice.rpc_id(1, false)
		return
	var persp := me.get_node_or_null("Perspective") as Perspective
	if persp == null:
		_report_perspective_choice.rpc_id(1, false)
		return

	# Simple prompt: show text, wait for 1 or 3 key.
	var layer := CanvasLayer.new()
	layer.layer = 20
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	layer.add_child(bg)

	var label := Label.new()
	label.text = "Choose camera:\n[1] First Person\n[3] Third Person (C toggles later)"
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(label)

	add_child(layer)

	var chosen_third := false

	# Poll for key press (1 or 3) since we can't use a local function with nonlocal.
	while true:
		await get_tree().process_frame
		if Input.is_key_pressed(KEY_1) or Input.is_key_pressed(KEY_KP_1):
			chosen_third = false
			break
		if Input.is_key_pressed(KEY_3) or Input.is_key_pressed(KEY_KP_3):
			chosen_third = true
			break

	persp.third_person = chosen_third
	layer.queue_free()
	_report_perspective_choice.rpc_id(1, chosen_third)


@rpc("any_peer", "call_local", "reliable")
func _report_perspective_choice(third: bool) -> void:
	_perspective_choices.append(third)


var _perspective_choices: Array[bool] = []


## Host only: wait until every player has reported a choice.
func _wait_for_perspective_choices() -> void:
	var expected := GameState.players.size()
	if expected == 0:
		expected = 1
	# Never wait forever: after 30 seconds the scene starts anyway (anyone who
	# didn't answer keeps their Settings choice).
	var waited := 0.0
	while _perspective_choices.size() < expected and waited < 30.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
