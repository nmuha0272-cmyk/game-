extends Ability
## Frank's strength.
## - Hold Q on a closed door: hold it shut (nobody can open it).
## - Hold Q on something heavy: move it around.
## - Press Q on a downed teammate: pick them up. Press Q again to put them down.
## Frank is also slower and louder than the others (see characters.gd).

## Let go automatically if Frank walks further away than this.
const MAX_REACH := 3.0

var _held_door: Door = null
var _moved_object: HeavyObject = null
var _carried: Player = null


func _init() -> void:
	ability_name = "Strength"


func _on_pressed() -> void:
	if _carried:
		_set_carrying(_carried, false)
		return
	var target := interactor.current_target
	if target is Player and target.is_downed and target.downed.carried_by == 0:
		_set_carrying(target, true)
	elif target is Door and not target.is_open:
		_held_door = target
		_held_door.request_hold(player, true)
	elif target is HeavyObject:
		_moved_object = target
		player.add_collision_exception_with(_moved_object)
		_moved_object.request_move(player, true)


func _on_released() -> void:
	_let_go_of_door()
	_let_go_of_object()


func _physics_process(_delta: float) -> void:
	if not is_local():
		return
	if player.is_downed:
		_on_released()
		if _carried:
			_set_carrying(_carried, false)
	if _held_door and _too_far(_held_door):
		_let_go_of_door()
	if _moved_object and _too_far(_moved_object):
		_let_go_of_object()
	if _carried and not is_instance_valid(_carried):
		_carried = null
	elif _carried and not _carried.is_downed:
		_carried = null  # Someone helped them up.

	if _moved_object:
		player.speed_multiplier = 0.6
		status_text = "Moving the %s" % _moved_object.object_name
	elif _carried:
		player.speed_multiplier = 0.75
		status_text = "Carrying %s   [Q] Put down" % GameState.get_player_name(_carried.name.to_int())
	elif _held_door:
		player.speed_multiplier = 1.0
		status_text = "Holding the door shut"
	else:
		player.speed_multiplier = 1.0
		status_text = ""


func _too_far(node: Node3D) -> bool:
	return player.global_position.distance_to(node.global_position) > MAX_REACH


func _let_go_of_door() -> void:
	if _held_door:
		_held_door.request_hold(player, false)
		_held_door = null


func _let_go_of_object() -> void:
	if _moved_object:
		_moved_object.request_move(player, false)
		player.remove_collision_exception_with(_moved_object)
		_moved_object = null


func _set_carrying(target: Player, carry: bool) -> void:
	_carried = target if carry else null
	if multiplayer.is_server():
		_server_carry(target.name.to_int(), carry)
	else:
		_request_carry.rpc_id(1, target.name.to_int(), carry)


@rpc("any_peer", "reliable")
func _request_carry(target_id: int, carry: bool) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == owner_id():
		_server_carry(target_id, carry)


## Host only: pick up or put down a downed teammate.
func _server_carry(target_id: int, carry: bool) -> void:
	var target := Player.find(get_tree(), target_id)
	if target == null:
		return
	if carry and target.is_downed and target.downed.carried_by == 0:
		target.downed.server_set_carried_by(owner_id())
	elif not carry and target.downed.carried_by == owner_id():
		target.downed.server_set_carried_by(0)
