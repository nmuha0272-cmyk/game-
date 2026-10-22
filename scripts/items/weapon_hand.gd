extends Node3D
## Shows the player's weapon in their hand while it's drawn (4), and hides it
## when holstered. The weapon is the item in the active quick slot.
## Built from boxes for now (no animations yet).

@export var controls: Node
@export var inventory: Inventory

var _shown := ""


func _ready() -> void:
	if inventory:
		inventory.changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	# Drawing/holstering doesn't change the inventory, so check each frame
	# (cheap: it only rebuilds when the answer changes).
	_refresh()


func _refresh() -> void:
	var item: Dictionary = inventory.get_active_quick() if inventory else {}
	var drawn: bool = controls != null and controls.get("_drawn") == true
	var id: String = Items.weapon_id(item) if drawn else ""
	if id == _shown:
		return
	_shown = id
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if id.is_empty() or not Weapons.INFO.has(id):
		return
	add_child(Weapons.make_mesh(id))
