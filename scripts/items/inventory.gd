class_name Inventory
extends Node
## Player inventory: 4 quick slots (keys 1-4) + storage slots (grows with pouches/backpacks, up to 10).
## Total capacity = 4 + storage (2 to 10) = 6 to 14 items.
##
## The HOST owns the real contents and sends a copy to every computer whenever
## they change. Picking up, dropping, giving, and crafting all happen on the host.

signal changed

## Quick slots everyone starts with (always 4).
const QUICK_SLOTS := 4
## Base storage slots (grows with packs).
const BASE_STORAGE := 2
## Maximum storage slots (with all pouches/backpacks).
const MAX_STORAGE := 10

## Quick slots: fixed 4, used for active items (guns, melee, throwables, medkits...).
var quick_slots: Array = [{}, {}, {}, {}]
## Storage slots: dynamic array, grows with pouches/backpacks.
var storage_slots: Array = [{}, {}]
## Currently selected quick slot (0-3).
var active_quick := 0

@onready var player: Player = get_parent()


# ------------------------------------------------------------- questions

## Total item capacity (quick + storage).
func total_capacity() -> int:
	return QUICK_SLOTS + storage_slots.size()

## Current storage slot count (grows with packs).
func storage_count() -> int:
	return storage_slots.size()

## Check if a quick slot index is valid.
func is_valid_quick(idx: int) -> bool:
	return idx >= 0 and idx < QUICK_SLOTS

## Check if a storage slot index is valid.
func is_valid_storage(idx: int) -> bool:
	return idx >= 0 and idx < storage_slots.size()

## Get item from quick slot.
func get_quick(idx: int) -> Dictionary:
	if not is_valid_quick(idx):
		return {}
	return quick_slots[idx]

## Get item from storage slot.
func get_storage(idx: int) -> Dictionary:
	if not is_valid_storage(idx):
		return {}
	return storage_slots[idx]

## Get currently active quick item (the one in hand).
func get_active_quick() -> Dictionary:
	return get_quick(active_quick)

## Find item by id across both quick and storage. Returns (is_quick, index).
func find_item(id: String) -> Array:
	for i in QUICK_SLOTS:
		if quick_slots[i].get("id") == id:
			return [true, i]
	for i in storage_slots.size():
		if storage_slots[i].get("id") == id:
			return [false, i]
	return [false, -1]

## A carried gun (quick slots first) that fires this ammo type, or {}.
## The dictionary is the real slot item, so changes to it stick.
func find_gun_for_ammo(ammo_type: String) -> Dictionary:
	for item: Dictionary in quick_slots + storage_slots:
		if Items.is_weapon(item) and not Items.is_melee(item) \
				and Weapons.ammo_type(Items.weapon_id(item)) == ammo_type:
			return item
	return {}


## True if player has item anywhere.
func has_item(id: String) -> bool:
	var result := find_item(id)
	return result[1] >= 0

## First empty storage slot, then first empty quick slot.
func free_slot() -> Array:
	for i in storage_slots.size():
		if storage_slots[i].is_empty():
			return [false, i]
	for i in QUICK_SLOTS:
		if quick_slots[i].is_empty():
			return [true, i]
	return [false, -1]

## Check if carrying any heavy item (in quick or storage).
func is_carrying_heavy() -> bool:
	for item in quick_slots:
		if Items.is_heavy(item):
			return true
	for item in storage_slots:
		if Items.is_heavy(item):
			return true
	return false

## Speed multiplier from heavy items (Guard ignores).
func speed_multiplier() -> float:
	if is_carrying_heavy() and player.character != Characters.Id.GUARD:
		return Items.HEAVY_SPEED_MULTIPLIER
	return 1.0

## Slot of a gas mask with filter left (-1 if none). Checks both quick and storage.
func find_working_gas_mask() -> Array:
	for i in QUICK_SLOTS:
		var item: Dictionary = quick_slots[i]
		if item.get("id") == "gas_mask" and item.get("filter", 0.0) > 0.0:
			return [true, i]
	for i in storage_slots.size():
		var item: Dictionary = storage_slots[i]
		if item.get("id") == "gas_mask" and item.get("filter", 0.0) > 0.0:
			return [false, i]
	return [false, -1]


# ------------------------------------------------------------- host-only changes

## Host only: add item to inventory. Prefers storage, then quick.
func server_add(item: Dictionary) -> bool:
	if not multiplayer.is_server():
		return false
	var result: Array = free_slot()
	if result[1] < 0:
		return false
	if result[0]: # is_quick
		quick_slots[result[1]] = item
	else:
		storage_slots[result[1]] = item
	_send_to_everyone()
	return true

## Host only: an item inside a slot was changed in place (ammo, filter...):
## send the new state to everyone.
func server_refresh() -> void:
	if multiplayer.is_server():
		_send_to_everyone()


## Host only: strap on a pouch/backpack. Adds storage slots.
func server_expand(extra_slots: int) -> int:
	if not multiplayer.is_server() or storage_slots.size() >= MAX_STORAGE:
		return 0
	var added := clampi(extra_slots, 1, MAX_STORAGE - storage_slots.size())
	for i in added:
		storage_slots.append({})
	_send_to_everyone()
	return added

## Host only: replace all slots at once (checkpoint restore).
func server_set_slots(new_quick: Array, new_storage: Array) -> void:
	if multiplayer.is_server():
		quick_slots = new_quick
		storage_slots = new_storage
		active_quick = clampi(active_quick, 0, QUICK_SLOTS - 1)
		_send_to_everyone()

## Host only: remove item from quick or storage.
func server_remove(is_quick: bool, slot: int) -> Dictionary:
	var item := {} 
	if is_quick and is_valid_quick(slot):
		item = quick_slots[slot]
		if multiplayer.is_server() and not item.is_empty():
			quick_slots[slot] = {}
			_send_to_everyone()
	elif not is_quick and is_valid_storage(slot):
		item = storage_slots[slot]
		if multiplayer.is_server() and not item.is_empty():
			storage_slots[slot] = {}
			_send_to_everyone()
	return item

## Host only: swap quick <-> storage.
func server_swap(quick_idx: int, storage_idx: int) -> void:
	if not multiplayer.is_server():
		return
	if not is_valid_quick(quick_idx) or not is_valid_storage(storage_idx):
		return
	var tmp: Dictionary = quick_slots[quick_idx]
	quick_slots[quick_idx] = storage_slots[storage_idx]
	storage_slots[storage_idx] = tmp
	_send_to_everyone()

## Used by toxic gas to drain a gas mask's filter (checks both arrays).
func server_drain_filter(is_quick: bool, slot: int, seconds: float) -> void:
	var item := get_quick(slot) if is_quick else get_storage(slot)
	if not multiplayer.is_server() or not item.has("filter"):
		return
	var before := ceili(item.filter)
	item.filter = maxf(item.filter - seconds, 0.0)
	if ceili(item.filter) != before:
		_send_to_everyone()


## Host only: show a message on this player's screen.
const RADIO_STATIC := preload("res://assets/audio/radio_static.wav")
const PING_SCENE := preload("res://scenes/player/ping_marker.tscn")


## Host only: this player's walkie-talkie crackles. Everyone near hears the
## static (so does the Long Man: the host tells him separately). The owner
## sees the message and, if a teammate called, a marker where they are.
func server_radio(text: String, caller_position: Vector3, caller_name: String) -> void:
	if multiplayer.is_server():
		_radio.rpc(text, caller_position, caller_name)


## Host only: show a message on this player's screen.
func server_tell(text: String) -> void:
	if player.is_multiplayer_authority():
		get_tree().call_group("player_hud", "show_message", text)
	else:
		_show_message.rpc_id(player.get_multiplayer_authority(), text)


@rpc("any_peer", "call_local", "reliable")
func _radio(text: String, caller_position: Vector3, caller_name: String) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var crackle := AudioStreamPlayer3D.new()
	crackle.stream = RADIO_STATIC
	crackle.unit_size = 7.0
	crackle.volume_db = 2.0
	crackle.position = Vector3(0, 1.2, 0)
	player.add_child(crackle)
	crackle.play()
	crackle.finished.connect(crackle.queue_free)
	if not player.is_multiplayer_authority():
		return
	get_tree().call_group("player_hud", "show_message", text)
	if caller_position.is_finite() and caller_name != "":
		var marker := PING_SCENE.instantiate()
		marker.text = "%s (radio)" % caller_name
		marker.color = Color(0.6, 1.0, 0.6)
		player.get_parent().get_parent().add_child(marker)
		marker.global_position = caller_position + Vector3.UP * 1.8


@rpc("any_peer", "call_local", "reliable")
func _show_message(text: String) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		get_tree().call_group("player_hud", "show_message", text)


# ------------------------------------------------------------- requests (owner's computer)

## Owner selects quick slot 0-3.
func select_quick(idx: int) -> void:
	active_quick = clampi(idx, 0, QUICK_SLOTS - 1)
	changed.emit()
	if multiplayer.is_server():
		_send_to_everyone()
	else:
		_request_select_quick.rpc_id(1, active_quick)

## Owner requests swap between quick and storage.
func request_swap(quick_idx: int, storage_idx: int) -> void:
	if multiplayer.is_server():
		server_swap(quick_idx, storage_idx)
	else:
		_request_swap.rpc_id(1, quick_idx, storage_idx)

## Owner drops active quick item.
func request_drop() -> void:
	_ask("drop", true, active_quick, 0)

## Owner gives active quick item to teammate.
func request_give(target_id: int) -> void:
	_ask("give", true, active_quick, target_id)

## Owner uses active quick item.
func request_use(target_id: int) -> void:
	_ask("use", true, active_quick, target_id)

## Owner uses item from storage (for crafting outputs, etc.).
func request_use_storage(storage_idx: int, target_id: int) -> void:
	_ask("use", false, storage_idx, target_id)

func _ask(action: String, is_quick: bool, slot: int, target_id: int) -> void:
	if multiplayer.is_server():
		_server_action(action, is_quick, slot, target_id)
	else:
		_request_action.rpc_id(1, action, is_quick, slot, target_id)


# ------------------------------------------------------------- networking

@rpc("any_peer", "reliable")
func _request_action(action: String, is_quick: bool, slot: int, target_id: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		_server_action(action, is_quick, slot, target_id)

@rpc("any_peer", "reliable")
func _request_select_quick(slot: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		active_quick = clampi(slot, 0, QUICK_SLOTS - 1)
		_send_to_everyone()

@rpc("any_peer", "reliable")
func _request_swap(quick_idx: int, storage_idx: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		server_swap(quick_idx, storage_idx)


## Host only: execute action.
func _server_action(action: String, is_quick: bool, slot: int, target_id: int) -> void:
	var item := get_quick(slot) if is_quick else get_storage(slot)
	if item.is_empty() or player.is_downed:
		return
match action:
			"drop":
				server_remove(is_quick, slot)
				ItemSpawner.find(get_tree()).server_drop(item, player)
			"give":
				var teammate := Player.find(get_tree(), target_id)
				if teammate == null or teammate == player or teammate.is_downed \
						or teammate.global_position.distance_to(player.global_position) > 3.0:
					return
				if teammate.inventory.free_slot()[1] < 0:
					server_tell("%s's hands are full." % GameState.get_player_name(target_id))
					return
				server_remove(is_quick, slot)
				teammate.inventory.server_add(item)
				teammate.inventory.server_tell("%s gave you: %s" % [
						GameState.get_player_name(player.name.to_int()), Items.display_name(item)])
				
				# Eli-Cole bond bonus: extra magazine/bandage
				if _is_eli_cole_pair(player, teammate) and Items.is_ammo(item):
					var bonus_item = item.duplicate(true)
					bonus_item.amount = 1  # Single extra magazine
					teammate.inventory.server_add(bonus_item)
					teammate.inventory.server_tell("Bond bonus! +1 magazine")
				elif _is_eli_cole_pair(player, teammate) and item.get("id") == "bandage":
					var bonus_item = item.duplicate(true)
					bonus_item.amount = 1
					teammate.inventory.server_add(bonus_item)
					teammate.inventory.server_tell("Bond bonus! +1 bandage")
			"use":
				if ItemEffects.server_use(item, player, target_id):
					server_remove(is_quick, slot)


func _send_to_everyone() -> void:
	_receive.rpc(quick_slots, storage_slots, active_quick)


func _is_eli_cole_pair(p1: Player, p2: Player) -> bool:
	var c1 = p1.character
	var c2 = p2.character
	return (c1 == Characters.Id.SON and c2 == Characters.Id.GUARD) or \
	       (c1 == Characters.Id.GUARD and c2 == Characters.Id.SON)


# Only the host (network ID 1) may send these.
@rpc("any_peer", "call_local", "reliable")
func _receive(new_quick: Array, new_storage: Array, new_active: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	quick_slots = new_quick
	storage_slots = new_storage
	if not player.is_multiplayer_authority():
		active_quick = new_active
	active_quick = clampi(active_quick, 0, QUICK_SLOTS - 1)
	changed.emit()


# ------------------------------------------------------------- compatibility (for old code)

## Old API: slot_count() -> total slots (for HUD width calc, etc.)
func slot_count() -> int:
	return total_capacity()

## Old API: get_item(idx) -> checks quick first, then storage (for legacy HUD)
func get_item(idx: int) -> Dictionary:
	if idx < QUICK_SLOTS:
		return get_quick(idx)
	var s_idx := idx - QUICK_SLOTS
	return get_storage(s_idx)

## Old API: active_slot property (for legacy code)
func get_active_slot() -> int:
	return active_quick

func set_active_slot(val: int) -> void:
	select_quick(val)