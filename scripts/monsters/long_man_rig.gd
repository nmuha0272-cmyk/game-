class_name LongManRig
extends BodyRig
## Moves the bones of the Long Man model (the uploaded creature) by code:
## walking, crawling on all fours, and the head twitch. Every turn is in the
## model's own space: X goes across him, Y up, Z out of his chest.

const SIDE := Vector3(1, 0, 0)
const TWIST := Vector3(0, 1, 0)
const ROLL := Vector3(0, 0, 1)


## phase: where in the step he is. amount: 0 standing still, 1 full speed.
## crawl: 0 standing, 1 on all fours. head_roll: head tilt in degrees.
## look_up: lifts his face (degrees), for the jump scare.
## look_yaw: turns his head toward you (degrees, + = his left).
## time: seconds, for the slow sway when he stands still.
func set_pose(phase: float, amount: float, crawl: float, head_roll: float, breath: float, look_up := 0.0, look_yaw := 0.0, time := 0.0) -> void:
	if _sk == null:
		return
	_reset()
	var s := sin(phase) * amount
	var lift_a := maxf(0.0, cos(phase)) * amount
	var lift_b := maxf(0.0, -cos(phase)) * amount
	var idle := 1.0 - clampf(amount * 2.0, 0.0, 1.0)
	var sway := sin(time * 0.9) * idle
	_drop(0.07 * crawl + absf(sin(phase)) * 0.01 * amount)  # hands and feet down on the floor
	# Bend over onto the hands, legs folding under him like a spider.
	_turn("Hips", SIDE, 62.0 * crawl)
	_turn("Hips", ROLL, sway * 4.0 + s * 5.0)
	_turn("Spine", SIDE, 8.0 * crawl + breath * 2.0)
	_turn("Spine", TWIST, s * 9.0)
	_turn("Spine1", ROLL, -sway * 5.0 - s * 4.0)
	_turn("Spine2", SIDE, breath * 2.5 + 6.0 * idle * (1.0 - crawl))
	# Shoulders hunch up and roll with each reach.
	_turn("LeftShoulder", ROLL, 10.0 + lift_a * 12.0)
	_turn("RightShoulder", ROLL, -10.0 - lift_b * 12.0)
	_turn("Neck", SIDE, -40.0 * crawl - look_up * 0.5)
	_turn("Neck", TWIST, look_yaw * 0.5)
	_turn("Head", TWIST, look_yaw * 0.5)
	_turn("Head", SIDE, -look_up * 0.5 - 25.0 * crawl)
	_turn("Head", ROLL, head_roll)
	# Legs: left with right arm, then right with left arm.
	_turn("LeftUpLeg", SIDE, -58.0 * crawl - 28.0 * s)
	_turn("RightUpLeg", SIDE, -58.0 * crawl + 28.0 * s)
	_turn("LeftUpLeg", ROLL, -12.0 * crawl)
	_turn("RightUpLeg", ROLL, 12.0 * crawl)
	_turn("LeftLeg", SIDE, 35.0 * crawl + 45.0 * lift_b)
	_turn("RightLeg", SIDE, 35.0 * crawl + 45.0 * lift_a)
	_turn("LeftFoot", SIDE, -20.0 * lift_b)
	_turn("RightFoot", SIDE, -20.0 * lift_a)
	# Arms reach forward and down to the floor and claw along, elbows out.
	_turn("LeftArm", SIDE, -45.0 * crawl + 30.0 * s - 25.0 * lift_a + sway * 6.0)
	_turn("RightArm", SIDE, -45.0 * crawl - 30.0 * s - 25.0 * lift_b - sway * 6.0)
	_turn("LeftArm", ROLL, 10.0 * crawl)
	_turn("RightArm", ROLL, -10.0 * crawl)
	_turn("LeftForeArm", SIDE, -25.0 * lift_a - 10.0 * idle)
	_turn("RightForeArm", SIDE, -25.0 * lift_b - 10.0 * idle)
	# Claws curl in as a hand lifts, and twitch when he stands still.
	var twitch := sin(time * 7.0) * sin(time * 2.3) * idle
	_turn("LeftHand", SIDE, -30.0 * lift_a - 12.0 * twitch)
	_turn("RightHand", SIDE, -30.0 * lift_b + 12.0 * twitch)
