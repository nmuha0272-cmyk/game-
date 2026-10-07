extends PuzzleInput
## A button, or a key in a launch console. Pressing it makes it active for a
## few seconds (0 = stays on forever). Two key consoles that must be turned
## "at the same time" are two of these with a short active time.

@export var active_time := 3.0

var _time_left := 0.0


func can_interact(_by: Player) -> bool:
	return enabled and not is_active


func _on_interact(_by: Player) -> void:
	if not requirement_met():
		return
	# Solo: the "at the same time" puzzles become a timed run between the
	# two buttons, so give a comfortable window.
	_time_left = maxf(active_time, 20.0) if GameState.is_solo() else active_time
	server_set_active(true)


func _process(delta: float) -> void:
	if multiplayer.is_server() and is_active and active_time > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			server_set_active(false)
