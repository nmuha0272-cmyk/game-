extends Interactable
## One key on a keypad ("0" to "9", "CLR" or "ENT").

@export var key := "1"


func get_prompt(_by: Player) -> String:
	return "[E] Press %s" % key


func _on_interact(_by: Player) -> void:
	owner.server_press(key)
