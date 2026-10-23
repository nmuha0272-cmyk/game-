class_name DownedState
extends Node
## Tracks whether this player is knocked down, and who (if anyone) is
## carrying them. The host decides, then tells every computer.
##
## When downed, a 30-second timer starts (it pauses while the Guard carries
## you). A teammate holds E for 3 seconds to help you up (a Med Kit does it
## instantly). If the timer runs out you "bleed out": you can't be helped up,
## (Not used any more: going down now kills the whole team, see team_monitor.gd.)

signal changed

## Seconds until a downed player bleeds out.
const BLEED_OUT_TIME := 30.0
## Eli-Cole bond bonus: bleed out time reduced to 15s
const BOND_BLEED_OUT_TIME := 15.0
## Seconds a teammate must hold E to help someone up.
const HELP_UP_TIME := 3.0

var is_downed := false
## True after bleeding out (still lying there, but out of the game for now).
var is_out := false
## Network ID of the Guard carrying us (0 = nobody).
var carried_by := 0
## Seconds left before bleeding out (counted on every computer for the HUD).
var time_left := 0.0
## Current bleed out time (may be reduced by Eli-Cole bond)
var _current_bleed_time := BLEED_OUT_TIME

@onready var player: Player = get_parent()


func get_carrier() -> Player:
	return Player.find(get_tree(), carried_by) if carried_by != 0 else null


func _is_eli_cole_pair(p1: Player, p2: Player) -> bool:
	var c1 = p1.character
	var c2 = p2.character
	return (c1 == Characters.Id.SON and c2 == Characters.Id.GUARD) or \
	       (c1 == Characters.Id.GUARD and c2 == Characters.Id.SON)


func _get_reviver() -> Player:
	# This is called when someone is helping up - we need to track who initiated the help
	# For now, we'll check nearby players when the timer starts
	return null


func _update_bleed_time() -> void:
	# Check if Eli and Cole are both alive and nearby
	var downed_id := player.name.to_int()
	var eli_id := 0
	var cole_id := 0
	
	for p in get_tree().get_nodes_in_group("players"):
		if p.character == Characters.Id.SON:
			eli_id = p.name.to_int()
		elif p.character == Characters.Id.GUARD:
			cole_id = p.name.to_int()
	
	# Check if Eli is helping Cole or vice versa
	var downed_char := player.character
	if downed_char == Characters.Id.SON and cole_id != 0:
		var cole := Player.find(get_tree(), cole_id)
		if cole and not cole.is_downed and cole.global_position.distance_to(player.global_position) <= 5.0:
			_current_bleed_time = BOND_BLEED_OUT_TIME
			return
	elif downed_char == Characters.Id.GUARD and eli_id != 0:
		var eli := Player.find(get_tree(), eli_id)
		if eli and not eli.is_downed and eli.global_position.distance_to(player.global_position) <= 5.0:
			_current_bleed_time = BOND_BLEED_OUT_TIME
			return
	
	_current_bleed_time = BLEED_OUT_TIME


func _process(delta: float) -> void:
	if not is_downed or is_out or carried_by != 0:
		return
	_update_bleed_time()
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0 and multiplayer.is_server():
		server_set_carried_by(0)
		_set_out.rpc(true)


## Host only: knock this player down, or help them up.
func server_set_downed(value: bool) -> void:
	if not multiplayer.is_server():
		return
	if not value:
		server_set_carried_by(0)
	else:
		# Going down costs you your gun: it drops so it can be picked back up
		# (or grabbed by a teammate). Do this before is_downed flips, so the
		# drop is allowed to run.
		player.get_node("WeaponControls").server_drop_active_weapon()
	_set_downed.rpc(value)


## Host only: bring a bled-out player back (at a checkpoint).
func server_respawn(at: Vector3) -> void:
	if not multiplayer.is_server():
		return
	server_set_carried_by(0)
	_current_bleed_time = BLEED_OUT_TIME
	_set_downed.rpc(false)
	_teleport.rpc_id(player.get_multiplayer_authority(), at)


## Host only: who is carrying this player (0 = put them down).
func server_set_carried_by(carrier_id: int) -> void:
	if multiplayer.is_server() and carrier_id != carried_by:
		_set_carried_by.rpc(carrier_id)


func can_be_helped(by: Player) -> bool:
	return is_downed and not is_out and by != player and not by.is_downed


func get_help_prompt(by: Player) -> String:
	var who := GameState.get_player_name(player.name.to_int())
	var text := "[Hold E] Help %s up (%ds left)" % [who, ceili(time_left)]
	if by.character == Characters.Id.GUARD:
		text += "   [Q] Drop" if carried_by == by.name.to_int() else "   [Q] Carry"
	return text


## Called on the helper's computer once they've held E long enough.
func request_help_up(_by: Player) -> void:
	if multiplayer.is_server():
		_server_help_up()
	else:
		_request_help_up.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_help_up() -> void:
	if multiplayer.is_server():
		_server_help_up()


func _server_help_up() -> void:
	if is_downed and not is_out:
		server_set_downed(false)


# Only the host (network ID 1) is allowed to send these.
@rpc("any_peer", "call_local", "reliable")
func _set_downed(value: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	is_downed = value
	is_out = false
	_update_bleed_time()
	time_left = _current_bleed_time if value else 0.0
	changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _set_out(value: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	is_out = value
	time_left = 0.0
	changed.emit()


@rpc("any_peer", "call_local", "reliable")
func _teleport(at: Vector3) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		player.global_position = at
		player.velocity = Vector3.ZERO


@rpc("any_peer", "call_local", "reliable")
func _set_carried_by(carrier_id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	# Stop the carrier and the carried player from bumping into each other.
	var old_carrier := get_carrier()
	if old_carrier:
		player.remove_collision_exception_with(old_carrier)
		old_carrier.remove_collision_exception_with(player)
	carried_by = carrier_id
	var new_carrier := get_carrier()
	if new_carrier:
		player.add_collision_exception_with(new_carrier)
		new_carrier.add_collision_exception_with(player)
	changed.emit()
