extends Node3D
## Deepwell's opening: the home screen, two cutscenes and character select.
##
## MENU:     Eli's family's old maroon sedan drives down a foggy forest road at
##           night. Only Eli (driving) and Cole are in it, with a duffel bag in
##           the back. The camera drifts slowly around the outside. The title
##           and buttons (main_menu.tscn) are on the left.
## TALK:     Cutscene 1, "The Road": Eli and Cole talk in the car (rain, wipers,
##           Mateo's dog tag swinging from the mirror). A sign for PINE HOLLOW
##           GAS comes up and Eli turns off the road.
## MEETING:  Cutscene 2, "The Meeting": the car pulls into a closed gas station
##           where Nora and Walter are waiting. Eli and Cole get out, they talk,
##           and Cole sends everyone to the trunk.
## SELECT:   Character select from INSIDE the trunk: the four stand behind the
##           car looking down into it (Walter, Nora, Eli, Cole from the left).
##           Hover someone (or their card) to see who they are, pick them and
##           they grab their gear, then Ready. The host presses Start.
## ARRIVING: only for CONTINUE (a saved game): a short fade before it loads.
##
## The lines are in res://data/opening_dialogue.json: edit them there. Voice
## clips: put assets/audio/voice/<id>.ogg (or .wav / .mp3), e.g. road_01.ogg,
## and it plays with that line (the line stays up as long as the clip).
##
## Online, the host runs the cutscenes: its screen says which step is playing
## (step_started) and main.gd sends that to everyone, so every screen shows
## the same shot at the same time. Hold Space (A on a controller) to vote to
## skip a cutscene: it skips when everyone has voted, or when the host holds.
##
## The team's real models (MODEL_FILES) are used when they're there. They have
## no skeleton yet (T-pose statues), so PoseShader poses them; a model with a
## skeleton is posed by HumanRig instead. Anything without a model is a simple
## stand-in shape, easy to swap later.

signal character_confirmed(character_id: String)
signal voice_line_requested(line_id: String)
## Only when `embedded`: CONTINUE's short drive finished and the screen is black.
signal arrived(character_id: String)
## The host's cutscene moved to step `index` (main.gd sends it to everyone).
signal step_started(index: int)
## This player held the skip button long enough to vote to skip.
signal skip_vote(voting: bool)
## Character select: pick a character ("" = put mine back), Ready, Start.
signal pick_requested(character_id: String)
signal ready_toggled(is_ready: bool)
signal start_requested

## True when this home screen runs inside the game's main scene
## (scenes/main.tscn). Then main.gd does the networking: Host/Join only send
## signals, main.gd calls enter_opening() when the host presses Play, and it
## tells us who picked whom (set_team) and which cutscene step to show.
var embedded := false
## True on a client: the cutscene doesn't move on by itself, it follows the
## host's steps (net_step).
var follow := false

const MENU_UI := preload("res://scenes/main_menu/deepwell/main_menu.tscn")
const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"
const MODEL_PATH := "res://assets/models/characters/%s.glb"
const SCRIPT_PATH := "res://data/opening_dialogue.json"
const VOICE_PATH := "res://assets/audio/voice/%s.%s"
## The team's real models (file names kept as they are) and how tall each
## person is, same as scripts/player/character_model.gd.
const MODEL_FILES := {"eli": ["eli", 1.78], "cole": ["frank", 1.9], "nora": ["journalist", 1.68], "walter": ["engineer", 1.75]}
const RIGGED_MODEL_HEIGHT := 0.98

const COLOR_TEXT := Color("d9d3c1")
const COLOR_DIM := Color("7b786c")
const COLOR_HIGHLIGHT := Color("e8b04a")
const COLOR_RED := Color("c0392b")

const DRIVE_SPEED := 17.0  # meters per second
const STATION_START_Z := -75.0  # (the weather station isn't on this road any more)
const ROAD_LENGTH := 160.0
const TRUNK_OPEN_ANGLE := -38.0  # the back edge swings up (and frames the top of the trunk view)
const SKIP_HOLD_TIME := 1.2
## Where the gas station starts when the car pulls in (it slides up to the car).
const GAS_STATION_START_Z := -40.0
## The meeting: Eli and Cole by their doors, Nora by her car, Walter by his pickup.
const MEET_POSITIONS := {
	"eli": Vector3(-1.55, 0.0, 0.5),
	"cole": Vector3(1.55, 0.0, 0.5),
	"nora": Vector3(-4.2, 0.0, -0.4),
	"walter": Vector3(4.15, 0.0, -0.2),
}
## Standing behind the car, looking down into the trunk. Seen from inside the
## trunk, left to right: Walter, Nora, Eli, Cole.
const TRUNK_POSITIONS := {
	"walter": Vector3(1.38, 0.0, 3.95),
	"nora": Vector3(0.47, 0.0, 3.8),
	"eli": Vector3(-0.47, 0.0, 3.8),
	"cole": Vector3(-1.38, 0.0, 3.95),
}
## How far someone steps toward the trunk when you hover them.
const HOVER_STEP := 0.28

## Order is the order the arrow keys / left and right cycle through
## (the same order you see them from inside the trunk).
const CHARACTER_ORDER := ["walter", "nora", "eli", "cole"]
const CHARACTERS := {
	"eli": {
		"talk_cam": Vector3(0.3, 1.52, -0.66),
		"talk_look": Vector3(-0.38, 1.4, -0.05),
		"name": "ELI REYES",
		"role": "THE SON  //  SURVIVOR",
		"seat": Vector3(-0.38, 0.0, -0.1),
		"color": Color(0.38, 0.23, 0.12),
		"size": 1.0,
		"about": "21. College student and Army Reserve soldier. His older twin brother Mateo walked into Blackwater two weeks ago and never came out. Eli is going in after him.",
		"abilities": [
			"SENSE: hold to see nearby monsters through walls for 3 seconds (20s cooldown).",
			"MILITARY TRAINING: steadier aim and faster reloads. Reads Morse code and military maps.",
			"MENTOR BOND: works better when Cole is close by.",
		],
		"quote": "\"He's my big brother. He'd come for me.\"",
		"items": "Flashlight and Mateo's dog tag",
	},
	"cole": {
		"talk_cam": Vector3(-0.3, 1.52, -0.66),
		"talk_look": Vector3(0.38, 1.42, -0.05),
		"name": "COLE BRENNAN",
		"role": "THE GUARD  //  PROTECTOR",
		"seat": Vector3(0.38, -0.1, -0.1),
		"color": Color(0.29, 0.32, 0.19),
		"size": 1.12,
		"about": "36. Former soldier. Raised Eli like his own son. Knows this place better than he admits.",
		"abilities": [
			"STRENGTH: hold doors shut, move heavy objects, build barricades, carry downed teammates.",
			"FIELD TRAINING: longer stuns, and can study a monster to show the team its weak point.",
			"Best with firearms, but slower and louder than everyone else.",
		],
		"quote": "\"Eyes up, kid. Stay behind me.\"",
		"items": "Heavy flashlight",
	},
	"nora": {
		"name": "NORA VANCE",
		"role": "THE JOURNALIST  //  STUNNER",
		"seat": Vector3(-0.7, 0.0, 3.75),
		"color": Color(0.7, 0.58, 0.4),
		"size": 0.95,
		"about": "35. Investigative journalist. She's been chasing Blackwater for three years. Her source vanished trying to expose it. She wants the proof.",
		"abilities": [
			"CAMERA FLASH: stuns a monster in front of her for 2 seconds (15s cooldown).",
			"EVIDENCE: photograph clues to unlock story files for the whole team.",
		],
		"quote": "\"If it's real, I'm getting it on film.\"",
		"items": "Camera",
	},
	"walter": {
		"name": "WALTER KESSLER",
		"role": "THE ENGINEER  //  FIXER",
		"seat": Vector3(0.7, 0.0, 3.75),
		"color": Color(0.13, 0.17, 0.32),
		"size": 0.97,
		"about": "60. Worked maintenance at Blackwater before it was sealed. Knows the tunnels. Nervous, quiet, and hiding something.",
		"abilities": [
			"REPAIR: the only one who can fix generators, elevators and panels.",
			"HACK: opens locked security doors, but it takes time, so someone has to guard him.",
		],
		"quote": "\"I can fix it. Just keep them away from me.\"",
		"items": "Toolbox and wrench",
	},
}

enum State { MENU, SELECT, TALK, MEETING, ARRIVING }

## Used only if data/opening_dialogue.json is missing.
const FALLBACK_SCRIPT := {
	"road": [
		{"id": "road_01", "speaker": "eli", "text": "You ever hear of a place called Blackwater?", "shot": "over_cole"},
		{"id": "road_14", "speaker": "cole", "text": "Take the next left.", "shot": "cole"},
	],
	"meeting": [
		{"id": "meet_01", "speaker": "nora", "text": "You're late."},
		{"id": "meet_08", "speaker": "cole", "text": "Gear's in the trunk. Grab what you need.", "action": "cole_to_trunk"},
	],
}

## Camera shots inside the car (car space: the car faces -Z, Eli drives on the
## left at x -0.38, Cole is at +0.38). [position, look at, field of view]
const ROAD_SHOTS := {
	"over_cole": [Vector3(0.66, 1.72, 0.16), Vector3(-0.38, 1.62, -0.28), 50.0],
	"eli": [Vector3(0.16, 1.4, -0.62), Vector3(-0.38, 1.62, -0.1), 48.0],
	"cole": [Vector3(-0.18, 1.4, -0.62), Vector3(0.38, 1.6, -0.1), 48.0],
	"hands": [Vector3(0.0, 1.56, -0.1), Vector3(-0.34, 1.3, -0.6), 46.0],
	"windshield": [Vector3(0.0, 1.62, 0.65), Vector3(0.0, 1.35, -14.0), 62.0],
	"cole_window": [Vector3(-0.04, 1.44, -0.5), Vector3(0.44, 1.62, -0.06), 50.0],
}
const MIRROR_POS := Vector3(0.0, 1.62, -0.6)

## The real car (Nasir's Volvo S90 or Audi RS Q8): put the model in
## assets/models/cars/ named volvo_s90, audi_rs_q8 or car (.glb, .gltf or .fbx)
## and the car scenes use it instead of the box car. Until then the box car is
## the placeholder. If it sits wrong, change these:
const CAR_MODEL_NAMES := ["car", "volvo_s90", "audi_rs_q8"]
const CAR_MODEL_TYPES := ["glb", "gltf", "fbx", "blend"]
const CAR_MODEL_TURN := 180.0  # degrees: set it to 0.0 if the car faces backwards
const CAR_MODEL_LENGTH := 5.0  # meters long (a real S90 is 4.96, an RS Q8 5.01)
const CAR_MODEL_OFFSET := Vector3(0.0, 0.0, 0.2)  # move it (meters): x right, y up, z back

var state := State.MENU
var hovered := ""
var selected := ""  # the character I picked ("" = none yet)
var taken: Array[String] = []  # picked by somebody else

var _time := 0.0
var _car: Node3D  # holds both cars, the people and the mirror (it bobs on the road)
var _placeholder_car: Node3D
var _hero_car: Node3D
var _roof: Node3D
var _trunk_lid: Node3D
var _trunk_lid_placeholder: Node3D
var _camera: Camera3D
var _scrollers: Array[Node3D] = []
var _figures := {}      # id -> {"root": Node3D, "materials": Array, "label": Label3D, ...}
var _menu: Control
var _select_ui: Control
var _info_name: Label
var _info_role: Label
var _info_about: Label
var _info_abilities: Label
var _info_quote: Label
var _info_items: Label
var _ready_button: Button
var _start_button: Button
var _select_status: Label
var _hint: Label
var _cards := {}  # id -> Button
var _unhover_timer: SceneTreeTimer
var _speed := DRIVE_SPEED
var _station: Node3D
var _gas_station: Node3D
var _station_lamp: OmniLight3D
var _trees: Array[Node3D] = []
var _fade: ColorRect
var _arrival_label: Label
var _arrived := false

var _talk_ui: Control
var _talk_name: Label
var _talk_text: Label
var _skip_label: Label
var _joining_ui: Control
var _voice: AudioStreamPlayer

var _mirror_cam: Camera3D
var _mirror_view: SubViewport
var _mirror_until := 0.0
var _last_selected := ""

## The cutscenes, one step at a time: beats (the car pulls in...) and lines.
var _steps: Array = []
var _step := -1
var _step_time := 0.0
var _step_length := 0.0
var _line_shown := false
var _skip_hold := 0.0
var _skip_voted := false
var _skip_votes := 0
var _skip_total := 1
var _tap_ready := true
## Cut straight to the next shot (cutscenes cut; only the menu and hovering glide).
var _snap_camera := false
var _road_fill: OmniLight3D
var _current_shot_name := ""
var _using_pad := false
var _joining := false

## Who picked whom: character id -> {"player": 2, "mine": false, "ready": true}.
var _team := {}
var _can_start := false
var _is_host := true
var _local_ready := false  # (when not embedded: running this scene by itself)

## The little things that make the car feel alive.
var _wipers: Array[Node3D] = []
var _dog_tag: Node3D
var _rain: GPUParticles3D
var _hands: Node3D
var _duffel: Node3D
var _sign: Node3D
var _hover_light: SpotLight3D
## Gear in the trunk: character id -> Array of {"node": Node3D, "home": Vector3, "rot": Vector3}.
var _gear := {}
var _gear_taken := {}  # character id -> true while they hold it

const MENU_CAM_TARGET := Vector3(0.0, 1.05, 0.2)
const ARRIVE_CAM_POS := Vector3(0.0, 0.98, 1.7)
const ARRIVE_CAM_TARGET := Vector3(0.0, 1.58, 3.45)
## Inside the open trunk, lying on the floor and looking up and out.
const SELECT_CAM_POS := Vector3(0.0, 0.86, 1.85)
const SELECT_CAM_TARGET := Vector3(0.0, 1.86, 3.85)


func _ready() -> void:
	get_viewport().physics_object_picking = true
	randomize()
	_build_environment()
	_build_road_and_forest()
	_build_station()
	_build_gas_station()
	_build_gas_station_extras()
	_build_cars()
	_build_car_details()
	for id: String in CHARACTER_ORDER:
		_build_character(id)
	_build_trunk_gear()
	_build_mirror()
	_build_camera()
	_build_ui()
	_build_steps()
	_set_state(State.MENU)


func _input(event: InputEvent) -> void:
	# Which prompt to show: a controller button or the Space key.
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_using_pad = false


func _process(delta: float) -> void:
	_time += delta

	if _speed > 0.01:
		for node in _scrollers:
			node.position.z += _speed * delta
			if node.position.z > 30.0:
				node.position.z -= ROAD_LENGTH
				if node.has_meta("side"):
					node.position.x = float(node.get_meta("side")) * randf_range(5.5, 20.0)
	if _sign and _sign.visible:
		_sign.position.z += _speed * delta

	var driving := _speed > 0.5
	var shake := 1.0 if driving else 0.12
	_car.position.y = (sin(_time * 9.0) * 0.008 + sin(_time * 2.3) * 0.012) * shake
	_car.rotation.z = sin(_time * 1.7) * 0.006 * shake
	_car.rotation.x = sin(_time * 3.1) * 0.003 * shake

	# Wipers sweep while it rains on the road; the dog tag swings.
	var wiping := state == State.MENU or state == State.TALK
	for wiper in _wipers:
		var target := (sin(_time * 2.6) * 0.5 + 0.5) * 95.0 if wiping else 0.0
		wiper.rotation_degrees.z = lerpf(wiper.rotation_degrees.z, target * float(wiper.get_meta("dir")), minf(delta * 12.0, 1.0))
	if _dog_tag:
		_dog_tag.rotation_degrees.x = sin(_time * 1.9) * 10.0 * shake + sin(_time * 7.0) * 2.0 * shake
		_dog_tag.rotation_degrees.z = sin(_time * 1.3 + 1.0) * 7.0 * shake
	if _rain:
		_rain.emitting = state == State.MENU or state == State.TALK or state == State.MEETING
	if _hands:
		_hands.visible = state == State.MENU or state == State.TALK
	if _road_fill:
		_road_fill.visible = state == State.MENU or state == State.TALK

	_animate_figures()

	if state == State.TALK or state == State.MEETING:
		_update_steps(delta)
	if _station_lamp and _gas_station.visible:
		# The light over the pumps buzzes and flickers.
		_station_lamp.light_energy = 1.1 + sin(_time * 7.0) * 0.08 + (0.35 if sin(_time * 23.0) > 0.93 else 0.0) \
				- (0.8 if sin(_time * 3.3) > 0.985 else 0.0)
	_update_mirror(delta)
	_update_camera(delta)
	if _select_ui:
		_select_ui.modulate.a = move_toward(_select_ui.modulate.a, 1.0, delta * 4.0)


func _animate_figures() -> void:
	for id: String in _figures:
		var data: Dictionary = _figures[id]
		var root: Node3D = data["root"]
		var holder: Node3D = data["holder"]
		var mode: String = data.get("mode", "seat")
		var at_trunk := mode == "trunk"
		var reach := sin(_time * 2.4 + root.position.x * 5.0)
		var grab: float = data.get("grab", 0.0)
		var bob := sin(_time * 1.6 + root.position.x * 3.0) * (0.006 if at_trunk else 0.002)
		holder.rotation_degrees.x = (-14.0 + reach * 3.0 - grab * 22.0) if at_trunk else 0.0
		holder.position.y = bob
		# Walter can't keep still.
		if id == "walter" and mode == "meet":
			holder.rotation_degrees.y = sin(_time * 3.7) * 4.0 + sin(_time * 1.1) * 6.0
		var rig := data["rig"] as HumanRig
		if rig == null:
			continue
		if at_trunk:
			rig.set_pose(0.0, 0.0, 0.0, -26.0 + reach * 3.0, sin(_time * 1.6) * 0.4)
			rig._turn("Spine", HumanRig.SIDE, 20.0 + reach * 4.0 + grab * 20.0)
			rig._turn("LeftArm", HumanRig.SIDE, -48.0 + reach * 14.0 - grab * 30.0)
			rig._turn("RightArm", HumanRig.SIDE, -48.0 - reach * 14.0 - grab * 30.0)
		elif mode == "meet":
			rig.set_pose(0.0, 0.0, 0.0, 0.0, sin(_time * 1.6))
		else:
			rig.set_pose(0.0, 0.0, 0.0, 0.0, sin(_time * 1.6))
			for leg in ["LeftUpLeg", "RightUpLeg"]:
				rig._turn(leg, HumanRig.SIDE, -85.0)
			for knee in ["LeftLeg", "RightLeg"]:
				rig._turn(knee, HumanRig.SIDE, 85.0)
			if id == "eli":
				for arm in ["LeftArm", "RightArm"]:
					rig._turn(arm, HumanRig.SIDE, -55.0)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.TALK or state == State.MEETING:
		# The host can tap Space (or click) to move on to the next line.
		if not follow and _tap_ready and ((event is InputEventMouseButton and event.pressed) or event.is_action_released("ui_accept")):
			if _skip_hold < 0.35 and _step >= 0 and _steps[_step].has("line") and _line_shown:
				_step_time = _step_length
		return
	if state == State.ARRIVING:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_finish_arrival()
		return
	if state != State.SELECT:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if (event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left")) and (focus == null or focus in _cards.values()):
		var step := 1 if event.is_action_pressed("ui_right") else -1
		var current := CHARACTER_ORDER.find(hovered if hovered != "" else selected)
		var next: String = CHARACTER_ORDER[wrapi(current + step, 0, CHARACTER_ORDER.size())]
		(_cards[next] as Button).grab_focus()
		_set_hovered(next)
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ Public

## Play Cutscene 1 ("The Road"), then 2 ("The Meeting"), then character select.
func enter_opening() -> void:
	if state != State.MENU:
		return
	# CONTINUE: the story already happened in the saved game.
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.get("continue_on_start"):
		_start_arrival()
		return
	_go_step(0)


## Kept for older callers.
func enter_select() -> void:
	enter_opening()


## Straight to character select (a player joining while the others watch the
## cutscenes arrives here when the host's cutscene ends).
func enter_select_now() -> void:
	_go_step(_steps.size() - 1)


## Client: show the host's step.
func net_step(index: int) -> void:
	_go_step(index)


## Which part a step belongs to: "road", "meeting" or "select".
func scene_of(index: int) -> String:
	if index < 0 or index >= _steps.size():
		return "menu"
	return str(_steps[index]["scene"])


## Host: skip the rest of the cutscene that's playing.
func skip_scene() -> void:
	if _step < 0 or _step >= _steps.size():
		return
	var scene := scene_of(_step)
	if scene == "select":
		return
	var next := _step + 1
	while next < _steps.size() - 1 and scene_of(next) == scene:
		next += 1
	_go_step(next)


## How many players voted to skip (shown in the corner).
func set_skip_votes(count: int, total: int) -> void:
	_skip_votes = count
	_skip_total = maxi(total, 1)
	_refresh_skip_label()


## A player joined during the cutscenes: they wait here until character select.
func show_joining() -> void:
	_joining = true
	follow = true
	_joining_ui.show()
	_menu.hide()


## Who picked which character (main.gd calls this when the picks change).
## team: character id -> {"player": 2, "mine": false, "ready": true}.
func set_team(team: Dictionary, can_start: bool, is_host: bool) -> void:
	var before := _team
	_team = team
	_can_start = can_start
	_is_host = is_host
	taken.clear()
	selected = ""
	for id: String in team:
		if team[id].get("mine", false):
			selected = id
		else:
			taken.append(id)
	for id: String in CHARACTER_ORDER:
		var had := before.has(id)
		var has := team.has(id)
		if has and not had:
			_grab_gear(id)
		elif had and not has:
			_return_gear(id)
	_refresh_highlights()
	_refresh_info()


## Mark a character as taken by another player (older callers).
func set_character_taken(id: String, is_taken: bool) -> void:
	var team := _team.duplicate(true)
	if is_taken:
		team[id] = {"player": 2, "mine": false, "ready": false}
	elif team.has(id) and not team[id].get("mine", false):
		team.erase(id)
	set_team(team, _can_start, _is_host)


## The host pressed Start: fade to black (then main.gd starts the chapter).
func fade_to_black(seconds := 1.0) -> void:
	_fade.show()
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, seconds)


## The title/buttons part of the screen (main_menu.tscn).
func get_menu_ui() -> Control:
	return _menu


# ------------------------------------------------------------------ The cutscenes

func _load_script() -> Dictionary:
	var data := {}
	if FileAccess.file_exists(SCRIPT_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCRIPT_PATH))
		if parsed is Dictionary:
			data = parsed
		else:
			push_warning("opening_dialogue.json has a mistake in it, so the built-in lines are used.")
	for key: String in ["road", "meeting"]:
		if not (data.get(key) is Array):
			data[key] = FALLBACK_SCRIPT[key]
	return data


## Every step of both cutscenes, in order. Beats are moments without talking.
func _build_steps() -> void:
	_steps.clear()
	var lines := _load_script()
	_steps.append({"scene": "road", "beat": "road_open", "time": 3.5, "shot": "windshield"})
	for line: Dictionary in lines["road"]:
		_steps.append({"scene": "road", "line": line, "shot": str(line.get("shot", ""))})
	_steps.append({"scene": "road", "beat": "sign", "time": 4.2, "shot": "windshield"})
	_steps.append({"scene": "road", "beat": "turn", "time": 1.8, "shot": "windshield"})
	_steps.append({"scene": "meeting", "beat": "pull_in", "time": 5.5, "shot": "lot"})
	_steps.append({"scene": "meeting", "beat": "get_out", "time": 2.2, "shot": "lot"})
	for line: Dictionary in lines["meeting"]:
		_steps.append({"scene": "meeting", "line": line})
	_steps.append({"scene": "meeting", "beat": "trunk", "time": 2.8, "shot": "trunk_side"})
	_steps.append({"scene": "meeting", "beat": "black", "time": 0.9, "shot": "trunk_side"})
	_steps.append({"scene": "select", "beat": "select", "time": 0.0})


func _go_step(index: int) -> void:
	if index < 0 or index >= _steps.size():
		return
	var previous := scene_of(_step) if _step >= 0 else "menu"
	var s: Dictionary = _steps[index]
	var scene: String = s["scene"]
	_step = index
	_step_time = 0.0
	_line_shown = false
	_tap_ready = false
	get_tree().create_timer(0.3).timeout.connect(func() -> void: _tap_ready = true)
	if scene != previous or state == State.MENU:
		_enter_scene(scene)
	if scene == "meeting":
		_catch_up_meeting(index)
	if str(s.get("shot", "")) != _current_shot_name or s.has("line"):
		_snap_camera = true
	_current_shot_name = str(s.get("shot", ""))
	_talk_name.text = ""
	_talk_text.text = ""
	if _voice.playing:
		_voice.stop()
	if s.has("line"):
		var line: Dictionary = s["line"]
		_step_length = _line_length(line)
		_do_action(str(line.get("action", "")))
	else:
		_step_length = float(s.get("time", 0.0))
		_start_beat(str(s["beat"]))
	if not follow:
		step_started.emit(index)


func _enter_scene(scene: String) -> void:
	_skip_voted = false
	_skip_hold = 0.0
	_skip_votes = 0
	_menu.hide()
	_select_ui.hide()
	_hover_light.visible = false
	if scene == "road":
		state = State.TALK
		_talk_ui.show()
		_show_hero_car(true)
		_gas_station.hide()
		_sign.hide()
		_speed = DRIVE_SPEED
		_car.rotation.y = 0.0
		for tree in _trees:
			tree.visible = true
		for id: String in CHARACTER_ORDER:
			_stop_turn(id)
			var root: Node3D = _figures[id]["root"]
			root.visible = id in ["eli", "cole"]
			root.rotation.y = 0.0
			root.position = CHARACTERS[id]["seat"]
			_set_figure_mode(id, "seat")
		_turn_head("cole", -0.5, 0.01)  # Cole looks out of his window
		_set_trunk_open(false)
		_duffel.visible = true
	elif scene == "meeting":
		state = State.MEETING
		_talk_ui.show()
		_show_hero_car(true)
		_car.rotation.y = 0.0
		_sign.hide()
		for tree in _trees:
			tree.visible = false
		_gas_station.position.z = GAS_STATION_START_Z
		_gas_station.show()
		_speed = 12.0
		for id: String in ["eli", "cole"]:
			_stop_turn(id)
			var root: Node3D = _figures[id]["root"]
			root.visible = true
			root.position = CHARACTERS[id]["seat"]
			root.rotation.y = 0.0
			_set_figure_mode(id, "seat")
			_turn_head(id, 0.0, 0.01)
		# Nora and Walter are waiting at the station (they slide in with it).
		for id: String in ["nora", "walter"]:
			var root: Node3D = _figures[id]["root"]
			root.visible = true
			root.rotation = Vector3.ZERO
			root.position = MEET_POSITIONS[id]
			_set_figure_mode(id, "meet")
			_face_toward(id, Vector3(0, 0, 0.5))
			root.position.z += GAS_STATION_START_Z
		# Nora leans on her car.
		(_figures["nora"]["root"] as Node3D).rotation.z = deg_to_rad(-7.0)
		_set_trunk_open(false)
	elif scene == "select":
		_enter_select()
	_refresh_skip_label()


func _start_beat(beat: String) -> void:
	match beat:
		"sign":
			_sign.position = Vector3(4.6, 0.0, -78.0)
			_sign.show()
		"turn":
			_fade.show()
			var tween := create_tween()
			tween.tween_property(_car, "rotation:y", 0.32, 1.6).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(_fade, "color:a", 1.0, 1.5).set_delay(0.3)
		"pull_in":
			_fade.show()
			_fade.color.a = 1.0
			create_tween().tween_property(_fade, "color:a", 0.0, 1.0)
		"get_out":
			_speed = 0.0
			for id: String in ["eli", "cole"]:
				_set_figure_mode(id, "meet")
				_move_figure_to(id, MEET_POSITIONS[id], 1.2)
			_figures["eli"]["root"].rotation.y = 0.0
			_face_toward("eli", MEET_POSITIONS["nora"], 1.2)
			_face_toward("cole", MEET_POSITIONS["walter"], 1.2)
		"trunk":
			# Eli walks round to the trunk and opens it.
			_move_figure_to("eli", Vector3(-0.3, 0.0, 3.25), 1.2)
			_face_toward("eli", Vector3(-0.3, 0.0, 2.0), 1.0)
			var tween := create_tween()
			tween.tween_interval(1.3)
			tween.tween_method(func(a: float) -> void:
				if _trunk_lid:
					_trunk_lid.rotation_degrees.x = a
				if _trunk_lid_placeholder:
					_trunk_lid_placeholder.rotation_degrees.x = a, 0.0, TRUNK_OPEN_ANGLE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"black":
			_fade.show()
			create_tween().tween_property(_fade, "color:a", 1.0, 0.45)


## Joining the meeting part-way (a skip, or a late message): put everyone where
## they'd be by now.
func _catch_up_meeting(index: int) -> void:
	var pull_in := _find_beat("pull_in")
	var get_out := _find_beat("get_out")
	if index > pull_in:
		_gas_station.position.z = 0.0
		_speed = 0.0
		_fade.color.a = 0.0
		for id: String in ["nora", "walter"]:
			(_figures[id]["root"] as Node3D).position = MEET_POSITIONS[id]
	if index > get_out:
		for id: String in ["eli", "cole"]:
			_set_figure_mode(id, "meet")
			var root: Node3D = _figures[id]["root"]
			if root.position.z < 0.2:  # still in the car
				root.position = MEET_POSITIONS[id]
		_face_toward("eli", MEET_POSITIONS["nora"])
		_face_toward("cole", MEET_POSITIONS["walter"])


## The red tail lights (hidden while the camera looks out of the trunk).
func _set_taillights(on: bool) -> void:
	for car: Node3D in [_hero_car, _placeholder_car]:
		for part in car.get_children():
			if part is MeshInstance3D and part.material_override is StandardMaterial3D:
				var m := part.material_override as StandardMaterial3D
				if m.emission_enabled and m.emission.r > 0.8 and m.emission.g < 0.2:
					part.visible = on


func _find_beat(beat: String) -> int:
	for i in _steps.size():
		if _steps[i].get("beat", "") == beat:
			return i
	return -1


func _do_action(action: String) -> void:
	match action:
		"cole_looks_out":
			_turn_head("cole", -0.5, 0.8)
		"cole_looks_at_eli":
			_turn_head("cole", 0.45, 1.6)
		"cole_to_trunk":
			_move_figure_to("cole", Vector3(0.75, 0.0, 3.3), 2.6)
			_face_toward("cole", Vector3(0.0, 0.0, 0.0), 0.8)


func _update_steps(delta: float) -> void:
	if _step < 0 or _step >= _steps.size():
		return
	_step_time += delta
	var s: Dictionary = _steps[_step]
	if s.has("line") and not _line_shown and _step_time >= float(s["line"].get("pause", 0.0)):
		_show_line(s["line"])
	if s.get("beat", "") == "pull_in":
		var p := clampf(_step_time / maxf(_step_length - 1.0, 0.1), 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - p, 3.0)
		_gas_station.position.z = lerpf(GAS_STATION_START_Z, 0.0, eased)
		_speed = 12.0 * (1.0 - eased)
		for id: String in ["nora", "walter"]:
			var root: Node3D = _figures[id]["root"]
			root.position.z = MEET_POSITIONS[id].z + _gas_station.position.z
	_update_skip(delta)
	if not follow and _step_time >= _step_length:
		_go_step(_step + 1)


func _line_length(line: Dictionary) -> float:
	var text := str(line.get("text", ""))
	var length := clampf(text.length() / 14.0, 2.2, 7.5)
	var clip := _voice_stream(str(line.get("id", "")))
	if clip:
		length = maxf(length, clip.get_length() + 0.35)
	return float(line.get("pause", 0.0)) + length


func _voice_stream(id: String) -> AudioStream:
	if id.is_empty():
		return null
	for type: String in ["ogg", "wav", "mp3"]:
		var path := VOICE_PATH % [id, type]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _show_line(line: Dictionary) -> void:
	_line_shown = true
	var who := str(line.get("speaker", ""))
	var id := str(line.get("id", ""))
	var show_subtitles: bool = Settings.subtitles if "subtitles" in Settings else true
	_talk_name.text = CHARACTERS[who]["name"].split(" ")[0] if CHARACTERS.has(who) else who.to_upper()
	_talk_text.text = str(line.get("text", ""))
	_talk_name.visible = show_subtitles
	_talk_text.visible = show_subtitles
	var clip := _voice_stream(id)
	if clip and not _joining:
		_voice.stream = clip
		_voice.play()
	if not id.is_empty():
		voice_line_requested.emit(id)


func _update_skip(delta: float) -> void:
	if _joining:
		return
	if Input.is_action_pressed("ui_accept"):
		_skip_hold += delta
	else:
		_skip_hold = 0.0
	if _skip_hold >= SKIP_HOLD_TIME and not _skip_voted:
		_skip_voted = true
		if embedded:
			skip_vote.emit(true)
		else:
			skip_scene()
	_refresh_skip_label()


func _refresh_skip_label() -> void:
	if _skip_label == null:
		return
	var button := "A" if _using_pad else "SPACE"
	var text := "Hold [%s] to skip" % button
	if _skip_total > 1 or _skip_votes > 0:
		text += "  (%d/%d)" % [_skip_votes, _skip_total]
	if _skip_voted:
		text = "You voted to skip  (%d/%d)" % [_skip_votes, _skip_total]
	elif _skip_hold > 0.15:
		var filled := int(_skip_hold / SKIP_HOLD_TIME * 10.0)
		text += "  " + "■".repeat(filled) + "□".repeat(maxi(10 - filled, 0))
	if not follow:
		text += "      [%s] next line" % ("A" if _using_pad else "SPACE")
	_skip_label.text = text


# ------------------------------------------------------------------ Camera

func _update_camera(delta: float) -> void:
	var pos: Vector3
	var look: Vector3
	var fov := 55.0
	var speed := 4.0
	if state == State.MENU:
		# A slow drift around the outside of the car (front, then its left side).
		var angle := deg_to_rad(215.0 + sin(_time * 0.045) * 50.0)
		var radius := 5.4 + sin(_time * 0.07) * 0.35
		pos = MENU_CAM_TARGET + Vector3(sin(angle) * radius, 0.35 + sin(_time * 0.11) * 0.2, cos(angle) * radius)
		var forward := (MENU_CAM_TARGET - pos).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		look = MENU_CAM_TARGET - right * 1.5  # the car sits right of the title
		speed = 2.0
	elif state == State.TALK:
		var shot := _current_shot()
		if ROAD_SHOTS.has(shot):
			var data: Array = ROAD_SHOTS[shot]
			pos = _car.to_global(data[0])
			look = _car.to_global(data[1])
			fov = data[2]
		elif shot == "eli" or shot == "cole":
			var c: Dictionary = CHARACTERS[shot]
			pos = _car.to_global(c["talk_cam"] + _face_lift(shot))
			look = _car.to_global(c["talk_look"] + _face_lift(shot))
			fov = 46.0
		else:
			pos = _car.to_global(ROAD_SHOTS["windshield"][0])
			look = _car.to_global(ROAD_SHOTS["windshield"][1])
		speed = 7.0
	elif state == State.MEETING:
		var shot := _current_shot()
		var who := ""
		if _step >= 0 and _steps[_step].has("line"):
			who = str(_steps[_step]["line"].get("speaker", ""))
		if who != "" and _figures.has(who):
			var anchor: Vector3 = (_figures[who]["root"] as Node3D).position
			var face := anchor + Vector3(0, 1.5, 0) + _face_lift(who)
			var toward := (_talk_center(who) - anchor)
			toward.y = 0.0
			toward = toward.normalized() if toward.length() > 0.1 else Vector3(0, 0, -1)
			var side := toward.cross(Vector3.UP).normalized()
			pos = face + toward * 1.7 + side * 0.55 + Vector3(0, 0.08, 0)
			look = face - Vector3(0, 0.08, 0)
			fov = 40.0
		elif shot == "trunk_side":
			pos = Vector3(-3.4, 1.9, 6.6)
			look = Vector3(0.0, 1.1, 2.6)
			fov = 50.0
		else:
			pos = Vector3(3.4, 2.2, 7.6)
			look = Vector3(-0.4, 1.3, -6.0)
			fov = 55.0
		speed = 5.0
	elif state == State.SELECT or state == State.ARRIVING:
		pos = SELECT_CAM_POS
		look = SELECT_CAM_TARGET
		fov = 80.0
		if state == State.SELECT and hovered != "" and _figures.has(hovered):
			# Ease a little toward whoever you're looking at.
			var who_pos: Vector3 = (_figures[hovered]["root"] as Node3D).position
			pos = pos.lerp(Vector3(who_pos.x * 0.35, pos.y + 0.03, pos.z + 0.12), 0.5)
			look = look.lerp(who_pos + Vector3(0, 1.6, 0) + _face_lift(hovered), 0.35)
			fov = 72.0
		speed = 3.5
	var target := Transform3D().looking_at(look - pos)
	target.origin = pos
	if _snap_camera:
		_snap_camera = false
		_camera.fov = fov
		_camera.global_transform = target
		return
	_camera.fov = lerpf(_camera.fov, fov, minf(delta * speed, 1.0))
	_camera.global_transform = _camera.global_transform.interpolate_with(target, 1.0 - exp(-speed * delta))


func _current_shot() -> String:
	if _step < 0 or _step >= _steps.size():
		return ""
	return str(_steps[_step].get("shot", ""))


## Where everyone else is standing (the speaker looks that way).
func _talk_center(who: String) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for id: String in _figures:
		if id != who and (_figures[id]["root"] as Node3D).visible:
			sum += (_figures[id]["root"] as Node3D).position
			count += 1
	return sum / float(count) if count > 0 else Vector3.ZERO


## Turn someone to face a point (they face -Z when not turned).
func _face_toward(id: String, point: Vector3, seconds := 0.0) -> void:
	var root: Node3D = _figures[id]["root"]
	var dir := point - root.position
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var yaw := atan2(-dir.x, -dir.z)
	_stop_turn(id)
	if seconds <= 0.0:
		root.rotation.y = yaw
	else:
		var tween := create_tween()
		tween.tween_property(root, "rotation:y", root.rotation.y + wrapf(yaw - root.rotation.y, -PI, PI), seconds).set_trans(Tween.TRANS_SINE)
		_figures[id]["turn_tween"] = tween


## Stop someone turning (a skip can jump to the next scene mid-turn).
func _stop_turn(id: String) -> void:
	var tween: Tween = _figures[id].get("turn_tween") as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	var move: Tween = _figures[id].get("move_tween") as Tween
	if move != null and move.is_valid():
		move.kill()


## Turn someone's body a little in their seat (looking out of the window or at the driver).
func _turn_head(id: String, yaw: float, seconds: float) -> void:
	var holder: Node3D = _figures[id]["holder"]
	create_tween().tween_property(holder, "rotation:y", yaw, seconds).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ States

func _set_state(new_state: State) -> void:
	if new_state == State.SELECT:
		_enter_select()
		return
	state = State.MENU
	_step = -1
	hovered = ""
	_select_ui.hide()
	_talk_ui.hide()
	_joining_ui.hide()
	_menu.show()
	if _menu.has_method("show_main_buttons"):
		_menu.show_main_buttons()
	_show_hero_car(true)
	_speed = DRIVE_SPEED
	_car.rotation.y = 0.0
	# Only Eli (driving) and Cole are in the car; the back seat has a duffel bag.
	for id: String in _figures:
		_stop_turn(id)
		var root: Node3D = _figures[id]["root"]
		root.visible = id in ["eli", "cole"]
		root.position = CHARACTERS[id]["seat"]
		root.rotation = Vector3.ZERO
		_set_figure_mode(id, "seat")
	_turn_head("cole", -0.25, 0.01)
	_duffel.visible = true
	for tree in _trees:
		tree.visible = true
	_station.hide()
	_gas_station.hide()
	_sign.hide()
	_hover_light.visible = false
	_set_trunk_open(false)
	_set_taillights(true)
	_refresh_highlights()


func _enter_select() -> void:
	state = State.SELECT
	hovered = ""
	_joining = false
	_joining_ui.hide()
	_talk_ui.hide()
	_menu.hide()
	_speed = 0.0
	_show_hero_car(true)
	_car.rotation.y = 0.0
	_station.hide()
	_sign.hide()
	_gas_station.position.z = 0.0
	_gas_station.show()
	for tree in _trees:
		tree.visible = false
	_set_trunk_open(true)
	_set_taillights(false)
	_duffel.visible = false  # it's in the trunk now
	for id: String in CHARACTER_ORDER:
		_stop_turn(id)
		var root: Node3D = _figures[id]["root"]
		root.visible = true
		root.position = TRUNK_POSITIONS[id]
		root.rotation = Vector3.ZERO  # facing the trunk (and the camera inside it)
		(_figures[id]["holder"] as Node3D).rotation.y = 0.0
		_set_figure_mode(id, "trunk")
	for id: String in _gear_taken.keys():
		_place_gear_in_hands(id)
	_snap_camera = true
	_select_ui.modulate.a = 0.0
	_select_ui.show()
	_fade.show()
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)
	_refresh_highlights()
	_refresh_info()
	(_cards[CHARACTER_ORDER[2]] as Button).grab_focus.call_deferred()


# ------------------------------------------------------------------ Character select

func _set_hovered(id: String) -> void:
	if state != State.SELECT:
		return
	_unhover_timer = null
	if hovered == id:
		return
	var old := hovered
	hovered = id
	# Step forward a little toward the trunk (and the last one steps back).
	for who: String in [old, id]:
		if who == "" or not _figures.has(who):
			continue
		var home: Vector3 = TRUNK_POSITIONS[who]
		_move_figure_to(who, home - Vector3(0, 0, HOVER_STEP) if who == id else home, 0.45)
	if id != "" and _figures.has(id):
		var p: Vector3 = TRUNK_POSITIONS[id]
		_hover_light.position = p + Vector3(0.0, 2.9, -1.3)
		_hover_light.look_at(p + Vector3(0, 1.2, -HOVER_STEP), Vector3.UP)
		_hover_light.visible = true
	else:
		_hover_light.visible = false
	_refresh_highlights()
	_refresh_info()


## Waits a moment before un-hovering, so moving the mouse between cards
## doesn't make the camera jump around.
func _unhover(id: String) -> void:
	var timer := get_tree().create_timer(0.35)
	_unhover_timer = timer
	timer.timeout.connect(func() -> void:
		if _unhover_timer == timer and hovered == id:
			_set_hovered(""))


## Click someone (or their card): pick them. Clicking your own pick puts it back.
func _select(id: String) -> void:
	if state != State.SELECT or taken.has(id):
		return
	var want := "" if selected == id else id
	if embedded:
		pick_requested.emit(want)
		return
	# Running this scene by itself: you're the only player.
	var team := {}
	if want != "":
		team[want] = {"player": 1, "mine": true, "ready": false}
		character_confirmed.emit(want)
	_local_ready = false
	set_team(team, false, true)


func _on_ready_pressed() -> void:
	if selected == "":
		return
	var now_ready := not bool(_team.get(selected, {}).get("ready", false))
	if embedded:
		ready_toggled.emit(now_ready)
		return
	_team[selected]["ready"] = now_ready
	set_team(_team.duplicate(true), now_ready, true)


func _on_start_pressed() -> void:
	if not _can_start:
		return
	if embedded:
		start_requested.emit()
		return
	fade_to_black()
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if ResourceLoader.exists(LOBBY_SCENE):
			get_tree().change_scene_to_file(LOBBY_SCENE))


# ------------------------------------------------------------------ Gear in the trunk

## What each person takes out of the trunk, and the rest of the gear.
func _build_trunk_gear() -> void:
	var black := _mat(Color(0.05, 0.05, 0.055), 0.5)
	var lens := _mat(Color(0.9, 0.9, 0.8), 0.2, Color(1.0, 0.95, 0.8), 1.2)
	var silver := _mat(Color(0.55, 0.56, 0.58), 0.35)
	var red := _mat(Color(0.45, 0.07, 0.05), 0.6)
	var olive := _mat(Color(0.2, 0.22, 0.12), 0.9)
	var brown := _mat(Color(0.25, 0.16, 0.09), 0.85)
	var grey := _mat(Color(0.3, 0.3, 0.3), 0.6)
	var y := 0.8  # the trunk floor
	_box(_car, Vector3(2.06, 0.02, 1.0), Vector3(0.0, 0.785, 2.12), _mat(Color(0.05, 0.045, 0.045), 0.95))  # trunk mat

	_gear = {"eli": [], "cole": [], "nora": [], "walter": []}
	# Eli: a flashlight and Mateo's dog tag.
	_add_gear("eli", _cylinder(0.025, 0.24, black, lens), Vector3(-0.38, y + 0.025, 2.42), Vector3(90, 0, 20))
	var tag := Node3D.new()
	_box(tag, Vector3(0.03, 0.004, 0.045), Vector3.ZERO, silver)
	_box(tag, Vector3(0.004, 0.003, 0.14), Vector3(0, 0, -0.08), silver)
	_add_gear("eli", tag, Vector3(-0.18, y + 0.005, 2.5), Vector3(0, 30, 0))
	# Cole: the heavy flashlight.
	_add_gear("cole", _cylinder(0.04, 0.36, black, lens), Vector3(-0.66, y + 0.04, 2.38), Vector3(90, 0, -15))
	# Nora: her camera.
	var camera := Node3D.new()
	_box(camera, Vector3(0.13, 0.08, 0.06), Vector3.ZERO, black)
	var cam_lens := _cylinder(0.03, 0.06, grey, null)
	cam_lens.rotation_degrees.x = 90.0
	cam_lens.position = Vector3(0, 0, -0.05)
	camera.add_child(cam_lens)
	_add_gear("nora", camera, Vector3(0.24, y + 0.04, 2.45), Vector3(0, -20, 0))
	# Walter: his toolbox and a wrench.
	var toolbox := Node3D.new()
	_box(toolbox, Vector3(0.42, 0.18, 0.2), Vector3.ZERO, red)
	_box(toolbox, Vector3(0.22, 0.03, 0.03), Vector3(0, 0.12, 0), black)
	_add_gear("walter", toolbox, Vector3(0.6, y + 0.09, 2.36), Vector3(0, 10, 0))
	var wrench := Node3D.new()
	_box(wrench, Vector3(0.025, 0.012, 0.26), Vector3.ZERO, silver)
	_box(wrench, Vector3(0.06, 0.012, 0.04), Vector3(0, 0, -0.14), silver)
	_add_gear("walter", wrench, Vector3(0.4, y + 0.008, 2.52), Vector3(0, -35, 0))

	# The rest stays in the trunk: walkie-talkies, a crowbar, Cole's duffel
	# bag and Nora's camera bag.
	for i in 2:
		var walkie := Node3D.new()
		_box(walkie, Vector3(0.06, 0.16, 0.035), Vector3(0, 0.08, 0), black)
		_box(walkie, Vector3(0.008, 0.1, 0.008), Vector3(0.018, 0.2, 0), black)
		walkie.position = Vector3(0.02 + i * 0.09, y + 0.02, 2.5)
		walkie.rotation_degrees = Vector3(-80, 0, 0)
		_car.add_child(walkie)
	var crowbar := _box(_car, Vector3(0.025, 0.025, 0.8), Vector3(0.05, y + 0.015, 2.32), _mat(Color(0.32, 0.06, 0.05), 0.5))
	crowbar.rotation_degrees.y = 72.0
	var duffel := _capsule(0.1, 0.5, olive)
	duffel.position = Vector3(-0.72, y + 0.1, 2.2)
	duffel.rotation_degrees = Vector3(0, 0, 90)
	_car.add_child(duffel)
	_box(_car, Vector3(0.24, 0.14, 0.13), Vector3(0.74, y + 0.07, 2.12), brown)  # Nora's camera bag


func _add_gear(id: String, node: Node3D, pos: Vector3, rot: Vector3) -> void:
	node.position = pos
	node.rotation_degrees = rot
	if node.get_parent() == null:
		_car.add_child(node)
	_gear[id].append({"node": node, "home": pos, "rot": rot})


func _cylinder(radius: float, length: float, mat: Material, cap: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mi.mesh = mesh
	mi.material_override = mat
	if cap:
		var glass := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = radius * 0.85
		disc.bottom_radius = radius * 0.85
		disc.height = 0.006
		glass.mesh = disc
		glass.position.y = length * 0.5
		glass.material_override = cap
		mi.add_child(glass)
	return mi


func _capsule(radius: float, length: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length
	mi.mesh = mesh
	mi.material_override = mat
	return mi


## They lean into the trunk and take their gear.
func _grab_gear(id: String) -> void:
	_gear_taken[id] = true
	var data: Dictionary = _figures[id]
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: data["grab"] = v, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.15)
	tween.tween_callback(_place_gear_in_hands.bind(id, 0.6))
	tween.tween_method(func(v: float) -> void: data["grab"] = v, 1.0, 0.0, 0.6).set_trans(Tween.TRANS_SINE)


## Moves someone's gear from the trunk to their hands (in front of their chest).
func _place_gear_in_hands(id: String, seconds := 0.0) -> void:
	if not _gear_taken.has(id) or state != State.SELECT:
		return
	var home: Vector3 = TRUNK_POSITIONS[id]
	var items: Array = _gear[id]
	for i in items.size():
		var item: Dictionary = items[i]
		var node: Node3D = item["node"]
		var target := home + Vector3((0.12 if i == 0 else -0.12), 1.0 + (0.08 if id == "nora" else 0.0), -0.3)
		if id == "walter" and i == 0:
			target = home + Vector3(0.22, 0.62, -0.18)  # the toolbox hangs at his side
		var rot: Vector3 = Vector3(0, 0, 0) if id == "nora" or id == "walter" else Vector3(-70, 0, 0)
		if seconds <= 0.0:
			node.position = target
			node.rotation_degrees = rot
		else:
			var tween := create_tween()
			tween.tween_property(node, "position", target, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(node, "rotation_degrees", rot, seconds)


## Put it back in the trunk (they changed their mind).
func _return_gear(id: String) -> void:
	_gear_taken.erase(id)
	for item: Dictionary in _gear.get(id, []):
		var node: Node3D = item["node"]
		var tween := create_tween()
		tween.tween_property(node, "position", item["home"], 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(node, "rotation_degrees", item["rot"], 0.6)


# ------------------------------------------------------------------ The car on the road

## Rain, wipers, Mateo's dog tag on the mirror, Eli's hands on the wheel, the
## duffel bag in the back seat and the gas station sign.
func _build_car_details() -> void:
	var black := _mat(Color(0.03, 0.03, 0.03), 0.6)
	# Two wipers at the bottom of the windshield (it leans back 28 degrees).
	for x in [-0.55, 0.2]:
		var base := Node3D.new()
		base.position = Vector3(x, 1.13, -0.93)
		base.rotation_degrees.x = -62.0
		_hero_car.add_child(base)
		var arm := Node3D.new()
		arm.set_meta("dir", -1.0)
		base.add_child(arm)
		var blade := _box(arm, Vector3(0.015, 0.62, 0.012), Vector3(0, 0.31, -0.02), black)
		blade.rotation_degrees.z = 0.0
		arm.rotation_degrees.z = 0.0
		_wipers.append(arm)
	# Mateo's dog tag hanging from the rear-view mirror.
	_dog_tag = Node3D.new()
	_dog_tag.position = MIRROR_POS + Vector3(0.0, -0.05, 0.0)
	_hero_car.add_child(_dog_tag)
	var chain := _mat(Color(0.6, 0.6, 0.6), 0.3)
	_box(_dog_tag, Vector3(0.004, 0.13, 0.004), Vector3(0, -0.065, 0), chain)
	_box(_dog_tag, Vector3(0.022, 0.034, 0.003), Vector3(0, -0.145, 0), _mat(Color(0.42, 0.43, 0.44), 0.3))
	# Eli's hands on the wheel at ten and two (stand-ins until the model can hold it).
	_hands = Node3D.new()
	_hero_car.add_child(_hands)
	var skin := _mat(Color(0.55, 0.4, 0.3), 0.7)
	var sleeve_mat := _mat(Color(0.32, 0.2, 0.11), 0.8)
	for x in [-0.525, -0.235]:
		var hand := _capsule(0.026, 0.1, skin)
		hand.position = Vector3(x, 1.255, -0.585)
		hand.rotation_degrees = Vector3(-25, 0, 0)
		_hands.add_child(hand)
		var sleeve := _capsule(0.04, 0.32, sleeve_mat)
		sleeve.position = Vector3(x + (-0.03 if x < -0.3 else 0.03), 1.24, -0.43)
		sleeve.rotation_degrees = Vector3(-75, 0, 0)
		_hands.add_child(sleeve)
	# The duffel bag on the back seat.
	_duffel = _capsule(0.15, 0.7, _mat(Color(0.2, 0.22, 0.12), 0.9))
	_duffel.position = Vector3(0.35, 1.12, 1.0)
	_duffel.rotation_degrees = Vector3(0, 0, 90)
	_hero_car.add_child(_duffel)

	# Rain falling past the car (it streams back as the car drives).
	_rain = GPUParticles3D.new()
	_rain.amount = 900
	_rain.lifetime = 1.2
	_rain.visibility_aabb = AABB(Vector3(-15, -2, -30), Vector3(30, 14, 50))
	_rain.position = Vector3(0, 9, -6)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(12, 0.5, 18)
	process.direction = Vector3(0, -1, 0.35)
	process.spread = 2.0
	process.initial_velocity_min = 14.0
	process.initial_velocity_max = 17.0
	process.gravity = Vector3(0, -6, 0)
	_rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.012, 0.45)
	var rain_mat := StandardMaterial3D.new()
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.albedo_color = Color(0.7, 0.75, 0.85, 0.35)
	rain_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	streak.material = rain_mat
	_rain.draw_pass_1 = streak
	add_child(_rain)

	# "PINE HOLLOW GAS - 1 MI": the sign the headlights catch at the end of the drive.
	_sign = Node3D.new()
	_sign.hide()
	add_child(_sign)
	_box(_sign, Vector3(0.1, 2.4, 0.1), Vector3(0, 1.2, 0), _mat(Color(0.35, 0.35, 0.33), 0.6))
	_box(_sign, Vector3(2.0, 0.9, 0.06), Vector3(0, 2.5, 0), _mat(Color(0.75, 0.73, 0.62), 0.5, Color(0.55, 0.52, 0.42), 0.35))
	var words := Label3D.new()
	words.text = "PINE HOLLOW GAS\n1 MI  ←"
	words.font_size = 64
	words.pixel_size = 0.0042
	words.modulate = Color(0.12, 0.1, 0.08)
	words.outline_size = 0
	words.position = Vector3(0, 2.5, 0.04)
	words.rotation_degrees.y = 180.0
	_sign.add_child(words)
	_sign.rotation_degrees.y = 160.0

	# A soft light on their faces inside the car (like the dashboard glow).
	var face_light := OmniLight3D.new()
	face_light.name = "FaceLight"
	face_light.position = Vector3(0.0, 1.5, -0.62)
	face_light.light_color = Color(0.95, 0.85, 0.75)
	face_light.light_energy = 0.35
	face_light.omni_range = 1.4
	_hero_car.add_child(face_light)

	# Soft moonlight over the car on the road, so you can see it.
	_road_fill = OmniLight3D.new()
	_road_fill.position = Vector3(-3.5, 4.5, 1.0)
	_road_fill.light_color = Color(0.55, 0.65, 0.9)
	_road_fill.light_energy = 1.3
	_road_fill.omni_range = 11.0
	add_child(_road_fill)

	# A soft light on whoever you hover at the trunk.
	_hover_light = SpotLight3D.new()
	_hover_light.light_color = Color(1.0, 0.86, 0.66)
	_hover_light.light_energy = 2.6
	_hover_light.spot_range = 6.0
	_hover_light.spot_angle = 16.0
	_hover_light.spot_angle_attenuation = 1.6
	_hover_light.visible = false
	add_child(_hover_light)


## The gas station's lot light and road sign behind the car (it lights the
## four from behind at the trunk), and the low buzz of the pump light.
func _build_gas_station_extras() -> void:
	var pole := _mat(Color(0.3, 0.3, 0.3), 0.6)
	_box(_gas_station, Vector3(0.18, 6.0, 0.18), Vector3(13.0, 3.0, 9.0), pole)
	var board := _box(_gas_station, Vector3(2.4, 1.3, 0.25), Vector3(13.0, 6.3, 9.0), _mat(Color(0.7, 0.62, 0.35), 0.5, Color(1.0, 0.8, 0.4), 0.6))
	board.rotation_degrees.y = 10.0
	var name_label := Label3D.new()
	name_label.text = "PINE HOLLOW\nGAS"
	name_label.font_size = 56
	name_label.pixel_size = 0.005
	name_label.modulate = Color(0.15, 0.08, 0.05)
	name_label.outline_size = 0
	name_label.position = Vector3(13.0, 6.3, 8.86)
	name_label.rotation_degrees.y = 190.0
	_gas_station.add_child(name_label)
	var lot := OmniLight3D.new()
	lot.position = Vector3(-2.0, 5.2, 8.5)
	lot.light_color = Color(1.0, 0.82, 0.55)
	lot.light_energy = 1.3
	lot.omni_range = 14.0
	lot.shadow_enabled = true
	_gas_station.add_child(lot)
	# Nora's car and Walter's old pickup get a few more shapes.
	_box(_gas_station, Vector3(1.6, 0.5, 2.0), Vector3(-5.4, 1.5, -1.2), _mat(Color(0.16, 0.2, 0.27)))
	_box(_gas_station, Vector3(2.0, 0.5, 1.6), Vector3(5.4, 1.75, 0.6), _mat(Color(0.1, 0.13, 0.15)))
	_box(_gas_station, Vector3(0.4, 0.22, 0.25), Vector3(4.55, 0.11, -0.05), _mat(Color(0.45, 0.07, 0.05), 0.6))  # Walter's toolbox
	var buzz_path := "res://assets/audio/ambient_drone.wav"
	if ResourceLoader.exists(buzz_path):
		var buzz := AudioStreamPlayer3D.new()
		buzz.stream = load(buzz_path)
		buzz.position = Vector3(0.0, 4.1, -2.0)
		buzz.volume_db = -14.0
		buzz.pitch_scale = 2.2
		buzz.autoplay = true
		buzz.unit_size = 4.0
		_gas_station.add_child(buzz)


## CONTINUE: the story already happened, so just fade out and load the save.
func _start_arrival() -> void:
	state = State.ARRIVING
	hovered = ""
	_arrived = true
	_menu.hide()
	_select_ui.hide()
	_talk_ui.hide()
	_refresh_highlights()
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_arrival_label, "modulate:a", 1.0, 1.0)
	tween.tween_callback(_finish_arrival)


func _refresh_highlights() -> void:
	for id: String in _figures:
		var data: Dictionary = _figures[id]
		var label: Label3D = data["label"]
		var info: Dictionary = _team.get(id, {})
		label.visible = state == State.SELECT and not info.is_empty()
		if info.is_empty():
			continue
		var text := "PLAYER %d" % int(info.get("player", 1))
		if info.get("mine", false):
			text += "  (YOU)"
		if info.get("ready", false):
			text += "\nREADY"
		label.text = text
		label.modulate = COLOR_HIGHLIGHT if info.get("mine", false) else COLOR_TEXT
		label.position.y = 2.15 if data.get("posed", false) else 1.95
		label.fixed_size = true
		label.pixel_size = 0.0011


func _refresh_cards() -> void:
	for id: String in _cards:
		var card: Button = _cards[id]
		var c: Dictionary = CHARACTERS[id]
		var first: String = c["name"].split(" ")[0]
		var role: String = c["role"].split("  //  ")[0]
		var status := role
		if taken.has(id):
			status = "TAKEN (PLAYER %d)" % int(_team[id].get("player", 0))
		elif id == selected:
			status = "YOU  -  click again to change"
		card.text = "%s\n%s" % [first, status]
		var style := card.get_theme_stylebox("normal") as StyleBoxFlat
		style.border_color = COLOR_HIGHLIGHT if id == selected else (COLOR_RED if taken.has(id) else c["color"].lightened(0.25))
		style.set_border_width_all(3 if id == selected else 0)
		style.border_width_left = 8
		card.add_theme_color_override("font_color", COLOR_RED if taken.has(id) else COLOR_TEXT)


func _refresh_info() -> void:
	var id := hovered if hovered != "" else selected
	if id == "":
		_info_name.text = "WHO ARE YOU?"
		_info_role.text = "LOOK AT SOMEONE AT THE TRUNK"
		_info_about.text = "Four people. One road in. Each of them has a reason to go into Blackwater, and a skill the others need to get out alive."
		_info_abilities.text = ""
		_info_quote.text = ""
		_info_items.text = ""
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
		_info_items.text = "TAKES FROM THE TRUNK:  " + str(c["items"]).to_upper()

	_refresh_cards()
	var my_info: Dictionary = _team.get(selected, {})
	_ready_button.disabled = selected == ""
	_ready_button.text = "NOT READY" if my_info.get("ready", false) else "READY"
	_start_button.visible = _is_host
	_start_button.disabled = not _can_start
	var picked := 0
	var ready := 0
	for who: String in _team:
		picked += 1
		if _team[who].get("ready", false):
			ready += 1
	if selected == "":
		_select_status.text = "PICK SOMEONE: CLICK THEM, OR THEIR CARD BELOW"
	elif _is_host and _can_start:
		_select_status.text = "EVERYONE IS READY. PRESS START."
	elif _is_host:
		_select_status.text = "%d READY. WAITING FOR EVERYONE TO PICK AND BE READY." % ready
	else:
		_select_status.text = "WAITING FOR THE HOST TO START  (%d READY)" % ready


# ------------------------------------------------------------------ Kept from before

func _move_figure_to(id: String, target: Vector3, duration := 0.85) -> void:
	if not _figures.has(id):
		return
	var data: Dictionary = _figures[id]
	var previous: Tween = data.get("move_tween") as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var root: Node3D = data["root"]
	var tween := create_tween()
	tween.tween_property(root, "position", target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	data["move_tween"] = tween


func _set_figure_mode(id: String, mode: String) -> void:
	if not _figures.has(id):
		return
	var data: Dictionary = _figures[id]
	data["mode"] = mode
	var seated := mode == "seat"
	if data.get("posed", false):
		var model: Node3D = data.get("model")
		if model:
			PoseShader.set_sitting(model, seated)
			var body: Dictionary = PoseShader.BODIES[MODEL_FILES[id][0]]
			model.position.y = 0.92 - float(body.hip_y) * model.scale.x if seated else 0.0
	for limb: Dictionary in data.get("limbs", []):
		var node: Node3D = limb["node"]
		if limb["kind"] == "thigh":
			node.rotation_degrees.x = 90.0 if seated else 0.0
		elif limb["kind"] == "arm":
			node.rotation_degrees.x = 55.0 if seated else (35.0 if mode == "trunk" else 8.0)


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
	_last_selected = selected
	var who := selected if selected != "" else "eli"
	var from: Vector3 = _car.to_global(MIRROR_POS)
	var face: Vector3 = (_figures[who]["root"] as Node3D).global_position + Vector3.UP * 1.5
	var target := Transform3D().looking_at(face - from)
	target.origin = from
	_mirror_cam.global_transform = _mirror_cam.global_transform.interpolate_with(target, minf(delta * 6.0, 1.0))


# ------------------------------------------------------------------ Arrival


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


func _build_hand_gun(holder: Node3D, side: float) -> Node3D:
	var gun := Node3D.new()
	var metal := _mat(Color("25282d"), 0.42, Color("4a4f57"), 0.12)
	_box(gun, Vector3(0.055, 0.065, 0.24), Vector3(0.0, 0.03, -0.02), metal)
	var grip := _box(gun, Vector3(0.05, 0.13, 0.07), Vector3(0.0, -0.07, 0.05), metal)
	grip.rotation_degrees.x = -16.0
	_box(gun, Vector3(0.012, 0.012, 0.018), Vector3(0.0, 0.07, -0.11), _mat(Color("c9c3b4"), 0.6))
	gun.position = Vector3(side * 0.5, 0.95, 1.45)
	gun.visible = false
	holder.add_child(gun)
	return gun


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


func _build_gas_station() -> void:
	_gas_station = Node3D.new()
	_gas_station.name = "GasStation"
	_gas_station.hide()
	add_child(_gas_station)
	var concrete := _mat(Color(0.24, 0.25, 0.25), 0.95)
	var metal := _mat(Color(0.3, 0.31, 0.32), 0.55)
	var dark_glass := _mat(Color(0.02, 0.025, 0.03), 0.15)
	var yellow := _mat(Color(0.55, 0.45, 0.2), 0.7, Color(1.0, 0.75, 0.3), 0.5)

	_box(_gas_station, Vector3(12.0, 4.4, 6.0), Vector3(0.0, 2.2, -11.0), concrete)
	for wx in [-4.0, -1.5, 1.5, 4.0]:
		_box(_gas_station, Vector3(2.0, 1.2, 0.1), Vector3(wx, 2.4, -7.94), dark_glass)
	_box(_gas_station, Vector3(3.0, 0.9, 0.1), Vector3(0.0, 3.6, -7.94), yellow)
	var closed := Label3D.new()
	closed.text = "CLOSED"
	closed.position = Vector3(0.0, 3.6, -7.86)
	closed.font_size = 48
	closed.pixel_size = 0.0035
	closed.modulate = Color(0.12, 0.08, 0.05)
	closed.outline_size = 0
	_gas_station.add_child(closed)

	_box(_gas_station, Vector3(12.0, 0.3, 6.5), Vector3(0.0, 4.4, -2.0), concrete)
	for px in [-5.5, 5.5]:
		for pz in [-4.6, 0.6]:
			_box(_gas_station, Vector3(0.22, 4.2, 0.22), Vector3(px, 2.1, pz), metal)
	for px in [-3.2, 3.2]:
		_box(_gas_station, Vector3(0.7, 1.9, 0.5), Vector3(px, 0.95, -2.4), yellow)
		_box(_gas_station, Vector3(0.5, 0.7, 0.05), Vector3(px, 1.3, -2.68), dark_glass)

	_station_lamp = OmniLight3D.new()
	_station_lamp.position = Vector3(0.0, 4.1, -2.0)
	_station_lamp.light_color = Color(1.0, 0.8, 0.45)
	_station_lamp.omni_range = 13.0
	_gas_station.add_child(_station_lamp)

	var puddle_mat := _mat(Color(0.04, 0.06, 0.08, 0.75), 0.2, Color(0.35, 0.45, 0.6), 0.12)
	for p in [Vector3(-2.4, 0.012, 1.2), Vector3(2.8, 0.012, 2.0), Vector3(-5.0, 0.012, -3.4)]:
		var puddle := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(2.6, 1.5)
		puddle.mesh = plane
		puddle.position = p
		puddle.material_override = puddle_mat
		_gas_station.add_child(puddle)

	_box(_gas_station, Vector3(1.8, 1.25, 4.0), Vector3(-5.4, 0.65, -1.0), _mat(Color(0.18, 0.22, 0.3)))
	_box(_gas_station, Vector3(2.2, 1.5, 4.8), Vector3(5.4, 0.75, -1.0), _mat(Color(0.12, 0.15, 0.18)))
	_box(_gas_station, Vector3(2.0, 0.7, 1.8), Vector3(5.4, 1.7, -1.8), _mat(Color(0.15, 0.18, 0.21)))




## Both cars go inside one holder (_car), so the people and the mirror ride
## along whichever one is showing.
func _build_cars() -> void:
	_build_hero_car()
	_hero_car = _car
	_build_placeholder_car()
	_placeholder_car = _car
	_car = Node3D.new()
	_car.name = "Car"
	add_child(_car)
	for car: Node3D in [_hero_car, _placeholder_car]:
		remove_child(car)
		_car.add_child(car)
	_show_hero_car(false)
	for car: Node3D in [_hero_car, _placeholder_car]:
		_swap_in_real_car(car)


## If the real car model is there, it replaces the boxes (the lights stay).
func _swap_in_real_car(car: Node3D) -> void:
	var scene: PackedScene = null
	for car_name: String in CAR_MODEL_NAMES:
		for type: String in CAR_MODEL_TYPES:
			var path := "res://assets/models/cars/%s.%s" % [car_name, type]
			if scene == null and ResourceLoader.exists(path):
				scene = load(path) as PackedScene
	if scene == null:
		return
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	for child in car.get_children():
		if child is GeometryInstance3D and not child.has_meta("keep_trunk"):
			child.visible = false
	var holder := Node3D.new()
	holder.name = "RealCar"
	car.add_child(holder)
	holder.add_child(model)
	# Lay it along the car (its longest side front to back), then turn and size it.
	var box := _model_box(model, holder)
	if box.size.x > box.size.z:
		model.rotation.y = PI / 2.0
		box = _model_box(model, holder)
	model.rotation.y += deg_to_rad(CAR_MODEL_TURN)
	box = _model_box(model, holder)
	var length := maxf(box.size.z, 0.001)
	model.scale *= CAR_MODEL_LENGTH / length
	box = _model_box(model, holder)
	model.position += Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) + CAR_MODEL_OFFSET


## The model's size and place, measured in the holder's own space.
func _model_box(model: Node3D, holder: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var to_holder := holder.global_transform.affine_inverse()
	for part in model.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = (to_holder * (part as VisualInstance3D).global_transform) * (part as VisualInstance3D).get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


func _show_hero_car(hero: bool) -> void:
	_hero_car.visible = hero
	_placeholder_car.visible = not hero


func _set_trunk_open(open: bool) -> void:
	var angle := TRUNK_OPEN_ANGLE if open else 0.0
	if _trunk_lid:
		_trunk_lid.rotation_degrees.x = angle
	if _trunk_lid_placeholder:
		_trunk_lid_placeholder.rotation_degrees.x = angle


func _build_hero_car() -> void:
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
	var cavity := _box(_car, Vector3(1.8, 0.28, 0.9), Vector3(0, 0.9, 2.1), _mat(Color(0.02, 0.02, 0.03)))
	cavity.set_meta("keep_trunk", true)
	_trunk_lid = Node3D.new()
	_trunk_lid.position = Vector3(0, 1.14, 1.62)  # hinged by the back window
	_car.add_child(_trunk_lid)
	var lid := _box(_trunk_lid, Vector3(2.0, 0.08, 1.0), Vector3(0, 0, 0.5), paint)
	lid.set_meta("keep_trunk", true)
	var trunk_light := OmniLight3D.new()
	trunk_light.position = Vector3(0, -0.25, 0.55)
	trunk_light.light_color = Color(1.0, 0.9, 0.75)
	trunk_light.light_energy = 1.2
	trunk_light.omni_range = 2.5
	_trunk_lid.add_child(trunk_light)
	_set_trunk_open(true)
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
	dash_light.light_energy = 0.04
	dash_light.omni_range = 1.6
	_car.add_child(dash_light)


func _build_placeholder_car() -> void:
	_car = Node3D.new()
	add_child(_car)

	var placeholder_mat := _mat(Color(0.15, 0.15, 0.15), 0.8)

	# Simple blocky placeholder car body
	_box(_car, Vector3(2.0, 0.5, 4.5), Vector3(0, 0.6, 0.3), placeholder_mat)       # floor/lower body
	_box(_car, Vector3(1.8, 0.05, 2.5), Vector3(0, 0.85, 0.4), _mat(Color(0.05, 0.045, 0.04)))  # cabin floor
	_box(_car, Vector3(2.0, 0.4, 1.5), Vector3(0, 1.0, -1.6), placeholder_mat)     # hood
	var cavity := _box(_car, Vector3(1.8, 0.28, 0.9), Vector3(0, 0.95, 2.05), _mat(Color(0.02, 0.02, 0.03)))
	cavity.set_meta("keep_trunk", true)
	_trunk_lid_placeholder = Node3D.new()
	_trunk_lid_placeholder.position = Vector3(0, 1.2, 1.6)
	_car.add_child(_trunk_lid_placeholder)
	var lid := _box(_trunk_lid_placeholder, Vector3(2.0, 0.08, 1.0), Vector3(0, 0, 0.5), placeholder_mat)
	lid.set_meta("keep_trunk", true)
	_set_trunk_open(true)
	_box(_car, Vector3(0.1, 0.4, 2.4), Vector3(-1.0, 1.0, 0.5), placeholder_mat)   # door left
	_box(_car, Vector3(0.1, 0.4, 2.4), Vector3(1.0, 1.0, 0.5), placeholder_mat)    # door right
	_box(_car, Vector3(2.05, 0.1, 4.5), Vector3(0, 0.35, 0.3), _mat(Color(0.2, 0.2, 0.2))) # bumper line
	_box(_car, Vector3(1.8, 0.05, 2.0), Vector3(0, 1.7, 0.5), placeholder_mat)     # roof

	# Simple wheels (4)
	var tire := _mat(Color(0.02, 0.02, 0.02))
	for pos in [Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5), Vector3(-0.95, 0.4, 1.6), Vector3(0.95, 0.4, 1.6)]:
		var w := MeshInstance3D.new()
		var w_mesh := CylinderMesh.new()
		w_mesh.top_radius = 0.4
		w_mesh.bottom_radius = 0.4
		w_mesh.height = 0.25
		w.mesh = w_mesh
		w.position = pos
		w.rotation_degrees.z = 90.0
		w.material_override = tire
		_car.add_child(w)

	# Simple headlights (2)
	var head_mat := _mat(Color(1, 1, 0.9), 0.2, Color(1, 0.95, 0.8), 2.0)
	for x in [-0.7, 0.7]:
		_box(_car, Vector3(0.35, 0.15, 0.05), Vector3(x, 1.0, -2.4), head_mat)

	# Simple taillights (2)
	var tail_mat := _mat(Color(0.5, 0.02, 0.02), 0.3, Color(1, 0.05, 0.03), 1.5)
	for x in [-0.7, 0.7]:
		_box(_car, Vector3(0.3, 0.12, 0.05), Vector3(x, 1.05, 2.7), tail_mat)


func _build_character(id: String) -> void:
	var c: Dictionary = CHARACTERS[id]
	var root := Node3D.new()
	root.position = c["seat"]
	var holder := Node3D.new()  # bobbing happens on root, seat offset on holder
	root.add_child(holder)
	_car.add_child(root)
	var materials: Array = []
	var limbs: Array = []
	var model: Node3D = null

	var model_path := MODEL_PATH % MODEL_FILES[id][0]
	var rig: HumanRig = null
	if ResourceLoader.exists(model_path):
		model = load(model_path).instantiate()
		model.set_script(HumanRig)  # the game's posing: sitting, arms down
		rig = model as HumanRig
		holder.add_child(model)
		if rig._sk == null:
			rig._ready()  # find the skeleton (the script was added after loading)
		if rig._sk == null and PoseShader.knows(MODEL_FILES[id][0]):
			# No skeleton (a T-pose statue): the pose shader puts the arms down and
			# bends the legs to sit, with the hips on the seat cushion.
			rig = null
			var height: float = MODEL_FILES[id][1]
			var size := height / RIGGED_MODEL_HEIGHT
			size *= 0.94
			var body: Dictionary = PoseShader.BODIES[MODEL_FILES[id][0]]
			model.set_script(null)
			PoseShader.apply(model, MODEL_FILES[id][0], true)
			model.scale = Vector3.ONE * size
			model.rotation.y = PI
			model.position = Vector3(0, 0.92 - float(body.hip_y) * size, 0)
			for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				for i in part.mesh.get_surface_count():
					materials.append(part.get_surface_override_material(i))
		elif rig._sk == null:
			model.queue_free()  # no skeleton and no pose numbers: the simple figure instead
			rig = null
		else:
			var height: float = MODEL_FILES[id][1]
			model.scale = Vector3.ONE * height / RIGGED_MODEL_HEIGHT
			model.rotation.y = PI  # the models face +Z; people in the car face -Z
	if rig == null and materials.is_empty():
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
			limbs.append({"node": thigh, "kind": "thigh"})

			var arm := MeshInstance3D.new()
			var arm_mesh := CapsuleMesh.new()
			arm_mesh.radius = 0.06 * s
			arm_mesh.height = 0.5 * s
			arm.mesh = arm_mesh
			arm.position = Vector3(side * 0.22 * s, 1.12, -0.05)
			arm.rotation_degrees.x = 55.0 if id == "eli" else 25.0
			arm.material_override = body_mat
			holder.add_child(arm)
			limbs.append({"node": arm, "kind": "arm"})

	# Clickable area around the whole figure.
	var hand_gun: Node3D = null
	if id in ["eli", "cole"]:
		hand_gun = _build_hand_gun(holder, -1.0 if id == "eli" else 1.0)

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

	_figures[id] = {"root": root, "holder": holder, "materials": materials, "label": label, "rig": rig,
			"model": model, "limbs": limbs, "mode": "seat", "gun": hand_gun,
			"posed": rig == null and not materials.is_empty() and materials[0] is ShaderMaterial}


## The real (posed) models' faces sit higher than the simple figures' did, so
## the close-up cameras rise to meet them.
const REAL_FACE_LIFT := Vector3(0.0, 0.2, 0.0)


func _face_lift(id: String) -> Vector3:
	return REAL_FACE_LIFT if _figures.has(id) and _figures[id].get("posed", false) else Vector3.ZERO


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 55.0
	add_child(_camera)
	_camera.look_at_from_position(Vector3(-4.2, 1.4, -6.0), MENU_CAM_TARGET)
	_camera.make_current()


# ------------------------------------------------------------------ UI


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_voice = AudioStreamPlayer.new()
	add_child(_voice)

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
	_menu.visibility_changed.connect(func() -> void: shade.visible = _menu.visible)
	if not embedded:  # in the game, main.gd calls enter_opening() when the host presses Play
		_menu.host_requested.connect(func(_port: int) -> void: enter_opening())
		_menu.join_requested.connect(func(_ip: String, _port: int) -> void: enter_opening())

	_build_select_ui(layer)

	_arrival_label = Label.new()
	_arrival_label.text = "BLACKWATER WEATHER STATION\nOCTOBER 22, 2015   04:40 AM"
	_arrival_label.theme = _menu.theme
	_arrival_label.add_theme_font_size_override("font_size", 22)
	_arrival_label.add_theme_color_override("font_color", COLOR_TEXT)
	_arrival_label.position = Vector2(88, 72)
	_arrival_label.modulate.a = 0.0
	layer.add_child(_arrival_label)

	# The cutscenes: black bars, who is talking, the subtitle, and the skip prompt.
	_talk_ui = Control.new()
	_talk_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_talk_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_talk_ui.theme = _menu.theme
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
	_talk_name.anchor_top = 0.735
	_talk_name.anchor_bottom = 0.775
	_talk_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_name.add_theme_font_size_override("font_size", 18)
	_talk_name.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	_talk_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_talk_name.add_theme_constant_override("outline_size", 6)
	_talk_ui.add_child(_talk_name)
	_talk_text = Label.new()
	_talk_text.anchor_left = 0.12
	_talk_text.anchor_right = 0.88
	_talk_text.anchor_top = 0.775
	_talk_text.anchor_bottom = 0.875
	_talk_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_talk_text.add_theme_font_size_override("font_size", 24)
	_talk_text.add_theme_color_override("font_color", COLOR_TEXT)
	_talk_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_talk_text.add_theme_constant_override("outline_size", 8)
	_talk_ui.add_child(_talk_text)
	_skip_label = Label.new()
	_skip_label.anchor_left = 0.4
	_skip_label.anchor_right = 0.98
	_skip_label.anchor_top = 0.93
	_skip_label.anchor_bottom = 0.99
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.add_theme_font_size_override("font_size", 15)
	_skip_label.add_theme_color_override("font_color", COLOR_DIM)
	_talk_ui.add_child(_skip_label)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.hide()
	layer.add_child(_fade)

	# Joining while the others watch the cutscenes.
	_joining_ui = ColorRect.new()
	(_joining_ui as ColorRect).color = Color(0.01, 0.01, 0.015)
	_joining_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_joining_ui.theme = _menu.theme
	_joining_ui.hide()
	layer.add_child(_joining_ui)
	var joining := Label.new()
	joining.text = "JOINING...\n\nThe others are watching the opening.\nYou'll meet them at the car."
	joining.set_anchors_preset(Control.PRESET_FULL_RECT)
	joining.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joining.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	joining.add_theme_font_size_override("font_size", 22)
	joining.add_theme_color_override("font_color", COLOR_TEXT)
	_joining_ui.add_child(joining)


func _build_select_ui(layer: CanvasLayer) -> void:
	_select_ui = Control.new()
	_select_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_select_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_ui.theme = _menu.theme
	_select_ui.hide()
	layer.add_child(_select_ui)

	var header := Label.new()
	header.text = "GRAB YOUR GEAR"
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", COLOR_TEXT)
	header.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	header.add_theme_constant_override("outline_size", 8)
	header.position = Vector2(64, 40)
	_select_ui.add_child(header)

	_hint = Label.new()
	_hint.text = "POINT AT SOMEONE (OR LEFT / RIGHT) TO SEE WHO THEY ARE.  CLICK (OR A) TO PICK THEM."
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", COLOR_DIM)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.position = Vector2(66, 86)
	_select_ui.add_child(_hint)

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -600
	panel.offset_right = -36
	panel.offset_top = 36
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.025, 0.03, 0.82)
	panel.add_theme_stylebox_override("panel", panel_style)
	_select_ui.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 26)
	_info_name.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(_info_name)

	_info_role = Label.new()
	_info_role.add_theme_font_size_override("font_size", 15)
	_info_role.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	vbox.add_child(_info_role)

	for label_name in ["_info_about", "_info_abilities", "_info_quote", "_info_items"]:
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 530
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", COLOR_HIGHLIGHT if label_name == "_info_items" else (COLOR_DIM if label_name == "_info_quote" else COLOR_TEXT))
		vbox.add_child(l)
		set(label_name, l)

	# Big name cards along the bottom: the easy way to pick.
	var cards := HBoxContainer.new()
	cards.anchor_left = 0.5
	cards.anchor_right = 0.5
	cards.anchor_top = 1.0
	cards.anchor_bottom = 1.0
	cards.offset_top = -150
	cards.offset_bottom = -88
	cards.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cards.add_theme_constant_override("separation", 14)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_select_ui.add_child(cards)
	for id: String in CHARACTER_ORDER:
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 62)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 16)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.03, 0.035, 0.035, 0.88)
		normal.content_margin_left = 20
		normal.content_margin_right = 12
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
		card.mouse_entered.connect(func() -> void:
			card.grab_focus()
			_set_hovered(id))
		card.mouse_exited.connect(_unhover.bind(id))
		card.focus_entered.connect(_set_hovered.bind(id))
		card.pressed.connect(_select.bind(id))
		cards.add_child(card)
		_cards[id] = card

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.5
	bottom.anchor_right = 0.5
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -78
	bottom.offset_bottom = -30
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 28)
	_select_ui.add_child(bottom)

	_select_status = Label.new()
	_select_status.add_theme_font_size_override("font_size", 15)
	_select_status.add_theme_color_override("font_color", COLOR_DIM)
	_select_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_select_status.add_theme_constant_override("outline_size", 6)
	bottom.add_child(_select_status)

	_ready_button = Button.new()
	_ready_button.text = "READY"
	_ready_button.custom_minimum_size = Vector2(150, 40)
	_ready_button.add_theme_font_size_override("font_size", 22)
	_ready_button.pressed.connect(_on_ready_pressed)
	bottom.add_child(_ready_button)

	_start_button = Button.new()
	_start_button.text = "START"
	_start_button.custom_minimum_size = Vector2(150, 40)
	_start_button.add_theme_font_size_override("font_size", 22)
	_start_button.pressed.connect(_on_start_pressed)
	bottom.add_child(_start_button)

	# Controller: down from the cards goes to Ready / Start.
	for id: String in CHARACTER_ORDER:
		var card: Button = _cards[id]
		card.focus_neighbor_bottom = card.get_path_to(_ready_button)
	_ready_button.focus_neighbor_top = _ready_button.get_path_to(_cards["eli"])
	_start_button.focus_neighbor_top = _start_button.get_path_to(_cards["cole"])
	_refresh_cards()
