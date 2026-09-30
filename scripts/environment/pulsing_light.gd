extends OmniLight3D
## Slowly pulses a light brighter and dimmer, like an emergency beacon.

## The glowing lamp material (must have emission enabled). Its glow dims with the light.
@export var fixture_material: StandardMaterial3D
## Pulses per second.
@export var pulse_speed := 0.5
## Brightness at the dimmest point, as a fraction of full brightness.
@export_range(0.0, 1.0) var min_brightness := 0.1

var _base_energy := 0.0
var _base_emission := 0.0
var _time := 0.0


func _ready() -> void:
	_base_energy = light_energy
	if fixture_material:
		_base_emission = fixture_material.emission_energy_multiplier


func _process(delta: float) -> void:
	_time += delta
	# sin goes -1..1, turn that into 0..1.
	var wave := (sin(_time * pulse_speed * TAU) + 1.0) / 2.0
	var brightness := lerpf(min_brightness, 1.0, wave * wave)
	light_energy = _base_energy * brightness
	if fixture_material:
		fixture_material.emission_energy_multiplier = _base_emission * brightness
