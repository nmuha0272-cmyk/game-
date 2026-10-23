extends Node
class_name MovementSync

var sync_partner: Player = null
var _original_speed: float = 0.0
var _sync_active: bool = false

func _ready() -> void:
	set_process(true)

func _physics_process(delta: float) -> void:
	if _sync_active and sync_partner and is_instance_valid(sync_partner):
		var target_speed = min(player.walk_speed, sync_partner.walk_speed)
		player.walk_speed = target_speed
	elif _sync_active:
		_stop_sync()

func start_sync(target: Player) -> bool:
	if not target or target == player:
		return false
	if target.global_position.distance_to(player.global_position) > 2.0:
		return false
	
	sync_partner = target
	_original_speed = player.walk_speed
	_sync_active = true
	
	# Sync on partner's client too
	if multiplayer.is_server():
		_sync_partner.rpc_id(target.name.to_int(), player.name.to_int(), true)
	else:
		_sync_partner.rpc_id(1, player.name.to_int(), target.name.to_int(), true)
	
	return true

func stop_sync() -> void:
	if _sync_active:
		_stop_sync()
		if sync_partner and is_instance_valid(sync_partner):
			if multiplayer.is_server():
				_sync_partner.rpc_id(sync_partner.name.to_int(), player.name.to_int(), false)
			else:
				_sync_partner.rpc_id(1, player.name.to_int(), sync_partner.name.to_int(), false)

func _stop_sync() -> void:
	_sync_active = false
	if _original_speed > 0.0:
		player.walk_speed = _original_speed
	_original_speed = 0.0
	sync_partner = null

@rpc("any_peer", "call_local", "reliable")
func _sync_partner(partner_id: int, requester_id: int, enable: bool) -> void:
	var partner = Player.find(get_tree(), partner_id)
	var requester = Player.find(get_tree(), requester_id)
	if not partner or not requester:
		return
	
	if enable:
		partner.sync_partner = requester
		partner._original_speed = partner.walk_speed
		partner._sync_active = true
	else:
		partner._sync_active = false
		if partner._original_speed > 0.0:
			partner.walk_speed = partner._original_speed
		partner._original_speed = 0.0
		partner.sync_partner = null

func is_syncing() -> bool:
	return _sync_active