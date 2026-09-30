extends Interactable
## A wall switch that turns a light on and off.

@export var light: Light3D

@onready var lever: Node3D = $Lever


func _ready() -> void:
	_update_lever()


func _on_interact(_by: Node) -> void:
	if light:
		light.visible = not light.visible
	_update_lever()


## Lever points up when the light is on, down when it's off.
func _update_lever() -> void:
	var is_on := light != null and light.visible
	lever.rotation_degrees.x = -30.0 if is_on else 30.0
