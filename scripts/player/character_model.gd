class_name CharacterModel
extends Node3D
## The body other players see: a sculpted model (from tools/make_characters.py)
## made of parts, so the arms and legs can swing when the player walks.
## Your own body is invisible to you (you only see its shadow), because the
## camera is inside your head.

const MODEL_FOLDER := "res://assets/models/"
const MODEL_NAMES := {
	Characters.Id.SON: "son",
	Characters.Id.JOURNALIST: "journalist",
	Characters.Id.ENGINEER: "engineer",
	Characters.Id.GUARD: "guard",
}

## How far the arms and legs swing (degrees) at walking speed.
@export var swing_degrees := 28.0

var _limbs := {}  # "arm_l" -> pivot Node3D
var _phase := 0.0
var _rigs := {}


func setup(character: int, is_local: bool) -> void:
	for child in get_children():
		child.queue_free()
	_limbs.clear()
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


func _add_part(parent: Node3D, file: String, is_local: bool) -> void:
	var part := MeshInstance3D.new()
	part.mesh = load(MODEL_FOLDER + file + ".obj")
	part.name = file
	if is_local:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	parent.add_child(part)


func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody3D
	if body == null or _limbs.is_empty():
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
