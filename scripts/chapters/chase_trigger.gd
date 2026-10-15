extends "res://scripts/chapters/stinger_trigger.gd"
## Wakes a sleeping monster and sends it after whoever walked in.
## With a cutscene: everyone watches it rise and stare first, then it charges.

@export var monster: Monster
@export var cutscene: Cutscene
## Optional: the monster jumps to this spot first (somewhere behind the
## players) and gets a moment to roar before it runs at them.
@export var burst_point: Marker3D
@export var burst_roar := 1.2


func _triggered(by: Player) -> void:
	if burst_point:
		monster.global_position = burst_point.global_position
		monster.velocity = Vector3.ZERO
		monster.wake(by, burst_roar)
	elif cutscene:
		cutscene.server_play()
		monster.wake(by, cutscene.total_time() + 0.4)
	else:
		monster.wake(by)
