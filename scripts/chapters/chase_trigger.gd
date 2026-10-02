extends "res://scripts/chapters/stinger_trigger.gd"
## Wakes a sleeping monster and sends it after whoever walked in.
## With a cutscene: everyone watches it rise and stare first, then it charges.

@export var monster: Monster
@export var cutscene: Cutscene


func _triggered(by: Player) -> void:
	if cutscene:
		cutscene.server_play()
		monster.wake(by, cutscene.total_time() + 0.4)
	else:
		monster.wake(by)
