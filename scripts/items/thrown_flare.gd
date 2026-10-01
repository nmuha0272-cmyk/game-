extends RigidBody3D
## A lit flare that was thrown. It burns red for 10 seconds, lighting the
## area, and pulls nearby monsters toward it (great for covering teammates).

@export var burn_time := 10.0
## Monsters this close come to stare at the flare.
@export var distract_radius := 15.0

var _time_left := 0.0
var _distract_timer := 0.0
var _base_energy := 0.0

@onready var _light: OmniLight3D = $Light
@onready var _hiss: AudioStreamPlayer3D = $Hiss


func _ready() -> void:
	freeze = not multiplayer.is_server()
	_time_left = burn_time
	_base_energy = _light.light_energy


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		_light.light_energy = _base_energy * randf_range(0.75, 1.1)
	else:
		_light.visible = false
		_hiss.stop()
		if multiplayer.is_server() and _time_left < -20.0:
			queue_free()  # Remove the burnt-out flare after a while.
		return

	if multiplayer.is_server():
		_distract_timer -= delta
		if _distract_timer <= 0.0:
			_distract_timer = 1.0
			for monster: Node3D in get_tree().get_nodes_in_group("monsters"):
				if monster.global_position.distance_to(global_position) <= distract_radius:
					monster.distract(global_position, _time_left)
