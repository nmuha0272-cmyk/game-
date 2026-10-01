extends PuzzleInput
## A button, or a key in a launch console. Pressing it makes it active for a
## few seconds (0 = stays on forever). Two key consoles that must be turned
## "at the same time" are two of these with a short active time.

@export var active_time := 3.0
## Solo mode: stays on at least this long, so one player can run between
## two launch keys.
@export var solo_active_time := 10.0

var _time_left := 0.0


func can_interact(_by: Player) -> bool:
	return enabled and not is_active


func _on_interact(_by: Player) -> void:
	if not requirement_met():
		return
	_time_left = active_time
	if GameState.is_solo() and active_time > 0.0:
		_time_left = maxf(active_time, solo_active_time)
	server_set_active(true)


func _process(delta: float) -> void:
	if multiplayer.is_server() and is_active and active_time > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			server_set_active(false)
