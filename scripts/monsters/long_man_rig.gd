class_name LongManRig
extends Node3D
## Moves the bones of the Long Man model (the uploaded creature) by code:
## walking, crawling on all fours, and the head twitch. Every turn is in the
## model's own space: X goes across him, Y up, Z out of his chest.

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


func _turn(bone: String, axis: Vector3, degrees: float) -> void:
	if not _bones.has(bone) or is_zero_approx(degrees):
		return
	var b: int = _bones[bone]
	var p := _sk.get_bone_parent(b)
	var parent_rot := _sk.get_bone_global_pose(p).basis.get_rotation_quaternion() if p >= 0 else Quaternion()
	var local_rest := _sk.get_bone_rest(b).basis.get_rotation_quaternion()
	var turn := Quaternion(axis, deg_to_rad(degrees))
	_sk.set_bone_pose_rotation(b, parent_rot.inverse() * turn * parent_rot * _sk.get_bone_pose_rotation(b))


## Puts every bone back to how the model was made.
func _reset() -> void:
	for i in _sk.get_bone_count():
		_sk.set_bone_pose_rotation(i, _sk.get_bone_rest(i).basis.get_rotation_quaternion())


## phase: where in the step he is. amount: 0 standing still, 1 full speed.
## crawl: 0 standing, 1 on all fours. head_roll: head tilt in degrees.
## look_up: lifts his face (degrees), for the jump scare.
func set_pose(phase: float, amount: float, crawl: float, head_roll: float, breath: float, look_up := 0.0) -> void:
	if _sk == null:
		return
	_reset()
	_sk.position.y = _sk_y - 0.07 * crawl  # hands and feet down on the floor
	var s := sin(phase) * amount
	var lift_a := maxf(0.0, cos(phase)) * amount
	var lift_b := maxf(0.0, -cos(phase)) * amount
	# Bend over onto the hands, legs folding under him like a spider.
	_turn("Hips", Vector3.RIGHT, 62.0 * crawl)
	_turn("Spine", Vector3.RIGHT, 8.0 * crawl + breath * 2.0)
	_turn("Spine2", Vector3.RIGHT, breath * 2.0)
	_turn("Neck", Vector3.RIGHT, -40.0 * crawl - look_up * 0.5)
	_turn("Head", Vector3.RIGHT, -look_up * 0.5)
	_turn("Head", Vector3.RIGHT, -25.0 * crawl)
	_turn("Head", Vector3.FORWARD, head_roll)
	# Legs: left with right arm, then right with left arm.
	_turn("LeftUpLeg", Vector3.RIGHT, -58.0 * crawl - 28.0 * s)
	_turn("RightUpLeg", Vector3.RIGHT, -58.0 * crawl + 28.0 * s)
	_turn("LeftLeg", Vector3.RIGHT, 35.0 * crawl + 35.0 * lift_b)
	_turn("RightLeg", Vector3.RIGHT, 35.0 * crawl + 35.0 * lift_a)
	# Arms reach forward and down to the floor and claw along.
	_turn("LeftArm", Vector3.RIGHT, -45.0 * crawl + 30.0 * s - 20.0 * lift_a)
	_turn("RightArm", Vector3.RIGHT, -45.0 * crawl - 30.0 * s - 20.0 * lift_b)
	_turn("LeftForeArm", Vector3.RIGHT, -20.0 * lift_a)
	_turn("RightForeArm", Vector3.RIGHT, -20.0 * lift_b)


## Where his head is, in this node's space (for the jump scare).
func head_position() -> Vector3:
	if _sk == null or not _bones.has("Head"):
		return Vector3(0, 0.85, 0)
	var t := global_transform.affine_inverse() * _sk.global_transform * _sk.get_bone_global_pose(_bones["Head"])
	return t.origin
