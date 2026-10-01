extends MeshInstance3D
## A small lamp that turns green when its puzzle is solved (a PuzzleGate output).

var is_lit := false

var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	material_override = _material
	_update()


## Called by a PuzzleGate on the host.
func puzzle_set(active: bool) -> void:
	if multiplayer.is_server():
		_set_lit.rpc(active)


@rpc("authority", "call_local", "reliable")
func _set_lit(value: bool) -> void:
	is_lit = value
	_update()


func _update() -> void:
	var color := Color(0.1, 1, 0.25) if is_lit else Color(0.9, 0.12, 0.05)
	_material.albedo_color = color
	_material.emission = color * 2.0
