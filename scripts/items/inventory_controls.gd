extends Node
## Reads your keys for the inventory: 1/2/3 or the mouse wheel to switch slot,
## left click to use, G to drop, T to give to the teammate you're looking at.
## Only does anything on your own player.

@export var inventory: Inventory
@export var interactor: Interactor


func _unhandled_input(event: InputEvent) -> void:
	if not inventory.player.is_multiplayer_authority() or inventory.player.is_downed:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	for i in Inventory.SLOT_COUNT:
		if event.is_action_pressed("slot_%d" % (i + 1)):
			inventory.select_slot(i)
	if event.is_action_pressed("slot_next"):
		inventory.select_slot((inventory.active_slot + 1) % Inventory.SLOT_COUNT)
	elif event.is_action_pressed("slot_prev"):
		inventory.select_slot((inventory.active_slot + Inventory.SLOT_COUNT - 1) % Inventory.SLOT_COUNT)
	elif event.is_action_pressed("use_item"):
		var looked_at := interactor.get_collider()
		inventory.request_use(looked_at.name.to_int() if looked_at is Player else 0)
	elif event.is_action_pressed("drop_item"):
		inventory.request_drop()
	elif event.is_action_pressed("give_item"):
		var teammate := get_teammate_in_reach()
		if teammate:
			inventory.request_give(teammate.name.to_int())


## The teammate you're looking at, if they're close enough to hand things to.
func get_teammate_in_reach() -> Player:
	var looked_at := interactor.get_collider()
	if looked_at is Player and looked_at != inventory.player and not looked_at.is_downed \
			and looked_at.global_position.distance_to(inventory.player.global_position) <= 3.0:
		return looked_at
	return null
