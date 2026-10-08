class_name CharacterModel
extends Node3D
## The body other players see. If the character has a real model with a
## skeleton (assets/models/characters/, from tools/make_rigged_character.py)
## its bones are moved (HumanRig). Otherwise it's the old sculpted model
## (from tools/make_characters.py) made of parts that swing.
## Your own body is invisible to you (you only see its shadow), because the
## camera is inside your head.

const MODEL_FOLDER := "res://assets/models/"
const MODEL_NAMES := {
	Characters.Id.SON: "son",
	Characters.Id.JOURNALIST: "journalist",
	Characters.Id.ENGINEER: "engineer",
	Characters.Id.GUARD: "guard",
}

## The models with skeletons, and how tall each person is (meters).
const RIGGED_FOLDER := "res://assets/models/characters/"
const RIGGED := {
	Characters.Id.SON: ["eli", 1.78],
	Characters.Id.JOURNALIST: ["journalist", 1.68],
	Characters.Id.ENGINEER: ["engineer", 1.75],
	Characters.Id.GUARD: ["frank", 1.9],
}
## The rigged models are this tall (in their own units).
const RIGGED_MODEL_HEIGHT := 0.98

## How far the arms and legs swing (degrees) at walking speed.
@export var swing_degrees := 28.0

var _limbs := {}  # "arm_l" -> pivot Node3D
var _phase := 0.0
var _rigs := {}
var _rig: HumanRig
var _rig_scale := 1.0


func setup(character: int, is_local: bool) -> void:
	for child in get_children():
		child.queue_free()
	_limbs.clear()
	_rig = null
	if RIGGED.has(character) and ResourceLoader.exists(RIGGED_FOLDER + RIGGED[character][0] + ".glb"):
		_setup_rigged(character, is_local)
		return
	var model: String = MODEL_NAMES.get(character, "son")
	if _rigs.is_empty():
		_rigs = JSON.parse_string(FileAccess.get_file_as_string(MODEL_FOLDER + "rigs.json"))
	var rig: Dictionary = _rigs[model]
	_add_part(self, model + "_body", is_local)
	for limb in ["arm_l", "arm_r", "leg_l", "leg_r"]:
		var pivot := Node3D.new()
		pivot.name = limb.capitalize().replace(" ", "")
		var key: String = ("shoulder_" if limb.begins_with("arm") else "hip_") + limb.right(1)
		var p: Array = rig[key]
		pivot.position = Vector3(p[0], p[1], p[2])
		add_child(pivot)
		_add_part(pivot, "%s_%s" % [model, limb], is_local)
		_limbs[limb] = pivot


func _setup_rigged(character: int, is_local: bool) -> void:
	var info: Array = RIGGED[character]
	var model := (load(RIGGED_FOLDER + info[0] + ".glb") as PackedScene).instantiate()
	model.set_script(HumanRig)
	_rig = model as HumanRig
	_rig_scale = info[1] / RIGGED_MODEL_HEIGHT
	_rig.scale = Vector3.ONE * _rig_scale
	_rig.rotation.y = PI  # the models face +Z; players face -Z
	add_child(_rig)
	if is_local:
		for part: MeshInstance3D in _rig.find_children("*", "MeshInstance3D", true, false):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _add_part(parent: Node3D, file: String, is_local: bool) -> void:
	var part := MeshInstance3D.new()
	part.mesh = load(MODEL_FOLDER + file + ".obj")
	part.name = file
	if is_local:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	parent.add_child(part)


func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody3D
	if body == null:
		return
	if _rig:
		_update_rig(body, delta)
		return
	if _limbs.is_empty():
		return
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var lying := absf(rotation_degrees.x) > 45.0
	if speed > 0.3 and not lying:
		_phase += delta * speed * 2.6
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, clampf(delta * 6.0, 0.0, 1.0))
	var amount := clampf(speed / 3.5, 0.0, 1.6) * swing_degrees
	var swing := sin(_phase) * amount
	_limbs.leg_l.rotation_degrees.x = swing
	_limbs.leg_r.rotation_degrees.x = -swing
	_limbs.arm_l.rotation_degrees.x = -swing * 0.8
	_limbs.arm_r.rotation_degrees.x = swing * 0.8


## Moves the bones: walking/running from the speed, crouching from how much
## the player squashed this node (the rig is un-squashed so it bends instead).
func _update_rig(body: CharacterBody3D, delta: float) -> void:
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var lying := absf(rotation_degrees.x) > 45.0
	if lying:
		speed = 0.0
	if speed > 0.3:
		_phase += delta * speed * 2.6
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, clampf(delta * 6.0, 0.0, 1.0))
	var amount := clampf(speed / 3.5, 0.0, 1.0) + clampf((speed - 3.5) / 2.5, 0.0, 1.0)
	var crouch := clampf((1.0 - scale.y) / 0.44, 0.0, 1.0)
	_rig.scale = Vector3(_rig_scale, _rig_scale / maxf(scale.y, 0.1), _rig_scale)
	var head := body.get_node_or_null("Head") as Node3D
	var look := head.rotation_degrees.x if head else 0.0
	var breath := sin(Time.get_ticks_msec() / 1000.0 * 1.6)
	_rig.set_pose(_phase, amount, crouch, look, breath)
