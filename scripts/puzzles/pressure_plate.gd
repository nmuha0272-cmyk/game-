extends Area3D
## A heavy floor plate. Active while something heavy is on it: a player
## (even a downed one), heavy furniture, or a heavy item like a car battery.

signal active_changed(active: bool)

@export var plate_mesh: MeshInstance3D
## Playing alone (backup solution): the plate stays down this many seconds
## after you step off, so one player can still get through. 0 = off.
@export var solo_linger := 0.0

var is_active := false

var _material: StandardMaterial3D
var _linger_left := 0.0


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	if plate_mesh:
		plate_mesh.material_override = _material
	_update_visuals()


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var weighted := false
	for body in get_overlapping_bodies():
		if body is Player or body is HeavyObject:
			weighted = true
		elif "item" in body and Items.is_heavy(body.item):
			weighted = true
	if solo_linger > 0.0 and GameState.is_solo():
		if weighted:
			_linger_left = solo_linger
		elif _linger_left > 0.0:
			_linger_left -= delta
			weighted = true
	if weighted != is_active:
		_set_active.rpc(weighted)


@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	is_active = value
	_update_visuals()
	active_changed.emit(value)


func _update_visuals() -> void:
	var color := Color(0.15, 0.8, 0.25) if is_active else Color(0.5, 0.45, 0.2)
	_material.albedo_color = color
	_material.emission = color * 0.4
	if plate_mesh:
		plate_mesh.position.y = -0.03 if is_active else 0.0
