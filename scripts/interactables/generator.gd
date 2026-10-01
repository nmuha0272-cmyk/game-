extends Repairable
## A broken generator. Once the Engineer repairs it, its lamp turns on,
## the warning light goes from red to green, and it starts humming.

@export var lamp: Light3D
@export var indicator_material: StandardMaterial3D

@onready var _hum: AudioStreamPlayer3D = $Hum


func _ready() -> void:
	if lamp:
		lamp.visible = false


func _on_repaired() -> void:
	if lamp:
		lamp.visible = true
	if indicator_material:
		indicator_material.emission = Color(0.1, 1.0, 0.2)
		indicator_material.albedo_color = Color(0.1, 0.6, 0.15)
	_hum.play()
