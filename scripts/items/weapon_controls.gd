extends Node
## Weapon/melee controls for the active quick slot item.
## 4 = toggle draw/holster, R = reload (guns), left-click = fire/swing.
## Only does anything on your own player.

@export var inventory: Inventory

var _cooldown := 0.0
var _drawn := false


func _ready() -> void:
	inventory.changed.connect(_on_inventory_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not inventory.player.is_multiplayer_authority() or inventory.player.is_downed:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon"):
		return

	var is_melee := Items.is_melee(item)

	if event.is_action_pressed("weapon_toggle"):
		_toggle_drawn()
	elif event.is_action_pressed("reload") and not is_melee:
		_request_reload()
	elif event.is_action_pressed("drop_weapon"):
		_request_drop()
	elif event.is_action_pressed("use_item") and _drawn:
		if is_melee:
			_request_swing()
		else:
			_request_fire()


func _process(_delta: float) -> void:
	if not inventory.player.is_multiplayer_authority() or inventory.player.is_downed:
		return

	if _cooldown > 0.0:
		_cooldown -= _delta

	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon") or not _drawn:
		return

	var is_melee := Items.is_melee(item)
	if not is_melee:
		# Full-auto guns
		if item.get("auto", false) and Input.is_action_pressed("use_item"):
			_request_fire()


func _on_inventory_changed() -> void:
	# If active quick slot changed or item removed, holster
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon"):
		_drawn = false


func _toggle_drawn() -> void:
	_drawn = not _drawn
	_request_set_drawn(_drawn)


func _request_set_drawn(drawn: bool) -> void:
	if multiplayer.is_server():
		_server_set_drawn(drawn)
	else:
		_request_drawn.rpc_id(1, drawn)


func _request_fire() -> void:
	if multiplayer.is_server():
		_server_fire()
	else:
		_request_fire_rpc.rpc_id(1)


func _request_swing() -> void:
	if multiplayer.is_server():
		_server_swing()
	else:
		_request_swing_rpc.rpc_id(1)


func _request_reload() -> void:
	if multiplayer.is_server():
		_server_reload()
	else:
		_request_reload_rpc.rpc_id(1)


func _request_drop() -> void:
	if multiplayer.is_server():
		_server_drop()
	else:
		_request_drop_rpc.rpc_id(1)


# ------------------------------------------------------------- RPCs (host receives)

@rpc("any_peer", "reliable")
func _request_drawn(drawn: bool) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_server_set_drawn(drawn)

@rpc("any_peer", "reliable")
func _request_fire_rpc() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_server_fire()

@rpc("any_peer", "reliable")
func _request_swing_rpc() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_server_swing()

@rpc("any_peer", "reliable")
func _request_reload_rpc() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_server_reload()

@rpc("any_peer", "reliable")
func _request_drop_rpc() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_server_drop()


# ------------------------------------------------------------- Host-only execution

func _server_set_drawn(drawn: bool) -> void:
	if not multiplayer.is_server():
		return
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon"):
		return
	_drawn = drawn
	_sync_drawn(drawn)
	if drawn:
		inventory.server_tell(_get_label(item))


func _server_fire() -> void:
	if not multiplayer.is_server():
		return
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon") or Items.is_melee(item) or not _drawn:
		return
	if _cooldown > 0.0:
		return

	var data := Weapons.get_info(Items.weapon_id(item))
	if not data:
		return

	var capacity: int = int(data.get("capacity", 0))
	var loaded := int(item.get("loaded", capacity))
	if loaded <= 0:
		inventory.server_tell("Empty! Press R to reload.")
		return

	_cooldown = float(data.get("fire_delay", 0.2))
	loaded -= 1
	item.loaded = loaded
	_fire_shot(data)
	_sync_item(item)


func _server_swing() -> void:
	if not multiplayer.is_server():
		return
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon") or not Items.is_melee(item) or not _drawn:
		return
	if _cooldown > 0.0:
		return

	var weapon_id := Items.weapon_id(item)
	var data := Weapons.get_melee_info(weapon_id)
	if not data:
		return

	_cooldown = float(data.get("speed", 1.0)) * 0.8  # swing speed based on weapon speed
	_swing_melee(data, weapon_id, item)


func _server_reload() -> void:
	if not multiplayer.is_server():
		return
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon") or Items.is_melee(item):
		return

	var weapon_id := Items.weapon_id(item)
	var data := Weapons.get_info(weapon_id)
	if not data:
		return

	var capacity := int(data.get("capacity", 0))
	var loaded := int(item.get("loaded", capacity))
	if loaded >= capacity:
		return

	var ammo_type: String = str(data.get("ammo", ""))
	var reserve: Dictionary = item.get("reserve", {})
	var have := int(reserve.get(ammo_type, 0))
	if have <= 0:
		inventory.server_tell("No %s left." % Weapons.AMMO.get(ammo_type, {}).get("name", "ammo"))
		return

	var take := mini(capacity - loaded, have)
	loaded += take
	reserve[ammo_type] = have - take
	item.loaded = loaded
	item.reserve = reserve
	_sync_item(item)
	inventory.server_tell("Reloaded. %d/%d" % [loaded, reserve.get(ammo_type, 0)])


## Host only: drop the gun/melee weapon in the active quick slot (going down).
func server_drop_active_weapon() -> void:
	_server_drop()


func _server_drop() -> void:
	if not multiplayer.is_server():
		return
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon"):
		return
	_drawn = false
	_sync_drawn(false)
	inventory.server_remove(true, inventory.active_quick)
	ItemSpawner.find(inventory.player.get_tree()).server_drop(item, inventory.player)


# ------------------------------------------------------------- Helpers

func _fire_shot(data: Dictionary) -> void:
	var camera := inventory.player.get_node_or_null("Head/Camera3D") as Camera3D
	if camera == null:
		return
	var origin := camera.global_position
	var basis := camera.global_transform.basis
	var forward := -basis.z
	var pellets := int(data.get("pellets", 1))
	var space := inventory.player.get_world_3d().direct_space_state
	for i in pellets:
		var direction := forward
		if pellets > 1:
			direction = (forward
					+ basis.x * randf_range(-0.06, 0.06)
					+ basis.y * randf_range(-0.06, 0.06)).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0)
		query.exclude = [inventory.player.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var monster := hit.get("collider") as Monster
		if monster == null:
			continue
		if data.has("stun"):
			monster.take_stun(float(data.stun))
		else:
			monster.take_damage(float(data.damage), inventory.player)
	inventory.player.get_tree().call_group("monsters", "hear_noise", origin, float(data.get("noise", 20.0)))


func _swing_melee(data: Dictionary, weapon_id: String, item: Dictionary) -> void:
	var camera := inventory.player.get_node_or_null("Head/Camera3D") as Camera3D
	if camera == null:
		return
	var origin := camera.global_position
	var basis := camera.global_transform.basis
	var forward := -basis.z
	var reach := float(data.get("reach", 2.0))
	var space := inventory.player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * reach)
	query.exclude = [inventory.player.get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var monster := hit.get("collider") as Monster
		if monster:
			var damage := float(data.get("damage", 25.0))
			if data.has("armor_pierce"):
				monster.take_damage(damage, inventory.player, float(data.armor_pierce))
			else:
				monster.take_damage(damage, inventory.player)
			# Bleed chance
			if data.has("bleed_chance") and randf() < float(data.bleed_chance):
				monster.apply_bleed()
		# Hit something solid - make noise
		inventory.player.get_tree().call_group("monsters", "hear_noise", origin, float(data.get("noise", 4.0)))
	else:
		# Miss - lighter noise
		inventory.player.get_tree().call_group("monsters", "hear_noise", origin, float(data.get("noise", 4.0)) * 0.5)

	# Decrease durability
	var max_dur := int(data.get("max_durability", 100))
	var cur_dur := int(item.get("durability", max_dur))
	cur_dur = max(0, cur_dur - 1)
	item.durability = cur_dur
	item.max_durability = max_dur
	_sync_item(item)

	if cur_dur <= 0:
		inventory.server_tell("Your %s broke." % data.name)
		inventory.server_remove(true, inventory.active_quick)
		_drawn = false
		_sync_drawn(false)


func _get_label(item: Dictionary) -> String:
	var weapon_id := Items.weapon_id(item)
	if Items.is_melee(item):
		var data := Weapons.get_melee_info(weapon_id)
		var dur := int(item.get("durability", data.get("max_durability", 100)))
		var max_dur := int(data.get("max_durability", 100))
		return "%s (%d/%d)" % [data.name, dur, max_dur]
	else:
		var data := Weapons.get_info(weapon_id)
		var loaded := int(item.get("loaded", data.get("capacity", 0)))
		var reserve: Dictionary = item.get("reserve", {})
		var ammo_type: String = str(data.get("ammo", ""))
		var have := int(reserve.get(ammo_type, 0))
		return "%s   %d/%d" % [data.name, loaded, have]


# ------------------------------------------------------------- Sync

func _sync_drawn(drawn: bool) -> void:
	_sync_item_data({"drawn": drawn})


func _sync_item(item: Dictionary) -> void:
	_sync_item_data(item)


func _sync_item_data(data: Dictionary) -> void:
	if multiplayer.is_server():
		_receive_item.rpc(data)
	else:
		_request_sync.rpc_id(1, data)


@rpc("any_peer", "reliable")
func _request_sync(data: Dictionary) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == inventory.player.get_multiplayer_authority():
		_receive_item.rpc(data)


@rpc("any_peer", "call_local", "reliable")
func _receive_item(data: Dictionary) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	if data.has("drawn"):
		_drawn = data.drawn
	# If full item data sent, update the active quick slot
	if data.has("id") and data.has("weapon"):
		# Find and update the item in our inventory (quick slots)
		for i in Inventory.QUICK_SLOTS:
			var slot_item := inventory.get_quick(i)
			if not slot_item.is_empty() and slot_item.get("weapon") == data.get("weapon"):
				if data.has("loaded"):
					slot_item.loaded = data.loaded
				if data.has("reserve"):
					slot_item.reserve = data.reserve
				if data.has("durability"):
					slot_item.durability = data.durability
				if data.has("max_durability"):
					slot_item.max_durability = data.max_durability
				break
	inventory.changed.emit()