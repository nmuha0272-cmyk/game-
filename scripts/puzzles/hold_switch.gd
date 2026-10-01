extends PuzzleInput
## Something one player has to keep holding: a heavy vent cover, a breaker
## switch, a safelight switch... Press E to start holding it, E again to let go.
## Holding it means standing still: step away (or get knocked down) and you
## let go. You can still look around and press things within reach.
## Active while held. This is what stops one player doing a puzzle alone.

## How far the holder can move from where they started holding.
@export var max_distance := 0.8
## How close you must be to grab it.
@export var reach := 2.5

## Network ID of whoever is holding it (0 = nobody).
var holder_id := 0

var _hold_start := Vector3.ZERO
var _hold_age := 0.0


func get_prompt(by: Player) -> String:
	var by_id := by.name.to_int()
	if holder_id == by_id:
		return "[E] Let go"
	if holder_id != 0:
		return "%s is holding it" % GameState.get_player_name(holder_id)
	return "[E] " + prompt_text


func _on_interact(by: Player) -> void:
	var by_id := by.name.to_int()
	if holder_id == 0:
		if by.global_position.distance_to(global_position) > reach:
			return
		_hold_start = by.global_position
		_hold_age = 0.0
		_set_holder.rpc(by_id)
		server_set_active(true)
	elif holder_id == by_id:
		_release()


func _process(delta: float) -> void:
	if not multiplayer.is_server() or holder_id == 0:
		return
	var holder := Player.find(get_tree(), holder_id)
	# For the first moment, keep updating where they stand: their latest
	# position may still be on its way over the network.
	_hold_age += delta
	if holder and _hold_age < 0.5:
		_hold_start = holder.global_position
	if holder == null or holder.is_downed \
			or holder.global_position.distance_to(_hold_start) > max_distance:
		_release()


func _release() -> void:
	_set_holder.rpc(0)
	server_set_active(false)


@rpc("authority", "call_local", "reliable")
func _set_holder(id: int) -> void:
	holder_id = id
