extends Node3D
## Shows the player's weapon in their hand while it's drawn (4), and hides it
## when holstered. The weapon is the item in the active quick slot.
## Built from boxes for now (no animations yet).
##
## When a monster is nearby, the weapon shakes with fear. Nora (journalist,
## not a soldier) shakes hardest.

@export var controls: Node
@export var inventory: Inventory

var _shown := ""
var _rng := RandomNumberGenerator.new()
var _base_position := Vector3.ZERO


func _ready() -> void:
	if inventory:
		inventory.changed.connect(_refresh)
	_rng.seed = Time.get_ticks_msec().to_int() ^ inventory.player.name.to_int()
	_base_position = position
	_refresh()


func _process(_delta: float) -> void:
	# Drawing/holstering doesn't change the inventory, so check each frame
	# (cheap: it only rebuilds when the answer changes).
	_refresh()

	# Shake the weapon with fear when a monster is near.
	var fear := inventory.player.get_meta("fear", 0.0)
	if fear > 0.05:
		var shake := fear
		if inventory.player.character == Characters.Id.JOURNALIST:
			shake *= 1.8  # Nora shakes hardest - not trained with guns
		elif inventory.player.character == Characters.Id.SON:
			shake *= 0.6  # Eli's Army Reserve training steadies him
		shake = clampf(shake, 0.0, 1.0)
		var amp := shake * 0.10
		position = _base_position + Vector3(
			_rng.randf_range(-amp, amp),
			_rng.randf_range(-amp, amp),
			_rng.randf_range(-amp, amp))
	else:
		position = _base_position


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
