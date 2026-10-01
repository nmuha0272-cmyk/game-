extends "res://scripts/chapters/stinger_trigger.gd"
## Wakes a sleeping monster and sends it after whoever walked in.

@export var monster: Monster


func _triggered(by: Player) -> void:
	monster.wake(by)
