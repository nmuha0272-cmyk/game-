extends Node3D
## A group of lights that turn on when a puzzle is solved (a PuzzleGate
## output), like the lights coming back after the power is restored.
## Sounds in the group (like a generator's hum) start and stop with them.


func _ready() -> void:
	_show(false)


func puzzle_set(active: bool) -> void:
	if multiplayer.is_server():
		_set_on.rpc(active)


@rpc("authority", "call_local", "reliable")
func _set_on(value: bool) -> void:
	_show(value)


func _show(value: bool) -> void:
	for child in get_children():
		if child is Light3D:
			child.visible = value
		elif child is AudioStreamPlayer3D:
			if value and not child.playing:
				child.play()
			elif not value:
				child.stop()
