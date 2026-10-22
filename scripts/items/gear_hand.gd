extends Node3D
## Shows the selected gear item in your left hand (lower left of the screen).
## Every computer shows it, so you can see what teammates are holding.

@export var inventory: Inventory

var _shown_id := ""


func _ready() -> void:
	inventory.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var item: Dictionary = inventory.get_active_quick()
	# Weapons are shown by WeaponHand instead (in the right hand, when drawn).
	var id: String = "" if Items.is_weapon(item) else str(item.get("id", ""))
	if id == _shown_id:
		return
	_shown_id = id
	for child in get_children():
		child.queue_free()
	if id.is_empty():
		return
	# Same trick as the character's held item: the flashlight skips layer 2.
	add_child(Items.make_mesh(id, 2))
