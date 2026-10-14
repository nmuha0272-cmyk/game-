extends Node3D
## Shows the player's gun in their hand while it's drawn, and hides it when
## holstered. Built from boxes for now (no animations yet).

@export var weapon: WeaponHolder

var _shown := ""


func _ready() -> void:
	if weapon:
		weapon.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var id := weapon.weapon_id if weapon and weapon.drawn else ""
	if id == _shown:
		return
	_shown = id
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if id.is_empty() or not Weapons.INFO.has(id):
		return
	var mesh := Weapons.make_mesh(id)
	add_child(mesh)
