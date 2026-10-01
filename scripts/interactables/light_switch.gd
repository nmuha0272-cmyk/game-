extends Interactable
## A wall switch that turns a light on and off for everyone.

@export var light: Light3D

@onready var lever: Node3D = $Lever


func _ready() -> void:
	_update_lever()


func _on_interact(_by: Player) -> void:
	if light:
		_set_light_on.rpc(not light.visible)


@rpc("authority", "call_local", "reliable")
func _set_light_on(is_on: bool) -> void:
	light.visible = is_on
	_update_lever()


## Lever points up when the light is on, down when it's off.
func _update_lever() -> void:
	var is_on := light != null and light.visible
	lever.rotation_degrees.x = -30.0 if is_on else 30.0
