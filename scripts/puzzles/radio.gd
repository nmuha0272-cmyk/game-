extends Node3D
## An old radio. Tune it with the - and + buttons. When it's on the right
## frequency (shown on a chart somewhere else) it becomes active and stays
## solved. With rotate_every set, the right frequency drifts every few
## seconds, so someone has to keep reading the chart out loud.

signal active_changed(active: bool)
signal code_changed(code: String)

@export var min_frequency := 90.0
@export var max_frequency := 99.5
@export var step := 0.5
@export var rotate_every := 0.0

var is_active := false
var frequency := 90.0
var target := 95.0

var _rotate_timer := 0.0

@onready var display: Label3D = $Display
@onready var static_noise: AudioStreamPlayer3D = $Static


func _ready() -> void:
	frequency = min_frequency
	if multiplayer.is_server():
		_set_target(_random_frequency())
		_rotate_timer = rotate_every
	else:
		_request_state.rpc_id(1)
	_update_display()


func get_display_code() -> String:
	return "%.1f MHz" % target


## Host only: a tune button was pressed (+1 or -1).
func server_tune(direction: int) -> void:
	if not multiplayer.is_server() or is_active:
		return
	var steps := int(round((max_frequency - min_frequency) / step)) + 1
	var index := int(round((frequency - min_frequency) / step))
	index = posmod(index + direction, steps)
	_set_frequency.rpc(min_frequency + index * step)
	if is_equal_approx(frequency, target):
		_set_active.rpc(true)


func _process(delta: float) -> void:
	# Closer to the right frequency = less static.
	var off := absf(frequency - target)
	static_noise.volume_db = -30.0 if is_active else lerpf(-18.0, -2.0, clampf(off / 3.0, 0.0, 1.0))
	if multiplayer.is_server() and rotate_every > 0.0 and not is_active:
		_rotate_timer -= delta
		if _rotate_timer <= 0.0:
			_rotate_timer = rotate_every
			_set_target.rpc(_random_frequency())


func _random_frequency() -> float:
	var steps := int(round((max_frequency - min_frequency) / step))
	var value := frequency
	while is_equal_approx(value, frequency):
		value = min_frequency + (randi() % (steps + 1)) * step
	return value


@rpc("any_peer", "reliable")
func _request_state() -> void:
	if multiplayer.is_server():
		var id := multiplayer.get_remote_sender_id()
		_set_target.rpc_id(id, target)
		_set_frequency.rpc_id(id, frequency)
		if is_active:
			_set_active.rpc_id(id, true)


@rpc("authority", "call_local", "reliable")
func _set_target(value: float) -> void:
	target = value
	code_changed.emit(get_display_code())


@rpc("authority", "call_local", "reliable")
func _set_frequency(value: float) -> void:
	frequency = value
	_update_display()


@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	is_active = value
	_update_display()
	active_changed.emit(value)


func _update_display() -> void:
	display.text = "%.1f MHz" % frequency
	display.modulate = Color(0.2, 1, 0.3) if is_active else Color(1, 0.75, 0.3)
