extends PuzzleInput
## A lever that flips between on and off. With one_way on, it stays on.

@export var one_way := false


func can_interact(_by: Player) -> bool:
	return enabled and not (one_way and is_active)


func _on_interact(_by: Player) -> void:
	if requirement_met():
		server_set_active(not is_active)
