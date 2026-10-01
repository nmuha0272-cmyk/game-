extends Node3D
## Shows the selected gear item in your left hand (lower left of the screen).
## Every computer shows it, so you can see what teammates are holding.

@export var inventory: Inventory

var _shown_id := ""


func _ready() -> void:
	inventory.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var item := inventory.get_active_item()
	var id: String = item.get("id", "")
	if id == _shown_id:
		return
	_shown_id = id
	for child in get_children():
		child.queue_free()
	if id.is_empty():
		return
	var mesh := Items.make_mesh(id)
	# Same trick as the character's held item: the flashlight skips this layer.
	mesh.layers = 2
	add_child(mesh)
