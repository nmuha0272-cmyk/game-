extends Node3D
## Deepwell home screen: a car driving down a dark forest road at night.
##
## MENU:   the camera watches the car from outside, with the title and buttons
##         (main_menu.tscn) on top.
## SELECT: after Host or Join, the camera moves into the back seat, looking
##         forward: Eli is driving, Cole is next to him, Nora and Walter are in
##         the back. Hover over a name card (or a character) and the camera
##         moves to that character's side and shows what they can do.
##         Click to choose them. Arrow keys and Enter also work.
## Picking a character shows their face in the rear-view mirror.
## TALK:   after "PLAY AS ...", the team talks while Eli drives (subtitles at
##         the bottom): "Uncle Cole, why is there a journalist and an old man
##         in the car?" Tap Space for the next line, hold Space to skip.
## ARRIVING: after the talk, the camera moves behind the car
##         and it drives up to the gate of the Blackwater Weather Station,
##         slows to a stop, and the screen fades to black before the lobby
##         (or next scene) loads. Press Enter or Esc to skip the drive.
##
## The seats show simple sitting figures. The team's real models (MODEL_FILES)
## sit there instead once they have a skeleton; for now they are T-pose
## statues, which can't sit, so they appear in the game instead.

signal character_confirmed(character_id: String)
## Only when `embedded`: the arrival drive finished and the screen is black.
signal arrived(character_id: String)

## True when this home screen runs inside the game's main scene
## (scenes/main.tscn). Then main.gd does the networking: Host/Join only send
## signals, main.gd calls enter_select() once the game is hosted/joined, and
## after the drive it emits `arrived` instead of changing scene.
var embedded := false

const MENU_UI := preload("res://scenes/main_menu/deepwell/main_menu.tscn")
const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"
const MODEL_PATH := "res://assets/models/characters/%s.glb"
## The team's real models (file names kept as they are) and how tall each
## person is, same as scripts/player/character_model.gd.
const MODEL_FILES := {"eli": ["eli", 1.78], "cole": ["frank", 1.9], "nora": ["journalist", 1.68], "walter": ["engineer", 1.75]}
const RIGGED_MODEL_HEIGHT := 0.98

const COLOR_TEXT := Color("d9d3c1")
const COLOR_DIM := Color("7b786c")
const COLOR_HIGHLIGHT := Color("e8b04a")
const COLOR_RED := Color("c0392b")

const DRIVE_SPEED := 17.0  # meters per second
const STATION_START_Z := -75.0  # where the station appears, far down the road
const STATION_STOP_Z := -9.0    # where its gate is when the car has stopped
const ROAD_LENGTH := 160.0

## Order is the order the arrow keys cycle through.
const CHARACTER_ORDER := ["eli", "cole", "nora", "walter"]
const CHARACTERS := {
	"eli": {
		"side_cam": Vector3(0.3, 1.52, -0.66),
		"side_look": Vector3(-0.38, 1.4, -0.05),
		"name": "ELI REYES",
		"role": "THE SON  //  TRACKER",
		"seat": Vector3(-0.38, 0.0, -0.1),
		"color": Color(0.38, 0.23, 0.12),
		"size": 1.0,
		"about": "21. College student and Army Reserve soldier. Both his parents died here in 1999. Now his two best friends are missing in there.",
		"abilities": [
			"SENSE: hold to see nearby monsters through walls for 3 seconds (20s cooldown).",
			"MILITARY TRAINING: steadier aim and faster reloads. Reads Morse code and military maps.",
			"MENTOR BOND: works better when Cole is close by.",
		],
		"quote": "\"Dad always said: slow is smooth, smooth is fast.\"",
	},
	"cole": {
		"side_cam": Vector3(-0.3, 1.52, -0.66),
		"side_look": Vector3(0.38, 1.42, -0.05),
		"name": "COLE BRENNAN",
		"role": "THE GUARD  //  PROTECTOR",
		"seat": Vector3(0.38, 0.0, -0.1),
		"color": Color(0.29, 0.32, 0.19),
		"size": 1.12,
		"about": "36. Former soldier. Raised Eli after his parents died, like a father. Knows this place better than he admits.",
		"abilities": [
			"STRENGTH: hold doors shut, move heavy objects, build barricades, carry downed teammates.",
			"FIELD TRAINING: longer stuns, and can study a monster to show the team its weak point.",
			"Best with firearms, but slower and louder than everyone else.",
		],
		"quote": "\"Eyes up, kid. Stay behind me.\"",
	},
	"nora": {
		"side_cam": Vector3(0.08, 1.52, 0.38),
		"side_look": Vector3(-0.55, 1.4, 1.02),
		"name": "NORA VANCE",
		"role": "THE JOURNALIST  //  STUNNER",
		"seat": Vector3(-0.55, 0.08, 1.02),
		"color": Color(0.7, 0.58, 0.4),
		"size": 0.95,
		"about": "35. Investigative journalist. Her source vanished trying to expose Deepwell. She wants the proof.",
		"abilities": [
			"CAMERA FLASH: stuns a monster in front of her for 2 seconds (15s cooldown).",
			"EVIDENCE: photograph clues to unlock story files for the whole team.",
		],
		"quote": "\"If it's real, I'm getting it on film.\"",
	},
	"walter": {
		"side_cam": Vector3(-0.08, 1.52, 0.38),
		"side_look": Vector3(0.55, 1.4, 1.02),
		"name": "WALTER KESSLER",
		"role": "THE ENGINEER  //  FIXER",
		"seat": Vector3(0.55, 0.08, 1.02),
		"color": Color(0.13, 0.17, 0.32),
		"size": 0.97,
		"about": "60. Worked at Deepwell before it was sealed. Nervous, quiet, and hiding something.",
		"abilities": [
			"REPAIR: the only one who can fix generators, elevators and panels.",
			"HACK: opens locked security doors, but it takes time, so someone has to guard him.",
		],
		"quote": "\"I can fix it. Just keep them away from me.\"",
	},
}

enum State { MENU, SELECT, TALK, ARRIVING }

## What the team says on the way: [character id, line].
const TALK := [
	["eli", "So... Uncle Cole. Why is there a journalist and an old man in the car?"],
	["cole", "Eli, they're here because—"],
	["nora", "I can speak for myself, thanks. Nora Vance. My source went missing out here a month ago, and I'm going to find out why."],
	["walter", "Walter Kessler. I worked at that station, a long time ago. I know the way in."],
	["cole", "They want the same thing we do, kid. We find Marcus and Jenna, and we get out."],
	["eli", "...Okay. Okay."],
]
## The rear-view mirror, above the dashboard (car space).
const MIRROR_POS := Vector3(0.0, 1.62, -0.6)

var state := State.MENU
var hovered := ""
var selected := ""
var taken: Array[String] = []

var _time := 0.0
var _car: Node3D
var _roof: Node3D
var _camera: Camera3D
var _scrollers: Array[Node3D] = []
var _figures := {}      # id -> {"root": Node3D, "materials": Array, "label": Label3D}
var _menu: Control
var _select_ui: Control
var _info_name: Label
var _info_role: Label
var _info_about: Label
var _info_abilities: Label
var _info_quote: Label
var _confirm_button: Button
var _hint: Label
var _cards := {}  # id -> Button
var _unhover_timer: SceneTreeTimer
var _speed := DRIVE_SPEED
var _station: Node3D
var _trees: Array[Node3D] = []
var _fade: ColorRect
var _arrival_label: Label
var _arrived := false
# The car talk.
var _talk_line := -1
var _talk_time := 0.0
var _talk_length := 0.0
var _talk_hold := 0.0
var _talk_ui: Control
var _talk_name: Label
var _talk_text: Label
# The rear-view mirror.
var _mirror_cam: Camera3D
var _mirror_view: SubViewport
var _mirror_until := 0.0
var _last_selected := ""

const MENU_CAM_POS := Vector3(-4.2, 1.35, -6.0)
const MENU_CAM_TARGET := Vector3(-1.4, 0.95, 0.4)
const ARRIVE_CAM_POS := Vector3(-2.4, 2.6, 7.0)
const ARRIVE_CAM_TARGET := Vector3(0.6, 1.6, -14.0)
const BACKSEAT_CAM_POS := Vector3(0.0, 1.5, 1.18)
const BACKSEAT_CAM_TARGET := Vector3(0.0, 1.32, -3.0)


func _ready() -> void:
	get_viewport().physics_object_picking = true
	randomize()
	_build_environment()
	_build_road_and_forest()
	_build_station()
	_build_car()
	for id: String in CHARACTER_ORDER:
		_build_character(id)
	_build_mirror()
	_build_camera()
	_build_ui()
	_set_state(State.MENU)


func _process(delta: float) -> void:
	_time += delta

	# Move the world toward the camera so the car looks like it's driving.
	if state == State.ARRIVING:
		_update_arrival(delta)
	elif state == State.TALK:
		_update_talk(delta)
	_update_mirror(delta)

	for node in _scrollers:
		node.position.z += _speed * delta
		if node.position.z > 30.0:
			node.position.z -= ROAD_LENGTH
			if node.has_meta("side"):
				node.position.x = float(node.get_meta("side")) * randf_range(5.5, 20.0)

	# Bumpy road: the car bobs and sways a little.
	var shake := _speed / DRIVE_SPEED
	_car.position.y = (sin(_time * 9.0) * 0.008 + sin(_time * 2.3) * 0.012) * shake
	_car.rotation.z = sin(_time * 1.7) * 0.006 * shake
	_car.rotation.x = sin(_time * 3.1) * 0.003 * shake

	# Characters breathe and sway with the car.
	for id: String in _figures:
		var root: Node3D = _figures[id]["root"]
		root.position.y = sin(_time * 1.6 + root.position.x * 3.0) * 0.006

	# Rigged models sit: thighs forward, knees bent, Eli's hands on the wheel.
	for id: String in _figures:
		var rig := _figures[id]["rig"] as HumanRig
		if rig == null:
			continue
		rig.set_pose(0.0, 0.0, 0.0, 0.0, sin(_time * 1.6))
		for leg in ["LeftUpLeg", "RightUpLeg"]:
			rig._turn(leg, HumanRig.SIDE, -85.0)
		for knee in ["LeftLeg", "RightLeg"]:
			rig._turn(knee, HumanRig.SIDE, 85.0)
		if id == "eli":
			for arm in ["LeftArm", "RightArm"]:
				rig._turn(arm, HumanRig.SIDE, -55.0)

	# Glide the camera toward where it should be right now.
	var pos := MENU_CAM_POS + Vector3(sin(_time * 0.21) * 0.35, sin(_time * 0.33) * 0.08, 0.0)
	var look := MENU_CAM_TARGET
	if state == State.ARRIVING:
		pos = ARRIVE_CAM_POS
		look = ARRIVE_CAM_TARGET
	elif state == State.TALK and _talk_line >= 0 and _talk_line < TALK.size():
		# The camera goes to whoever is talking.
		var who: String = TALK[_talk_line][0]
		pos = CHARACTERS[who]["side_cam"] + Vector3(sin(_time * 0.6) * 0.012, sin(_time * 0.9) * 0.01, 0.0)
		look = CHARACTERS[who]["side_look"]
	elif state == State.SELECT:
		if hovered != "":
			pos = CHARACTERS[hovered]["side_cam"]
			look = CHARACTERS[hovered]["side_look"]
		else:
			pos = BACKSEAT_CAM_POS
			look = BACKSEAT_CAM_TARGET
		# Just picked someone: look into the rear-view mirror at them.
		if _time < _mirror_until:
			pos = MIRROR_POS + Vector3(0.02, -0.06, 0.55)
			look = MIRROR_POS + Vector3(0.0, 0.07, 0.0)  # the mirror sits low, below the info panel
		pos += Vector3(sin(_time * 0.6) * 0.012, sin(_time * 0.9) * 0.01, 0.0)  # road bumps
	_camera.fov = lerpf(_camera.fov, 28.0 if state == State.SELECT and _time < _mirror_until else 55.0, minf(delta * 4.0, 1.0))
	# The cards fade away while you look in the mirror, so they don't cover it.
	if _select_ui:
		_select_ui.modulate.a = move_toward(_select_ui.modulate.a, 0.0 if _time < _mirror_until else 1.0, delta * 4.0)
	var target := Transform3D().looking_at(look - pos)
	target.origin = pos
	_camera.global_transform = _camera.global_transform.interpolate_with(target, 1.0 - exp(-4.0 * delta))


func _unhandled_input(event: InputEvent) -> void:
	if state == State.TALK:
		# A tap on Space (or a click) moves on; holding Space skips (see _update_talk).
		if (event is InputEventMouseButton and event.pressed) or event.is_action_released("ui_accept"):
			if _talk_hold < 0.35:
				_talk_time = _talk_length
		return
	if state == State.ARRIVING:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_finish_arrival()  # skip the drive
		return
	if state != State.SELECT:
		return
	if event.is_action_pressed("ui_cancel"):
		_set_state(State.MENU)
	elif (event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left")) and get_viewport().gui_get_focus_owner() == null:
		var step := 1 if event.is_action_pressed("ui_right") else -1
		var current := CHARACTER_ORDER.find(hovered if hovered != "" else selected)
		var next: String = CHARACTER_ORDER[wrapi(current + step, 0, CHARACTER_ORDER.size())]
		_set_hovered(next)
		_select(next)
	elif event.is_action_pressed("ui_accept") and selected != "":
		_confirm()


# ------------------------------------------------------------------ Public

## Mark a character as taken by another player (call this from the lobby/network code).
func set_character_taken(id: String, is_taken: bool) -> void:
	if is_taken and not taken.has(id):
		taken.append(id)
	elif not is_taken:
		taken.erase(id)
	if is_taken and selected == id:
		selected = ""
	_refresh_highlights()
	_refresh_info()


# ------------------------------------------------------------------ States

func _set_state(new_state: State) -> void:
	if new_state == State.SELECT:
		state = State.SELECT
		hovered = ""
		_menu.hide()
		# Show the character cards once the camera has moved into the back seat.
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if state == State.SELECT:
				_select_ui.show()
				_set_hovered(""))
		_refresh_info()
	else:
		state = State.MENU
		hovered = ""
		_select_ui.hide()
		_menu.show()
		if _menu.has_method("show_main_buttons"):
			_menu.show_main_buttons()
	_refresh_highlights()


## The title/buttons part of the screen (main_menu.tscn).
func get_menu_ui() -> Control:
	return _menu


## Move into the car to pick a character (main.gd calls this once the game
## is hosted or the join went through).
func enter_select() -> void:
	_on_play_requested()


func _on_play_requested(_a: Variant = null, _b: Variant = null) -> void:
	if state == State.MENU:
		_set_state(State.SELECT)


# ------------------------------------------------------------------ Selection

func _set_hovered(id: String) -> void:
	if state != State.SELECT:
		return
	_unhover_timer = null
	hovered = id
	_refresh_highlights()
	_refresh_info()


## Waits a moment before going back to the back-seat view, so moving the mouse
## between cards doesn't make the camera jump around.
func _unhover(id: String) -> void:
	var timer := get_tree().create_timer(0.35)
	_unhover_timer = timer
	timer.timeout.connect(func() -> void:
		if _unhover_timer == timer and hovered == id:
			_set_hovered(""))


func _select(id: String) -> void:
	if state != State.SELECT or taken.has(id):
		return
	selected = id
	_refresh_highlights()
	_refresh_info()


func _confirm() -> void:
	if selected == "":
		return
	character_confirmed.emit(selected)
	if not embedded:
		var network := get_node_or_null("/root/NetworkManager")
		if network and network.has_method("select_character"):
			network.select_character(selected)
		var game_state := get_node_or_null("/root/GameState")
		if game_state and "chosen_character" in game_state:
			game_state.chosen_character = selected
	_start_talk()


# ------------------------------------------------------------------ The car talk

## After PLAY AS: the team talks while Eli drives, then the drive to the gate.
func _start_talk() -> void:
	state = State.TALK
	hovered = ""
	_select_ui.hide()
	_refresh_highlights()
	_talk_line = -1
	_talk_ui.show()
	_next_talk_line()


func _next_talk_line() -> void:
	_talk_line += 1
	if _talk_line >= TALK.size():
		_talk_ui.hide()
		_start_arrival()
		return
	var who: String = TALK[_talk_line][0]
	var text: String = TALK[_talk_line][1]
	_talk_name.text = CHARACTERS[who]["name"].split(" ")[0]
	_talk_text.text = text
	var show_subtitles: bool = Settings.subtitles if "subtitles" in Settings else true
	_talk_name.visible = show_subtitles
	_talk_text.visible = show_subtitles
	_talk_time = 0.0
	_talk_length = clampf(text.length() / 15.0, 1.6, 7.0)  # reading time


func _update_talk(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		_talk_hold += delta
		if _talk_hold >= 1.0:  # held: skip the rest
			_talk_hold = 0.0
			_talk_line = TALK.size() - 1
			_talk_time = _talk_length
	else:
		_talk_hold = 0.0
	_talk_time += delta
	if _talk_time >= _talk_length:
		_next_talk_line()


# ------------------------------------------------------------------ The rear-view mirror

## A little camera at the mirror (in its own SubViewport) looking at whoever
## you picked; the mirror shows that picture, flipped like a real mirror.
func _build_mirror() -> void:
	var mirror := Node3D.new()
	mirror.position = MIRROR_POS
	_car.add_child(mirror)
	var black := _mat(Color(0.04, 0.04, 0.04))
	_box(mirror, Vector3(0.3, 0.1, 0.03), Vector3.ZERO, black)
	_box(mirror, Vector3(0.02, 0.12, 0.02), Vector3(0, 0.1, 0), black)
	_mirror_view = SubViewport.new()
	_mirror_view.size = Vector2i(384, 128)
	_mirror_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_mirror_view)
	_mirror_cam = Camera3D.new()
	_mirror_cam.fov = 30.0
	_mirror_cam.near = 0.05
	_mirror_view.add_child(_mirror_cam)
	var glass := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.27, 0.08)
	glass.mesh = quad
	glass.position = Vector3(0, 0, 0.017)  # the side facing the people in the car
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _mirror_view.get_texture()
	mat.uv1_scale = Vector3(-1, 1, 1)  # a mirror shows things the other way round
	glass.material_override = mat
	mirror.add_child(glass)


func _update_mirror(delta: float) -> void:
	if _mirror_cam == null:
		return
	# Picking someone shows their face in the mirror for a moment.
	if state == State.SELECT and selected != _last_selected and selected != "":
		_mirror_until = _time + 2.5
	_last_selected = selected
	var who := selected if selected != "" else "eli"
	var from: Vector3 = _car.to_global(MIRROR_POS)
	var face: Vector3 = (_figures[who]["root"] as Node3D).global_position + Vector3.UP * 1.5
	var target := Transform3D().looking_at(face - from)
	target.origin = from
	_mirror_cam.global_transform = _mirror_cam.global_transform.interpolate_with(target, minf(delta * 6.0, 1.0))


# ------------------------------------------------------------------ Arrival

## The car drives up to the Blackwater Weather Station and stops at the gate.
func _start_arrival() -> void:
	state = State.ARRIVING
	hovered = ""
	_arrived = false
	_select_ui.hide()
	_refresh_highlights()
	_station.position.z = STATION_START_Z
	_station.show()
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(_arrival_label, "modulate:a", 1.0, 2.0)


func _update_arrival(delta: float) -> void:
	_station.position.z += _speed * delta
	# Brake smoothly so the gate stops right in front of the car.
	var remaining := STATION_STOP_Z - _station.position.z
	if remaining > 0.05 and _speed > 0.3:
		_speed = maxf(_speed - (_speed * _speed) / (2.0 * remaining) * delta, 0.3)
	else:
		_speed = 0.0
		if not _arrived:
			_arrived = true
			get_tree().create_timer(2.0).timeout.connect(_finish_arrival)
	# Trees past the gate would stand inside the station grounds, so hide them.
	for tree in _trees:
		tree.visible = tree.position.z > _station.position.z + 3.0 or absf(tree.position.x) > 40.0


func _finish_arrival() -> void:
	if state != State.ARRIVING or _fade.visible:
		return
	_fade.show()
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 1.5)
	tween.tween_callback(func() -> void:
		if embedded:
			arrived.emit(selected)
		elif ResourceLoader.exists(LOBBY_SCENE):
			get_tree().change_scene_to_file(LOBBY_SCENE)
		else:
			_arrival_label.get_parent().move_child(_arrival_label, -1)
			_arrival_label.text = "%s HAS ARRIVED.\n(LOBBY SCENE NOT BUILT YET)" % CHARACTERS[selected]["name"])


func _refresh_highlights() -> void:
	for id: String in _figures:
		var data: Dictionary = _figures[id]
		var glow := 0.0
		if state == State.SELECT:
			glow = 0.9 if id == selected else 0.45 if id == hovered else 0.0
		for mat: StandardMaterial3D in data["materials"]:
			mat.emission_enabled = glow > 0.0
			mat.emission = Color(COLOR_HIGHLIGHT, 1.0)
			mat.emission_energy_multiplier = glow * 0.18
			mat.albedo_color.a = 1.0
		var label: Label3D = data["label"]
		label.visible = false  # name cards at the bottom show the names instead
		var label_text: String = CHARACTERS[id]["name"].split(" ")[0]
		if taken.has(id):
			label_text += "  (TAKEN)"
		label.text = label_text
		label.modulate = COLOR_RED if taken.has(id) else COLOR_HIGHLIGHT if (id == hovered or id == selected) else COLOR_TEXT


func _refresh_cards() -> void:
	for id: String in _cards:
		var card: Button = _cards[id]
		var c: Dictionary = CHARACTERS[id]
		var first: String = c["name"].split(" ")[0]
		var role: String = c["role"].split("  //  ")[0]
		card.text = "%s\n%s" % [first, "TAKEN" if taken.has(id) else role]
		card.disabled = taken.has(id)
		var style := card.get_theme_stylebox("normal") as StyleBoxFlat
		style.border_color = COLOR_HIGHLIGHT if id == selected else c["color"].lightened(0.25)
		style.set_border_width_all(3 if id == selected else 0)
		style.border_width_left = 8


func _refresh_info() -> void:
	var id := hovered if hovered != "" else selected
	if id == "":
		_info_name.text = "WHO ARE YOU?"
		_info_role.text = "HOVER OVER SOMEONE IN THE CAR"
		_info_about.text = "Four people. One road in. Each of them has a reason to go into Deepwell, and a skill the others need to survive."
		_info_abilities.text = ""
		_info_quote.text = ""
	else:
		var c: Dictionary = CHARACTERS[id]
		_info_name.text = c["name"]
		_info_role.text = c["role"] + ("   [TAKEN]" if taken.has(id) else "")
		_info_about.text = c["about"]
		var lines := PackedStringArray()
		for ability: String in c["abilities"]:
			lines.append("•  " + ability)
		_info_abilities.text = "\n".join(lines)
		_info_quote.text = c["quote"]

	_refresh_cards()
	if selected != "":
		_confirm_button.disabled = false
		_confirm_button.text = "PLAY AS %s" % CHARACTERS[selected]["name"].split(" ")[0]
	else:
		_confirm_button.disabled = true
		_confirm_button.text = "CLICK A NAME TO CHOOSE"


# ------------------------------------------------------------------ World

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.4)
	env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_density = 0.045
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.85)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-35, 30, 0)
	add_child(moon)


func _mat(color: Color, roughness := 0.9, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _build_road_and_forest() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(120, 260)
	ground.mesh = ground_mesh
	ground.position = Vector3(0, -0.01, -100)
	ground.material_override = _mat(Color(0.03, 0.045, 0.03))
	add_child(ground)

	var road := MeshInstance3D.new()
	var road_mesh := PlaneMesh.new()
	road_mesh.size = Vector2(7.5, 260)
	road.mesh = road_mesh
	road.position = Vector3(0.9, 0.0, -100)
	road.material_override = _mat(Color(0.06, 0.06, 0.065), 0.7)
	add_child(road)

	var paint := _mat(Color(0.75, 0.68, 0.4), 0.6)
	var edge := _mat(Color(0.55, 0.55, 0.52), 0.6)
	for i in int(ROAD_LENGTH / 6.0):
		var dash := _box(self, Vector3(0.12, 0.02, 2.4), Vector3(-0.9 + 1.8, 0.01, 25.0 - i * 6.0), paint)
		_scrollers.append(dash)
	for x in [-2.8, 4.6]:
		_box(self, Vector3(0.1, 0.02, 260.0), Vector3(x, 0.01, -100), edge)

	# Pine trees on both sides of the road.
	var trunk_mat := _mat(Color(0.05, 0.035, 0.025))
	var needle_mat := _mat(Color(0.02, 0.05, 0.03))
	for i in 70:
		var side := -1.0 if i % 2 == 0 else 1.0
		var tree := Node3D.new()
		tree.set_meta("side", side)
		tree.position = Vector3(side * randf_range(5.5, 20.0) + 0.9, 0, 30.0 - randf() * ROAD_LENGTH)
		var height := randf_range(7.0, 13.0)
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.12
		trunk_mesh.bottom_radius = 0.2
		trunk_mesh.height = height
		trunk.mesh = trunk_mesh
		trunk.position.y = height * 0.5
		trunk.material_override = trunk_mat
		tree.add_child(trunk)
		for layer in 3:
			var cone := MeshInstance3D.new()
			var cone_mesh := CylinderMesh.new()
			cone_mesh.top_radius = 0.0
			cone_mesh.bottom_radius = randf_range(1.6, 2.4) - layer * 0.45
			cone_mesh.height = height * 0.45
			cone.mesh = cone_mesh
			cone.position.y = height * (0.35 + layer * 0.22)
			cone.material_override = needle_mat
			tree.add_child(cone)
		add_child(tree)
		_scrollers.append(tree)
		_trees.append(tree)

	# A few old road signs and reflector posts passing by.
	var post_mat := _mat(Color(0.5, 0.5, 0.48), 0.5, Color(0.9, 0.8, 0.5), 0.25)
	for i in 12:
		var post := _box(self, Vector3(0.08, 0.9, 0.08), Vector3(5.1, 0.45, 25.0 - i * 14.0), post_mat)
		_scrollers.append(post)


## The Blackwater Weather Station: fence and gate on the road, the 1960s
## building behind it (left wing, taller center entrance block with a mural
## over glass doors, right wing with a weather tower on the roof).
## Simple shapes for now; replace with a real model later.
func _build_station() -> void:
	_station = Node3D.new()
	_station.position = Vector3(0.9, 0.0, STATION_START_Z)
	_station.hide()
	add_child(_station)

	var concrete := _mat(Color(0.5, 0.5, 0.47), 0.95)
	var dark_glass := _mat(Color(0.03, 0.035, 0.04), 0.2)
	var lit_glass := _mat(Color(0.3, 0.25, 0.15), 0.3, Color(1.0, 0.75, 0.4), 0.6)
	var metal := _mat(Color(0.3, 0.3, 0.3), 0.5)
	var fence_mesh := _mat(Color(0.45, 0.45, 0.45, 0.25), 0.6)

	# Fence along the gate line, with a rolling gate across the road.
	for i in 21:
		var px: float = -40.0 + i * 4.0
		if absf(px) < 3.9:
			continue
		_box(_station, Vector3(0.08, 2.4, 0.08), Vector3(px, 1.2, 0), metal)
	for side in [-1.0, 1.0]:
		_box(_station, Vector3(36.0, 2.2, 0.02), Vector3(side * 22.0, 1.1, 0), fence_mesh)
		_box(_station, Vector3(36.0, 0.05, 0.05), Vector3(side * 22.0, 2.4, 0), metal)
		_box(_station, Vector3(0.16, 2.8, 0.16), Vector3(side * 4.0, 1.4, 0), metal)
	_box(_station, Vector3(7.8, 2.2, 0.03), Vector3(0, 1.15, 0), fence_mesh)
	_box(_station, Vector3(7.8, 0.06, 0.06), Vector3(0, 2.25, 0), metal)
	_box(_station, Vector3(7.8, 0.06, 0.06), Vector3(0, 0.1, 0), metal)

	# Warning sign on the gate.
	_box(_station, Vector3(1.6, 0.9, 0.03), Vector3(1.6, 1.4, 0.05), _mat(Color(0.75, 0.72, 0.62)))
	var sign_text := Label3D.new()
	sign_text.text = "U.S. GOVERNMENT PROPERTY\nBLACKWATER WEATHER STATION\nNO TRESPASSING"
	sign_text.position = Vector3(1.6, 1.4, 0.08)
	sign_text.font_size = 22
	sign_text.pixel_size = 0.0035
	sign_text.modulate = Color(0.12, 0.08, 0.06)
	sign_text.outline_size = 0
	_station.add_child(sign_text)

	# The building, 25-30 m behind the gate.
	_box(_station, Vector3(22.0, 7.0, 12.0), Vector3(-19.5, 3.5, -30.0), concrete)   # left wing
	_box(_station, Vector3(17.0, 10.5, 14.0), Vector3(0.0, 5.25, -29.0), concrete)   # center block
	_box(_station, Vector3(26.0, 8.0, 12.0), Vector3(21.5, 4.0, -30.0), concrete)    # right wing
	var front_wing := -24.0 + 0.06
	var front_center := -22.0 + 0.06
	# Left wing windows: two rows.
	for row in [2.0, 4.8]:
		for wx in [-28.0, -23.5, -19.0, -14.5, -10.5]:
			var lit: bool = row == 4.8 and wx == -19.0
			_box(_station, Vector3(2.6, 1.3, 0.1), Vector3(wx, row, front_wing), lit_glass if lit else dark_glass)
	# Right wing: big grid windows.
	for row in [2.2, 5.6]:
		for wx in [12.0, 19.0, 26.0, 32.0]:
			_box(_station, Vector3(5.0, 1.9, 0.1), Vector3(wx, row, front_wing), dark_glass)
	# Center block: small windows beside the mural, mural, canopy, glass doors.
	for wx in [-6.5, -4.0, 4.0, 6.5]:
		for row in [3.4, 5.6, 7.8]:
			_box(_station, Vector3(0.8, 1.0, 0.1), Vector3(wx, row, front_center), dark_glass)
	_box(_station, Vector3(4.4, 3.6, 0.1), Vector3(0.0, 7.6, front_center), _mat(Color(0.18, 0.16, 0.14)))  # mural
	_box(_station, Vector3(6.0, 0.25, 1.6), Vector3(0.0, 3.2, front_center + 0.8), concrete)               # canopy
	_box(_station, Vector3(3.8, 3.0, 0.1), Vector3(0.0, 1.5, front_center), _mat(Color(0.05, 0.06, 0.06), 0.2, Color(0.4, 0.9, 0.7), 0.15))
	# Weather tower and antenna on the right wing roof.
	_box(_station, Vector3(0.25, 9.0, 0.25), Vector3(26.0, 12.5, -31.0), metal)
	_box(_station, Vector3(2.4, 0.1, 0.1), Vector3(26.0, 16.2, -31.0), metal)
	_box(_station, Vector3(0.1, 0.1, 2.0), Vector3(26.0, 15.0, -31.0), metal)

	# Lights: a floodlight over the doors and a lamp at the gate.
	var flood := OmniLight3D.new()
	flood.position = Vector3(0.0, 4.0, -19.5)
	flood.light_color = Color(1.0, 0.85, 0.6)
	flood.light_energy = 2.0
	flood.omni_range = 14.0
	_station.add_child(flood)
	_box(_station, Vector3(0.12, 4.5, 0.12), Vector3(-5.0, 2.25, 0.4), metal)
	var gate_lamp := OmniLight3D.new()
	gate_lamp.position = Vector3(-5.0, 4.6, 0.6)
	gate_lamp.light_color = Color(0.85, 0.9, 1.0)
	gate_lamp.light_energy = 1.4
	gate_lamp.omni_range = 9.0
	_station.add_child(gate_lamp)


func _build_car() -> void:
	_car = Node3D.new()
	add_child(_car)

	var paint := _mat(Color(0.34, 0.1, 0.08), 0.4)
	var trim := _mat(Color(0.06, 0.06, 0.06), 0.6)
	var chrome := _mat(Color(0.5, 0.5, 0.5), 0.25)
	var glass := _mat(Color(0.35, 0.42, 0.5, 0.2), 0.05)
	var seat := _mat(Color(0.12, 0.09, 0.07))
	var dash := _mat(Color(0.05, 0.05, 0.05), 0.8, Color(0.3, 0.9, 0.6), 0.06)

	# Body: lower shell (sides, hood, trunk) leaves the cabin open on top.
	_box(_car, Vector3(2.0, 0.45, 4.8), Vector3(0, 0.55, 0.2), paint)       # floor/lower body
	_box(_car, Vector3(1.84, 0.02, 2.6), Vector3(0, 0.79, 0.4), _mat(Color(0.05, 0.045, 0.04)))  # cabin floor
	_box(_car, Vector3(2.0, 0.35, 1.5), Vector3(0, 0.95, -1.55), paint)     # hood
	_box(_car, Vector3(2.0, 0.35, 1.0), Vector3(0, 0.95, 2.1), paint)       # trunk
	_box(_car, Vector3(0.08, 0.38, 2.4), Vector3(-0.96, 0.95, 0.4), paint)  # door left
	_box(_car, Vector3(0.08, 0.38, 2.4), Vector3(0.96, 0.95, 0.4), paint)   # door right
	_box(_car, Vector3(2.04, 0.1, 4.9), Vector3(0, 0.3, 0.2), chrome)       # bumper line
	_roof = _box(_car, Vector3(1.86, 0.06, 2.1), Vector3(0, 1.84, 0.5), paint)  # roof
	_box(_car, Vector3(1.8, 0.02, 2.04), Vector3(0, 1.8, 0.5), _mat(Color(0.13, 0.12, 0.11)))  # ceiling lining

	# Pillars.
	for x in [-0.93, 0.93]:
		var a := _box(_car, Vector3(0.07, 0.78, 0.07), Vector3(x, 1.47, -0.75), trim)
		a.rotation_degrees.x = 28.0
		_box(_car, Vector3(0.07, 0.72, 0.07), Vector3(x, 1.48, 0.55), trim)
		var c := _box(_car, Vector3(0.07, 0.78, 0.07), Vector3(x, 1.47, 1.6), trim)
		c.rotation_degrees.x = -25.0

	# Glass: windshield (leaning back), rear window, side windows.
	var windshield := _box(_car, Vector3(1.8, 0.8, 0.02), Vector3(0, 1.47, -0.75), glass)
	windshield.rotation_degrees.x = 28.0
	var rear := _box(_car, Vector3(1.8, 0.78, 0.02), Vector3(0, 1.47, 1.63), glass)
	rear.rotation_degrees.x = -25.0
	for x in [-0.95, 0.95]:
		_box(_car, Vector3(0.02, 0.66, 2.2), Vector3(x, 1.47, 0.45), glass)

	# Dashboard with a faint green glow, steering wheel, and seats.
	_box(_car, Vector3(1.8, 0.22, 0.4), Vector3(0, 1.08, -0.82), dash)
	var wheel := MeshInstance3D.new()
	var wheel_mesh := TorusMesh.new()
	wheel_mesh.inner_radius = 0.15
	wheel_mesh.outer_radius = 0.18
	wheel.mesh = wheel_mesh
	wheel.position = Vector3(-0.38, 1.18, -0.55)
	wheel.rotation_degrees = Vector3(65, 0, 0)
	wheel.material_override = trim
	_car.add_child(wheel)
	for pos in [Vector3(-0.38, 0.85, 0.15), Vector3(0.38, 0.85, 0.15)]:
		_box(_car, Vector3(0.55, 0.12, 0.55), pos, seat)
		_box(_car, Vector3(0.55, 0.5, 0.12), pos + Vector3(0, 0.3, 0.3), seat)
	_box(_car, Vector3(1.8, 0.12, 0.6), Vector3(0, 0.9, 1.05), seat)
	_box(_car, Vector3(1.8, 0.65, 0.12), Vector3(0, 1.25, 1.38), seat)

	# Wheels.
	var tire := _mat(Color(0.02, 0.02, 0.02))
	for pos in [Vector3(-0.95, 0.38, -1.4), Vector3(0.95, 0.38, -1.4), Vector3(-0.95, 0.38, 1.7), Vector3(0.95, 0.38, 1.7)]:
		var w := MeshInstance3D.new()
		var w_mesh := CylinderMesh.new()
		w_mesh.top_radius = 0.38
		w_mesh.bottom_radius = 0.38
		w_mesh.height = 0.25
		w.mesh = w_mesh
		w.position = pos
		w.rotation_degrees.z = 90.0
		w.material_override = tire
		_car.add_child(w)

	# Headlights, taillights, and a dim dome light inside.
	var head_mat := _mat(Color(1, 1, 0.9), 0.2, Color(1, 0.95, 0.8), 3.0)
	var tail_mat := _mat(Color(0.5, 0.02, 0.02), 0.3, Color(1, 0.05, 0.03), 2.0)
	for x in [-0.7, 0.7]:
		_box(_car, Vector3(0.32, 0.14, 0.04), Vector3(x, 0.9, -2.31), head_mat)
		_box(_car, Vector3(0.3, 0.1, 0.04), Vector3(x, 0.92, 2.61), tail_mat)
		var beam := SpotLight3D.new()
		beam.position = Vector3(x, 0.9, -2.4)
		beam.rotation_degrees.x = -4.0
		beam.light_color = Color(1, 0.94, 0.8)
		beam.light_energy = 4.0
		beam.spot_range = 45.0
		beam.spot_angle = 28.0
		_car.add_child(beam)
	var dome := OmniLight3D.new()
	dome.position = Vector3(0, 1.45, 0.35)
	dome.light_color = Color(1.0, 0.9, 0.78)
	dome.light_energy = 0.55
	dome.omni_range = 2.4
	_car.add_child(dome)
	var dash_light := OmniLight3D.new()
	dash_light.position = Vector3(0, 1.25, -0.6)
	dash_light.light_color = Color(0.4, 1.0, 0.7)
	dash_light.light_energy = 0.15
	dash_light.omni_range = 1.6
	_car.add_child(dash_light)


func _build_character(id: String) -> void:
	var c: Dictionary = CHARACTERS[id]
	var root := Node3D.new()
	root.position = c["seat"]
	var holder := Node3D.new()  # bobbing happens on root, seat offset on holder
	root.add_child(holder)
	_car.add_child(root)
	var materials: Array = []

	var model_path := MODEL_PATH % MODEL_FILES[id][0]
	var rig: HumanRig = null
	if ResourceLoader.exists(model_path):
		var model: Node3D = load(model_path).instantiate()
		model.set_script(HumanRig)  # the game's posing: sitting, arms down
		rig = model as HumanRig
		holder.add_child(model)
		if rig._sk == null:
			rig._ready()  # find the skeleton (the script was added after loading)
		if rig._sk == null:
			model.queue_free()  # no skeleton: a T-pose statue can't sit in the car
			rig = null
		else:
			var height: float = MODEL_FILES[id][1]
			model.scale = Vector3.ONE * height / RIGGED_MODEL_HEIGHT
			model.rotation.y = PI  # the models face +Z; people in the car face -Z
	if rig == null:
		var s: float = c["size"]
		var body_mat := _mat(c["color"], 0.85)
		var skin_mat := _mat(Color(0.62, 0.48, 0.38), 0.7)
		var leg_mat := _mat(Color(0.08, 0.09, 0.12), 0.9)
		materials = [body_mat, skin_mat, leg_mat]

		var torso := MeshInstance3D.new()
		var torso_mesh := CapsuleMesh.new()
		torso_mesh.radius = 0.2 * s
		torso_mesh.height = 0.68 * s
		torso.mesh = torso_mesh
		torso.position = Vector3(0, 1.12, 0.12)
		torso.rotation_degrees.x = 8.0
		torso.material_override = body_mat
		holder.add_child(torso)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.12 * s
		head_mesh.height = 0.26 * s
		head.mesh = head_mesh
		head.position = Vector3(0, 1.12 + 0.44 * s, 0.1)
		head.material_override = skin_mat
		holder.add_child(head)

		for side in [-1.0, 1.0]:
			var thigh := MeshInstance3D.new()
			var thigh_mesh := CapsuleMesh.new()
			thigh_mesh.radius = 0.08 * s
			thigh_mesh.height = 0.5
			thigh.mesh = thigh_mesh
			thigh.position = Vector3(side * 0.1, 0.98, -0.12)
			thigh.rotation_degrees.x = 90.0
			thigh.material_override = leg_mat
			holder.add_child(thigh)

			var arm := MeshInstance3D.new()
			var arm_mesh := CapsuleMesh.new()
			arm_mesh.radius = 0.06 * s
			arm_mesh.height = 0.5 * s
			arm.mesh = arm_mesh
			arm.position = Vector3(side * 0.22 * s, 1.12, -0.05)
			arm.rotation_degrees.x = 55.0 if id == "eli" else 25.0
			arm.material_override = body_mat
			holder.add_child(arm)

	# Clickable area around the whole figure.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.0
	shape.shape = capsule
	shape.position = Vector3(0, 1.2, 0.05)
	body.add_child(shape)
	root.add_child(body)
	body.mouse_entered.connect(func() -> void:
		if hovered == "":
			_set_hovered(id))
	body.input_event.connect(func(_cam: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select(id))

	var label := Label3D.new()
	label.text = c["name"].split(" ")[0]
	label.position = Vector3(0, 1.9, 0.25)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.0022
	label.font_size = 40
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.85)
	var label_font := SystemFont.new()
	label_font.font_names = PackedStringArray(["Courier Prime", "Courier New", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	label_font.font_weight = 700
	label.font = label_font
	label.visible = false
	root.add_child(label)

	_figures[id] = {"root": root, "materials": materials, "label": label, "rig": rig}


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 55.0
	add_child(_camera)
	_camera.look_at_from_position(MENU_CAM_POS, MENU_CAM_TARGET)
	_camera.make_current()


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Dark gradient on the left so the menu text is easy to read.
	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.85))
	gradient.set_color(1, Color(0, 0, 0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_to = Vector2(0.6, 0.0)
	shade.texture = tex
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)

	_menu = MENU_UI.instantiate()
	_menu.show_background = false
	_menu.auto_go_to_lobby = false
	_menu.embedded = embedded
	layer.add_child(_menu)
	if not embedded:  # in the game, main.gd calls enter_select() when ready
		_menu.host_requested.connect(_on_play_requested)
		_menu.join_requested.connect(_on_play_requested)

	_build_select_ui(layer)

	_arrival_label = Label.new()
	_arrival_label.text = "BLACKWATER WEATHER STATION\nOCTOBER 14, 2015   03:52 AM"
	_arrival_label.theme = _menu.theme
	_arrival_label.add_theme_font_size_override("font_size", 22)
	_arrival_label.add_theme_color_override("font_color", COLOR_TEXT)
	_arrival_label.position = Vector2(88, 72)
	_arrival_label.modulate.a = 0.0
	layer.add_child(_arrival_label)

	# The car talk: black bars, who is talking, and the subtitle.
	_talk_ui = Control.new()
	_talk_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_talk_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_talk_ui.hide()
	layer.add_child(_talk_ui)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.88
		bar.anchor_bottom = 0.1 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_talk_ui.add_child(bar)
	_talk_name = Label.new()
	_talk_name.anchor_left = 0.15
	_talk_name.anchor_right = 0.85
	_talk_name.anchor_top = 0.74
	_talk_name.anchor_bottom = 0.78
	_talk_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_name.add_theme_font_size_override("font_size", 18)
	_talk_name.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	_talk_ui.add_child(_talk_name)
	_talk_text = Label.new()
	_talk_text.anchor_left = 0.12
	_talk_text.anchor_right = 0.88
	_talk_text.anchor_top = 0.78
	_talk_text.anchor_bottom = 0.87
	_talk_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_talk_text.add_theme_font_size_override("font_size", 24)
	_talk_text.add_theme_color_override("font_color", COLOR_TEXT)
	_talk_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_talk_text.add_theme_constant_override("outline_size", 8)
	_talk_ui.add_child(_talk_text)
	var hint := Label.new()
	hint.text = "[SPACE] next     hold [SPACE] skip"
	hint.anchor_left = 0.6
	hint.anchor_right = 0.98
	hint.anchor_top = 0.94
	hint.anchor_bottom = 0.99
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", COLOR_DIM)
	_talk_ui.add_child(hint)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.hide()
	layer.add_child(_fade)


func _build_select_ui(layer: CanvasLayer) -> void:
	_select_ui = Control.new()
	_select_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_select_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_ui.theme = _menu.theme
	_select_ui.hide()
	layer.add_child(_select_ui)

	var header := Label.new()
	header.text = "CHOOSE YOUR CHARACTER"
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", COLOR_TEXT)
	header.position = Vector2(88, 64)
	_select_ui.add_child(header)

	_hint = Label.new()
	_hint.text = "HOVER OVER A NAME TO MEET THEM.  CLICK TO CHOOSE.  ARROW KEYS + ENTER ALSO WORK."
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", COLOR_DIM)
	_hint.position = Vector2(90, 112)
	_select_ui.add_child(_hint)

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -560
	panel.offset_right = -56
	panel.offset_top = -250
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_ui.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 36)
	_info_name.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(_info_name)

	_info_role = Label.new()
	_info_role.add_theme_font_size_override("font_size", 16)
	_info_role.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	vbox.add_child(_info_role)

	for label_name in ["_info_about", "_info_abilities", "_info_quote"]:
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 440
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", COLOR_DIM if label_name == "_info_quote" else COLOR_TEXT)
		vbox.add_child(l)
		set(label_name, l)

	# Big name cards along the bottom: the easy way to pick.
	var cards := HBoxContainer.new()
	cards.anchor_left = 0.5
	cards.anchor_right = 0.5
	cards.anchor_top = 1.0
	cards.anchor_bottom = 1.0
	cards.offset_top = -250
	cards.offset_bottom = -150
	cards.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cards.add_theme_constant_override("separation", 18)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_select_ui.add_child(cards)
	for id: String in CHARACTER_ORDER:
		var card := Button.new()
		card.custom_minimum_size = Vector2(250, 96)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 22)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.03, 0.035, 0.035, 0.88)
		normal.content_margin_left = 22
		normal.content_margin_right = 14
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.12, 0.11, 0.08, 0.95)
		hover.border_color = COLOR_HIGHLIGHT
		hover.set_border_width_all(2)
		hover.border_width_left = 8
		card.add_theme_stylebox_override("normal", normal)
		card.add_theme_stylebox_override("hover", hover)
		card.add_theme_stylebox_override("focus", hover)
		card.add_theme_stylebox_override("pressed", hover)
		card.add_theme_stylebox_override("disabled", normal.duplicate())
		card.add_theme_color_override("font_disabled_color", COLOR_RED)
		card.mouse_entered.connect(func() -> void:
			card.grab_focus()
			_set_hovered(id))
		card.mouse_exited.connect(_unhover.bind(id))
		card.focus_entered.connect(_set_hovered.bind(id))
		card.pressed.connect(_select.bind(id))
		cards.add_child(card)
		_cards[id] = card

	var bottom := HBoxContainer.new()
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 88
	bottom.offset_top = -110
	bottom.add_theme_constant_override("separation", 48)
	_select_ui.add_child(bottom)

	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(_set_state.bind(State.MENU))
	bottom.add_child(back)

	_confirm_button = Button.new()
	_confirm_button.pressed.connect(_confirm)
	bottom.add_child(_confirm_button)
	_refresh_cards()
