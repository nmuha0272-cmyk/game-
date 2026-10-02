extends OmniLight3D
## Makes a light flicker like an old, dying fluorescent tube.
## Also dims the glowing tube mesh and the buzzing sound along with it.
## A light switch can still turn it fully off by hiding it.

## The glowing tube material (must have emission enabled). Its glow dims with the light.
@export var fixture_material: StandardMaterial3D
## A looping buzz sound that plays while the light is powered.
@export var buzz: AudioStreamPlayer3D
## 0 = almost steady, 1 = barely works.
@export_range(0.0, 1.0) var brokenness := 0.2

var _base_energy := 0.0
var _base_emission := 0.0
var _lit := true
var _timer := 0.0


func _ready() -> void:
	_base_energy = light_energy
	if fixture_material:
		_base_emission = fixture_material.emission_energy_multiplier


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_pick_next_state()

	var powered := visible
	var brightness := 1.0 if (_lit and powered) else 0.0
	light_energy = _base_energy * brightness
	if fixture_material:
		fixture_material.emission_energy_multiplier = _base_emission * brightness
	if buzz and buzz.playing != powered:
		buzz.playing = powered


func _pick_next_state() -> void:
	# When a monster is close, every broken light nearly dies.
	var broken := brokenness
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.global_position.distance_to(global_position) < 9.0:
			broken = maxf(brokenness, 0.85)
	if _lit and randf() < broken:
		# Cut out for a moment. Very broken lights stay dark longer.
		_lit = false
		_timer = randf_range(0.03, 0.12) + randf() * broken * 1.5
	else:
		# Come back on (sometimes only for a split second).
		_lit = true
		_timer = randf_range(0.05, 0.4) if randf() < 0.5 else randf_range(0.5, 4.0 * (1.0 - broken) + 0.5)
		light_energy = _base_energy * randf_range(0.85, 1.0)
