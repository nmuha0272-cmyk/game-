class_name WeaponHolder
extends Node
## A player's single weapon slot.
##
## Like the inventory, the HOST owns the real state (what gun, rounds loaded,
## spare ammo) and sends a copy to every computer whenever it changes. The
## owner's computer only asks the host to draw, fire and reload.
##
## Firing is done on the host: it shoots a ray from the owner's camera, damages
## whatever monster it hits, and makes a noise that every monster can hear.

signal changed

## The gun this player carries ("" = unarmed). See Weapons.INFO.
var weapon_id := ""
## Rounds in the magazine right now.
var loaded := 0
## Spare ammo: ammo type (String) -> rounds (int).
var reserve := {}
## True while the gun is "out" (holding left click fires instead of using gear).
var drawn := false

var _cooldown := 0.0

@onready var player: Player = get_parent()


# ------------------------------------------------------------- questions

func info() -> Dictionary:
	return Weapons.INFO.get(weapon_id, {})


func has_weapon() -> bool:
	return not weapon_id.is_empty() and Weapons.INFO.has(weapon_id)


func ammo_type() -> String:
	return Weapons.ammo_type(weapon_id)


func reserve_rounds() -> int:
	return int(reserve.get(ammo_type(), 0))


## Text shown on the HUD, e.g. "9mm Pistol   15/30".
func label() -> String:
	if not has_weapon():
		return ""
	return "%s   %d/%d" % [info().name, loaded, reserve_rounds()]


# ------------------------------------------------------------- starting loadout
## Called on every computer when the player spawns (deterministic, so no
## network message is needed). start_loaded < 0 means "fill the magazine".
func set_loadout(id: String, start_loaded: int, start_reserve: Dictionary) -> void:
	weapon_id = id
	var capacity := int(Weapons.INFO[id].get("capacity", 0)) if Weapons.INFO.has(id) else 0
	loaded = clampi(start_loaded if start_loaded >= 0 else capacity, 0, capacity)
	reserve = start_reserve.duplicate(true)
	changed.emit()


# ------------------------------------------------------------- owner requests

func request_toggle() -> void:
	if not has_weapon():
		return
	if multiplayer.is_server():
		server_set_drawn(not drawn)
	else:
		_request_drawn.rpc_id(1, not drawn)


func request_fire() -> void:
	if not has_weapon() or not drawn or player.is_downed or _cooldown > 0.0:
		return
	_cooldown = float(info().get("fire_delay", 0.2))
	if multiplayer.is_server():
		server_fire()
	else:
		_request_fire.rpc_id(1)


func request_reload() -> void:
	if not has_weapon():
		return
	if multiplayer.is_server():
		server_reload()
	else:
		_request_reload.rpc_id(1)


# ------------------------------------------------------------- host-only changes

func server_set_drawn(value: bool) -> void:
	if not multiplayer.is_server():
		return
	drawn = value if has_weapon() else false
	_send()
	if drawn:
		server_tell(label())


func server_fire() -> void:
	if not multiplayer.is_server() or not has_weapon() or player.is_downed:
		return
	var data := info()
	if loaded <= 0:
		server_tell("Empty! Press R to reload.")
		return
	loaded -= 1
	_fire_shot(data)
	_send()


func server_reload() -> void:
	if not multiplayer.is_server() or not has_weapon():
		return
	var capacity := int(info().get("capacity", 0))
	if loaded >= capacity:
		return
	var have := reserve_rounds()
	if have <= 0:
		server_tell("No %s left." % Weapons.AMMO.get(ammo_type(), {}).get("name", "ammo"))
		return
	var take := mini(capacity - loaded, have)
	loaded += take
	reserve[ammo_type()] = have - take
	_send()


## Host only: pick up spare ammo (see ItemEffects).
func server_add_ammo(type: String, rounds: int) -> void:
	if not multiplayer.is_server() or rounds <= 0:
		return
	reserve[type] = int(reserve.get(type, 0)) + rounds
	_send()


func _fire_shot(data: Dictionary) -> void:
	var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
	if camera == null:
		return
	var origin := camera.global_position
	var basis := camera.global_transform.basis
	var forward := -basis.z
	var pellets := int(data.get("pellets", 1))
	var space := player.get_world_3d().direct_space_state
	for i in pellets:
		var direction := forward
		if pellets > 1:
			direction = (forward
					+ basis.x * randf_range(-0.06, 0.06)
					+ basis.y * randf_range(-0.06, 0.06)).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0)
		query.exclude = [player.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var monster := hit.get("collider") as Monster
		if monster == null:
			continue
		if data.has("stun"):
			monster.take_stun(float(data.stun))
		else:
			monster.take_damage(float(data.damage), player)
	# Every gunshot draws monsters to where you fired.
	player.get_tree().call_group("monsters", "hear_noise", origin, float(data.get("noise", 20.0)))


# ------------------------------------------------------------- networking

func _send() -> void:
	_receive.rpc(weapon_id, loaded, reserve, drawn)


# Only the host (network ID 1) may send these.
@rpc("any_peer", "call_local", "reliable")
func _receive(id: String, new_loaded: int, new_reserve: Dictionary, new_drawn: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	weapon_id = id
	loaded = new_loaded
	reserve = new_reserve
	drawn = new_drawn
	changed.emit()


@rpc("any_peer", "reliable")
func _request_drawn(value: bool) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		server_set_drawn(value)


@rpc("any_peer", "reliable")
func _request_fire() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		server_fire()


@rpc("any_peer", "reliable")
func _request_reload() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		server_reload()


# ------------------------------------------------------------- messages

func server_tell(text: String) -> void:
	if player.is_multiplayer_authority():
		player.get_tree().call_group("player_hud", "show_message", text)
	else:
		_show_message.rpc_id(player.get_multiplayer_authority(), text)


@rpc("any_peer", "reliable")
func _show_message(text: String) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		player.get_tree().call_group("player_hud", "show_message", text)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
