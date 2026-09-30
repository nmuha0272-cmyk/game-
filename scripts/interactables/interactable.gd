class_name Interactable
extends StaticBody3D
## Base script for anything the player can look at and press E on.
## Make a new script that `extends Interactable` and override `_on_interact`.

signal interacted(by: Node)

## Shown on screen as "[E] <prompt_text>".
@export var prompt_text := "Interact"
@export var enabled := true


func interact(by: Node) -> void:
	if not enabled:
		return
	_on_interact(by)
	interacted.emit(by)


## Child scripts replace this with what the object should do.
func _on_interact(_by: Node) -> void:
	pass
