class_name Inventory
extends Node
## A player's 3 gear slots.
##
## The HOST owns the real contents and sends a copy to every computer whenever
## they change. Picking up, dropping and handing items over all happen in one
## step on the host, so items can never be duplicated or lost.

signal changed

const SLOT_COUNT := 3

## Each slot is {} when empty, or an item like {"id": "battery"}.
var slots: Array = [{}, {}, {}]
## The selected slot (shown in your hand). Chosen by the owner.
var active_slot := 0

@onready var player: Player = get_parent()


# ------------------------------------------------------------- questions

func get_item(slot: int) -> Dictionary:
	return slots[slot] if slot >= 0 and slot < SLOT_COUNT else {}


func get_active_item() -> Dictionary:
	return get_item(active_slot)


func find_item(id: String) -> int:
	for i in SLOT_COUNT:
		if slots[i].get("id") == id:
			return i
	return -1


func has_item(id: String) -> bool:
	return find_item(id) >= 0


func free_slot() -> int:
	# Prefer the selected slot so a picked-up item lands in your hand.
	if slots[active_slot].is_empty():
		return active_slot
	for i in SLOT_COUNT:
		if slots[i].is_empty():
			return i
	return -1


func is_carrying_heavy() -> bool:
	for item in slots:
		if Items.is_heavy(item):
			return true
	return false


## The Guard carries heavy things at full speed. Everyone else slows down.
func speed_multiplier() -> float:
	if is_carrying_heavy() and player.character != Characters.Id.GUARD:
		return Items.HEAVY_SPEED_MULTIPLIER
	return 1.0


## Slot of a gas mask that still has filter left (-1 if none).
func find_working_gas_mask() -> int:
	for i in SLOT_COUNT:
		if slots[i].get("id") == "gas_mask" and slots[i].get("filter", 0.0) > 0.0:
			return i
	return -1


# ------------------------------------------------------------- host-only changes

func server_add(item: Dictionary) -> bool:
	var slot := free_slot()
	if not multiplayer.is_server() or slot < 0:
		return false
	slots[slot] = item
	_send_to_everyone()
	return true


## Host only: replace all slots at once (restoring gear at a checkpoint).
func server_set_slots(new_slots: Array) -> void:
	if multiplayer.is_server():
		slots = new_slots
		_send_to_everyone()


func server_remove(slot: int) -> Dictionary:
	var item := get_item(slot)
	if multiplayer.is_server() and not item.is_empty():
		slots[slot] = {}
		_send_to_everyone()
	return item


## Used by toxic gas to drain a gas mask's filter.
func server_drain_filter(slot: int, seconds: float) -> void:
	var mask := get_item(slot)
	if not multiplayer.is_server() or not mask.has("filter"):
		return
	var before := ceili(mask.filter)
	mask.filter = maxf(mask.filter - seconds, 0.0)
	# Only send an update when the whole-second number changes.
	if ceili(mask.filter) != before:
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


func server_tell(text: String) -> void:
	if player.is_multiplayer_authority():
		get_tree().call_group("player_hud", "show_message", text)
	else:
		_show_message.rpc_id(player.get_multiplayer_authority(), text)


# ------------------------------------------------------------- requests (owner's computer)

func select_slot(slot: int) -> void:
	active_slot = clampi(slot, 0, SLOT_COUNT - 1)
	changed.emit()
	if multiplayer.is_server():
		_send_to_everyone()
	else:
		_request_select.rpc_id(1, active_slot)


func request_drop() -> void:
	_ask("drop", active_slot, 0)


func request_give(target_id: int) -> void:
	_ask("give", active_slot, target_id)


func request_use(target_id: int) -> void:
	_ask("use", active_slot, target_id)


func _ask(action: String, slot: int, target_id: int) -> void:
	if multiplayer.is_server():
		_server_action(action, slot, target_id)
	else:
		_request_action.rpc_id(1, action, slot, target_id)


# ------------------------------------------------------------- networking

@rpc("any_peer", "reliable")
func _request_action(action: String, slot: int, target_id: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		_server_action(action, slot, target_id)


@rpc("any_peer", "reliable")
func _request_select(slot: int) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player.get_multiplayer_authority():
		active_slot = clampi(slot, 0, SLOT_COUNT - 1)
		_send_to_everyone()


## Host only: do what the player asked, if it's allowed.
func _server_action(action: String, slot: int, target_id: int) -> void:
	var item := get_item(slot)
	if item.is_empty() or player.is_downed:
		return
	match action:
		"drop":
			server_remove(slot)
			ItemSpawner.find(get_tree()).server_drop(item, player)
		"give":
			var teammate := Player.find(get_tree(), target_id)
			if teammate == null or teammate == player or teammate.is_downed \
					or teammate.global_position.distance_to(player.global_position) > 3.0:
				return
			if teammate.inventory.free_slot() < 0:
				server_tell("%s's hands are full." % GameState.get_player_name(target_id))
				return
			server_remove(slot)
			teammate.inventory.server_add(item)
			teammate.inventory.server_tell("%s gave you: %s" % [
					GameState.get_player_name(player.name.to_int()), Items.display_name(item)])
		"use":
			if ItemEffects.server_use(item, player, target_id):
				server_remove(slot)


func _send_to_everyone() -> void:
	_receive.rpc(slots, active_slot)


# Only the host (network ID 1) may send these.
@rpc("any_peer", "call_local", "reliable")
func _receive(new_slots: Array, new_active: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	slots = new_slots
	# Our own selection stays as we chose it; others follow the host.
	if not player.is_multiplayer_authority():
		active_slot = new_active
	changed.emit()


@rpc("any_peer", "reliable")
func _show_message(text: String) -> void:
	if multiplayer.get_remote_sender_id() == 1:
		get_tree().call_group("player_hud", "show_message", text)
