extends Node
## Inventory controls: 1/2/3/4 = quick slots, E = open storage menu, G = drop, T = give.
## Only does anything on your own player.

@export var inventory: Inventory
@export var interactor: Interactor

var _storage_menu_open := false


func _ready() -> void:
	# Listen for inventory changes to close menu if inventory structure changes
	inventory.changed.connect(_on_inventory_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not inventory.player.is_multiplayer_authority() or inventory.player.is_downed:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	# Quick slot selection: 1, 2, 3, 4
	for i in Inventory.QUICK_SLOTS:
		var action := "slot_%d" % (i + 1)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			inventory.select_quick(i)
			return

	# Open/close storage menu with E
	if event.is_action_pressed("open_storage"):
		_toggle_storage_menu()
		return

	# Close storage menu with E or Escape
	if _storage_menu_open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_storage")):
		_close_storage_menu()
		return

	# Only handle use/drop/give when storage menu is closed
	if _storage_menu_open:
		return

	if event.is_action_pressed("use_item") and not _is_melee_or_gun_drawn():
		var looked_at := interactor.get_collider()
		inventory.request_use(looked_at.name.to_int() if looked_at is Player else 0)
	elif event.is_action_pressed("drop_item"):
		inventory.request_drop()
	elif event.is_action_pressed("give_item"):
		var teammate := get_teammate_in_reach()
		if teammate:
			inventory.request_give(teammate.name.to_int())


func _is_melee_or_gun_drawn() -> bool:
	# Check if active quick item is a weapon (gun or melee) that should handle left-click
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon"):
		return false
	return true


func _toggle_storage_menu() -> void:
	_storage_menu_open = not _storage_menu_open
	if _storage_menu_open:
		_open_storage_menu()
	else:
		_close_storage_menu()


func _open_storage_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.menu_open = true
	get_tree().call_group("player_hud", "open_storage_menu")


func _close_storage_menu() -> void:
	_storage_menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.menu_open = false
	get_tree().call_group("player_hud", "close_storage_menu")


func _on_inventory_changed() -> void:
	# If storage size changed, rebuild storage menu
	if _storage_menu_open:
		get_tree().call_group("player_hud", "refresh_storage_menu")


## The teammate you're looking at, if they're close enough to hand things to.
func get_teammate_in_reach() -> Player:
	var looked_at := interactor.get_collider()
	if looked_at is Player and looked_at != inventory.player and not looked_at.is_downed \
			and looked_at.global_position.distance_to(inventory.player.global_position) <= 3.0:
		return looked_at
	return null