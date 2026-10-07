class_name HoldSwitch
extends PuzzleInput
## Something one player has to keep holding: a heavy vent cover, a breaker
## switch, a safelight switch... Press E to start holding it, E again to let go.
## Holding it means standing still: step away (or get knocked down) and you
## let go. You can still look around and press things within reach.
## Active while held. This is what stops one player doing a puzzle alone —
## except when playing solo, where it latches on instead (see _on_interact).

## How far the holder can move from where they started holding.
@export var max_distance := 0.8
## How close you must be to grab it.
@export var reach := 2.5
## Only this character can hold it (-1 = anyone), like the Guard lifting a
## heavy gate. BACKUP: if that character isn't in the team, anyone can.
@export var required_character := -1

## Network ID of whoever is holding it (0 = nobody).
var holder_id := 0

var _hold_start := Vector3.ZERO
var _hold_age := 0.0


func _ready() -> void:
	super()
	add_to_group("hold_switches")


## The switch this player is holding, or null. Lets them let go with E even
## when they aren't looking at it any more (a lifted vent cover is up high).
static func held_by(player: Player) -> Node:
	for hold_switch in player.get_tree().get_nodes_in_group("hold_switches"):
		if hold_switch.holder_id == player.name.to_int():
			return hold_switch
	return null


func _allowed(by: Player) -> bool:
	return required_character < 0 or by.character == required_character \
			or not GameState.team_has(required_character)


func get_prompt(by: Player) -> String:
	if holder_id == 0 and not _allowed(by):
		return "Too heavy. Only %s is strong enough." % Characters.display_name(required_character)
	var by_id := by.name.to_int()
	if holder_id == by_id:
		return "[E] Let go"
	if holder_id != 0:
		return "%s is holding it" % GameState.get_player_name(holder_id)
	return "[E] " + prompt_text


func _on_interact(by: Player) -> void:
	var by_id := by.name.to_int()
	if GameState.is_solo():
		# Solo: the switch latches. Press E to turn it on, E again to let go.
		if not _allowed(by) or by.global_position.distance_to(global_position) > reach:
			return
		if is_active:
			_release()
		else:
			_set_holder.rpc(by_id)
			server_set_active(true)
		return
	if holder_id == 0:
		if not _allowed(by) or by.global_position.distance_to(global_position) > reach:
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
	if GameState.is_solo():
		# Solo: it stays latched even if you walk away. Only a missing
		# holder (level reload) turns it off.
		if holder == null:
			_release()
		return
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
