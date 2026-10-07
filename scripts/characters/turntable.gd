extends Node3D
## Slowly turns the model around, so you can see it from every side.

@export var degrees_per_second := 20.0


func _process(delta: float) -> void:
	rotate_y(deg_to_rad(degrees_per_second) * delta)
