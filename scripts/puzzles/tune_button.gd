extends Interactable
## The - or + button on a radio.

@export var direction := 1


func get_prompt(_by: Player) -> String:
	return "[E] Tune %s" % ("up (+)" if direction > 0 else "down (-)")


func _on_interact(_by: Player) -> void:
	owner.server_tune(direction)
