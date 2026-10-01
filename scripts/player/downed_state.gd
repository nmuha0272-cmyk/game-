class_name DownedState
extends Node
## Tracks whether this player is knocked down, and who (if anyone) is
## carrying them. The host decides both, then tells every computer.
##
## Placeholder for now: a teammate presses E to help a downed player up.
## Phase 9 replaces that with the real 30-second revive timer.

signal changed

var is_downed := false
## Network ID of the Guard carrying us (0 = nobody).
var carried_by := 0

@onready var player: Player = get_parent()


func get_carrier() -> Player:
	return Player.find(get_tree(), carried_by) if carried_by != 0 else null


## Host only: knock this player down, or help them up.
func server_set_downed(value: bool) -> void:
	if not multiplayer.is_server():
		return
	if not value:
		server_set_carried_by(0)
	_set_downed.rpc(value)


## Host only: who is carrying this player (0 = put them down).
func server_set_carried_by(carrier_id: int) -> void:
	if multiplayer.is_server() and carrier_id != carried_by:
		_set_carried_by.rpc(carrier_id)


func can_be_helped(by: Player) -> bool:
	return is_downed and by != player and not by.is_downed


func get_help_prompt(by: Player) -> String:
	var text := "[E] Help %s up" % GameState.get_player_name(player.name.to_int())
	if by.character == Characters.Id.GUARD:
		text += "   [Q] Drop" if carried_by == by.name.to_int() else "   [Q] Carry"
	return text


## Called on the helper's computer when they press E.
func request_help_up(_by: Player) -> void:
	if multiplayer.is_server():
		server_set_downed(false)
	else:
		_request_help_up.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_help_up() -> void:
	if multiplayer.is_server() and is_downed:
		server_set_downed(false)


# Only the host (network ID 1) is allowed to send these.
@rpc("any_peer", "call_local", "reliable")
func _set_downed(value: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	is_downed = value
	changed.emit()


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
