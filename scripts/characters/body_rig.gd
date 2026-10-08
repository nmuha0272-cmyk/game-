class_name BodyRig
extends Node3D
## A model with a Mixamo-style skeleton (bones named mixamorig_Hips, ...),
## moved by code. Every turn is in the model's own space: X goes across the
## body (to its left), Y up, Z out of its chest.

var _sk: Skeleton3D
var _bones := {}
var _sk_y := 0.0


func _ready() -> void:
	var found := find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return
	_sk = found[0]
	_sk_y = _sk.position.y
	for i in _sk.get_bone_count():
		_bones[_sk.get_bone_name(i).trim_prefix("mixamorig_").trim_prefix("mixamorig:")] = i


## Turns one bone (and everything hanging off it) around an axis.
func _turn(bone: String, axis: Vector3, degrees: float) -> void:
	if not _bones.has(bone) or is_zero_approx(degrees):
		return
	var b: int = _bones[bone]
	var p := _sk.get_bone_parent(b)
	var parent_rot := _sk.get_bone_global_pose(p).basis.get_rotation_quaternion() if p >= 0 else Quaternion()
	var turn := Quaternion(axis, deg_to_rad(degrees))
	_sk.set_bone_pose_rotation(b, parent_rot.inverse() * turn * parent_rot * _sk.get_bone_pose_rotation(b))


## Puts every bone back to how the model was made.
func _reset() -> void:
	for i in _sk.get_bone_count():
		_sk.set_bone_pose_rotation(i, _sk.get_bone_rest(i).basis.get_rotation_quaternion())


## Moves the whole body up or down (model units).
func _drop(amount: float) -> void:
	_sk.position.y = _sk_y - amount


## Where the head is, in this node's space.
func head_position() -> Vector3:
	if _sk == null or not _bones.has("Head"):
		return Vector3(0, 0.85, 0)
	var t := global_transform.affine_inverse() * _sk.global_transform * _sk.get_bone_global_pose(_bones["Head"])
	return t.origin
