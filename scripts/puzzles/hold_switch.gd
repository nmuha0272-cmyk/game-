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

## Network IDs of whoever is holding it (0 = nobody). Supports up to 2 holders.
var holder_id_1 := 0
var holder_id_2 := 0

var _hold_start_1 := Vector3.ZERO
var _hold_start_2 := Vector3.ZERO
var _hold_age := 0.0
var _strength_multiplier := 1.0


func stays_done() -> bool:
	return false


func _ready() -> void:
	super()
	add_to_group("hold_switches")


## The switch this player is holding, or null. Lets them let go with E even
## when they aren't looking at it any more (a lifted vent cover is up high).
static func held_by(player: Player) -> Node:
	for hold_switch in player.get_tree().get_nodes_in_group("hold_switches"):
		if hold_switch.holder_id_1 == player.name.to_int() or hold_switch.holder_id_2 == player.name.to_int():
			return hold_switch
	return null


func _is_eli_cole_pair(p1: Player, p2: Player) -> bool:
	var c1 = p1.character
	var c2 = p2.character
	return (c1 == Characters.Id.SON and c2 == Characters.Id.GUARD) or \
	       (c1 == Characters.Id.GUARD and c2 == Characters.Id.SON)


func _allowed(by: Player) -> bool:
	return required_character < 0 or by.character == required_character \
			or not GameState.team_has(required_character)


func get_holders() -> Array[Player]:
	var holders := []
	if holder_id_1 != 0:
		var p1 := Player.find(get_tree(), holder_id_1)
		if p1: holders.append(p1)
	if holder_id_2 != 0:
		var p2 := Player.find(get_tree(), holder_id_2)
		if p2: holders.append(p2)
	return holders


func get_prompt(by: Player) -> String:
	var holders := get_holders()
	var by_id := by.name.to_int()
	
	if holders.is_empty() and not _allowed(by):
		return "Too heavy. Only %s is strong enough." % Characters.display_name(required_character)
	
	if by_id == holder_id_1 or by_id == holder_id_2:
		return "[E] Let go"
	
	if holders.size() == 2:
		var names := holders.map(func(p: Player): return GameState.get_player_name(p.name.to_int()))
		return "%s and %s are holding it" % names
	elif holders.size() == 1:
		return "%s is holding it" % GameState.get_player_name(holders[0].name.to_int())
	
	return "[E] " + prompt_text


func _on_interact(by: Player) -> void:
	var by_id := by.name.to_int()
	if GameState.is_solo():
		if not _allowed(by) or by.global_position.distance_to(global_position) > reach:
			return
		if is_active:
			_release()
		else:
			_set_holder.rpc(by_id)
			server_set_active(true)
		return
	
	# Check if already holding
	if by_id == holder_id_1 or by_id == holder_id_2:
		_release(by_id)
		return
	
	# Try to grab
	if holder_id_1 == 0:
		if not _allowed(by) or by.global_position.distance_to(global_position) > reach:
			return
		_hold_start_1 = by.global_position
		_hold_age = 0.0
		_set_holder.rpc(by_id, 1)
		server_set_active(true)
	elif holder_id_2 == 0:
		if not _allowed(by) or by.global_position.distance_to(global_position) > reach:
			return
		_hold_start_2 = by.global_position
		# Eli-Cole bond bonus: dual hold strength
		var other_holder := Player.find(get_tree(), holder_id_1)
		if other_holder and _is_eli_cole_pair(by, other_holder):
			_strength_multiplier = 1.5
		_set_holder.rpc(by_id, 2)
	else:
		return  # Already two holders


func _process(delta: float) -> void:
	if not multiplayer.is_server() or (holder_id_1 == 0 and holder_id_2 == 0):
		return
	
	var h1 := Player.find(get_tree(), holder_id_1) if holder_id_1 != 0 else null
	var h2 := Player.find(get_tree(), holder_id_2) if holder_id_2 != 0 else null
	
	if GameState.is_solo():
		if h1 == null and h2 == null:
			_release()
		return
	
	_hold_age += delta
	if _hold_age < 0.5:
		if h1: _hold_start_1 = h1.global_position
		if h2: _hold_start_2 = h2.global_position
	
	var release_1 := h1 == null or h1.is_downed or h1.global_position.distance_to(_hold_start_1) > max_distance
	var release_2 := h2 == null or h2.is_downed or h2.global_position.distance_to(_hold_start_2) > max_distance
	
	if release_1 and release_2:
		_release()
	elif release_1:
		_set_holder.rpc(0, 1)
	elif release_2:
		_set_holder.rpc(0, 2)


func _release(specific_id: int = 0) -> void:
	if specific_id == 0:
		# Release all
		_set_holder.rpc(0, 1)
		_set_holder.rpc(0, 2)
		_strength_multiplier = 1.0
		server_set_active(false)
	elif specific_id == holder_id_1:
		_set_holder.rpc(0, 1)
		if holder_id_2 == 0:
			_strength_multiplier = 1.0
			server_set_active(false)
	elif specific_id == holder_id_2:
		_set_holder.rpc(0, 2)
		if holder_id_1 == 0:
			_strength_multiplier = 1.0
			server_set_active(false)


@rpc("authority", "call_local", "reliable")
func _set_holder(id: int, slot: int = 1) -> void:
	if slot == 1:
		holder_id_1 = id
		if id == 0: _hold_start_1 = Vector3.ZERO
	else:
		holder_id_2 = id
		if id == 0: _hold_start_2 = Vector3.ZERO
