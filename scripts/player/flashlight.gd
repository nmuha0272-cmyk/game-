class_name Flashlight
extends SpotLight3D
## Turns the flashlight on and off with the flashlight key (F).

signal switched(is_on: bool)

@export var starts_on := false


func _ready() -> void:
	visible = starts_on


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight"):
		set_on(not visible)


func set_on(value: bool) -> void:
	visible = value
	switched.emit(value)
