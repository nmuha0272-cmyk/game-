class_name HumanRig
extends BodyRig
## The players' bodies (models made in a T-pose): arms down at the sides,
## walking and running, crouching, breathing, and looking up and down.

const SIDE := Vector3(1, 0, 0)  # turning around this tips things forward/back
const TWIST := Vector3(0, 1, 0)
const ROLL := Vector3(0, 0, 1)


## phase: where in the step. amount: 0 standing, 1 walking, 2 running.
## crouch: 0..1. look: head up (+) or down (-) in degrees. breath: -1..1.
func set_pose(phase: float, amount: float, crouch: float, look: float, breath: float) -> void:
	if _sk == null:
		return
	_reset()
	var walk := clampf(amount, 0.0, 1.0)
	var run := clampf(amount - 1.0, 0.0, 1.0)
	var s := sin(phase)
	var lift_l := maxf(0.0, -cos(phase))
	var lift_r := maxf(0.0, cos(phase))
	var stride := walk * (24.0 + 14.0 * run)
	# The body dips on each step and leans forward when running or crouching.
	_drop(absf(cos(phase)) * 0.008 * walk + 0.12 * crouch)
	_turn("Hips", TWIST, s * 6.0 * walk)
	_turn("Spine", SIDE, 4.0 * walk + 10.0 * run + 18.0 * crouch + breath * 1.2)
	_turn("Spine1", TWIST, -s * 7.0 * walk)
	_turn("Spine2", SIDE, breath * 1.5)
	_turn("Neck", SIDE, -look * 0.4 - 6.0 * run - 10.0 * crouch)
	_turn("Head", SIDE, -look * 0.4)
	# Legs swing; the knee bends as each foot comes forward.
	_turn("LeftUpLeg", SIDE, -s * stride - 70.0 * crouch)
	_turn("RightUpLeg", SIDE, s * stride - 70.0 * crouch)
	_turn("LeftLeg", SIDE, lift_l * (30.0 + 35.0 * run) * walk + 110.0 * crouch)
	_turn("RightLeg", SIDE, lift_r * (30.0 + 35.0 * run) * walk + 110.0 * crouch)
	_turn("LeftFoot", SIDE, -lift_l * 15.0 * walk - 40.0 * crouch)
	_turn("RightFoot", SIDE, -lift_r * 15.0 * walk - 40.0 * crouch)
	# Arms come down from the T-pose, then swing against the legs.
	_turn("LeftShoulder", ROLL, -6.0)
	_turn("RightShoulder", ROLL, 6.0)
	_turn("LeftArm", ROLL, -72.0 + breath * 1.0)
	_turn("RightArm", ROLL, 72.0 - breath * 1.0)
	var arm := walk * (18.0 + 22.0 * run)
	_turn("LeftArm", SIDE, s * arm - 8.0 * crouch)
	_turn("RightArm", SIDE, -s * arm - 8.0 * crouch)
	_turn("LeftForeArm", SIDE, -12.0 - 35.0 * run - maxf(0.0, s) * 15.0 * walk)
	_turn("RightForeArm", SIDE, -12.0 - 35.0 * run - maxf(0.0, -s) * 15.0 * walk)
