extends AnimatableBody3D
## Something big a puzzle moves, like a gate that lifts up (a PuzzleGate
## output). Moves by `open_offset` when active, and back when not.

@export var open_offset := Vector3(0, 1.2, 0)
@export var move_time := 0.8
@export var sound: AudioStreamPlayer3D

var is_open := false

var _closed_position := Vector3.ZERO


func _ready() -> void:
	_closed_position = position


func puzzle_set(active: bool) -> void:
	if multiplayer.is_server() and active != is_open:
		_set_open.rpc(active)


@rpc("authority", "call_local", "reliable")
func _set_open(value: bool) -> void:
	is_open = value
	var target := _closed_position + (open_offset if value else Vector3.ZERO)
	create_tween().tween_property(self, "position", target, move_time).set_trans(Tween.TRANS_SINE)
	if sound:
		sound.play()
