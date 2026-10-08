extends Interactable
## One key on a keypad ("0" to "9", "CLR" or "ENT").

@export var key := "1"


func get_prompt(_by: Player) -> String:
	return "[E] Use the keypad"


## Runs on the computer of the player who pressed E: the keypad pops up
## on their screen, and they type the code there.
func interact(by: Player) -> void:
	if can_interact(by) and not owner.is_active:
		owner.open_ui()


func _on_interact(_by: Player) -> void:
	owner.server_press(key)
