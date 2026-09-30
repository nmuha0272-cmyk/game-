extends AudioStreamPlayer3D
## Every so often, plays a random creepy sound from a random spot nearby,
## so players hear clanks and creaks coming from different directions.

@export var sounds: Array[AudioStream] = []
## Size of the box (centered on where this node starts) sounds can come from.
@export var area_size := Vector3(20.0, 3.0, 28.0)
@export var min_delay := 8.0
@export var max_delay := 20.0

var _center := Vector3.ZERO
var _timer := 0.0


func _ready() -> void:
	_center = position
	_timer = randf_range(3.0, min_delay)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_play_random_sound()
		_timer = randf_range(min_delay, max_delay)


func _play_random_sound() -> void:
	if sounds.is_empty():
		return
	var offset := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * area_size
	position = _center + offset
	stream = sounds.pick_random()
	pitch_scale = randf_range(0.8, 1.1)
	play()
