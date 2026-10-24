extends Node
class_name MovementSync
## Walking in step with a teammate (for example Cole helping Eli along):
## while synced, both players walk at the slower player's speed. Started and
## stopped from player_movement.gd. Each player's computer slows its own
## player; the partner's computer is told to do the same.

var sync_partner: Player = null
var _original_speed: float = 0.0
var _sync_active: bool = false

@onready var player: Player = get_parent()


func _physics_process(_delta: float) -> void:
	if _sync_active and is_instance_valid(sync_partner):
		player.walk_speed = minf(_original_speed, sync_partner.walk_speed)
	elif _sync_active:
		_stop_sync()


func start_sync(target: Player) -> bool:
	if target == null or target == player:
		return false
	if target.global_position.distance_to(player.global_position) > 2.0:
		return false
	_begin(target)
	# Tell the partner's computer to walk in step with us too.
	var partner_sync := target.get_node_or_null("MovementSync")
	if partner_sync:
		partner_sync._set_partner.rpc_id(target.name.to_int(), player.name.to_int(), true)
	return true


func stop_sync() -> void:
	if not _sync_active:
		return
	var partner := sync_partner
	_stop_sync()
	if is_instance_valid(partner):
		var partner_sync := partner.get_node_or_null("MovementSync")
		if partner_sync:
			partner_sync._set_partner.rpc_id(partner.name.to_int(), player.name.to_int(), false)


func is_syncing() -> bool:
	return _sync_active


func _begin(target: Player) -> void:
	if not _sync_active:
		_original_speed = player.walk_speed
	sync_partner = target
	_sync_active = true


func _stop_sync() -> void:
	_sync_active = false
	if _original_speed > 0.0:
		player.walk_speed = _original_speed
	_original_speed = 0.0
	sync_partner = null


## Runs on this player's own computer: a teammate started/stopped walking
## in step with us.
@rpc("any_peer", "call_local", "reliable")
func _set_partner(partner_id: int, enable: bool) -> void:
	var partner := Player.find(get_tree(), partner_id)
	if enable and partner:
		_begin(partner)
	elif not enable:
		_stop_sync()
