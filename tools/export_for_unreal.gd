extends SceneTree
## Exports Chapter 1's layout to unreal/SubjectZero/Content/Data/chapter1.json,
## so the Unreal version builds the exact same level.
## Run:  godot --headless -s tools/export_for_unreal.gd
##
## Godot uses meters, Y up, forward = -Z. Unreal uses centimeters, Z up,
## forward = +X. So a Godot point (x, y, z) becomes Unreal (-z, x, y) * 100.

const OUT := "res://unreal/SubjectZero/Content/Data/chapter1.json"
const DOOR_SCENE := "res://scenes/interactables/door.tscn"

var data := {"rock": [], "shapes": [], "lights": [], "doors": [], "spawns": [], "labels": [], "trees": [], "moon": {}}


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var level: Node3D = load("res://scenes/chapters/chapter_1/chapter_1.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	_walk(level, level)
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("exported: rock %d, shapes %d, lights %d, doors %d, trees %d, labels %d" % [
		data.rock.size(), data.shapes.size(), data.lights.size(), data.doors.size(), data.trees.size(), data.labels.size()])
	quit()


# ---------------------------------------------------------------- conversions

func pos(p: Vector3) -> Array:
	return [snappedf(-p.z * 100.0, 0.1), snappedf(p.x * 100.0, 0.1), snappedf(p.y * 100.0, 0.1)]


func vec(v: Vector3) -> Array:
	return [snappedf(-v.z, 0.0001), snappedf(v.x, 0.0001), snappedf(v.y, 0.0001)]


## A Godot box of size (sx, sy, sz) along its local x, y, z becomes an Unreal
## box whose local X = Godot local -Z, Y = Godot local X, Z = Godot local Y.
func frame(t: Transform3D, size: Vector3) -> Dictionary:
	var b := t.basis
	var sx := b.x.length(); var sy := b.y.length(); var sz := b.z.length()
	return {
		"p": pos(t.origin),
		"x": vec(-b.z.normalized()),
		"z": vec(b.y.normalized()),
		"s": [snappedf(size.z * sz * 100.0, 0.1), snappedf(size.x * sx * 100.0, 0.1), snappedf(size.y * sy * 100.0, 0.1)],
	}


func material_name(mat: Material) -> String:
	if mat == null:
		return "#808080"
	if mat.resource_path.begins_with("res://assets/materials/"):
		return mat.resource_path.get_file().get_basename()
	if mat is StandardMaterial3D:
		var c: Color = mat.albedo_color
		if mat.emission_enabled:
			return "!" + mat.emission.to_html(false)  # "!" = glowing
		return "#" + c.to_html(false)
	return "#808080"


# ---------------------------------------------------------------- walking the scene

func _walk(node: Node, level: Node) -> void:
	if node.name == "Rock":
		for part in node.get_children():
			if part is CSGBox3D:
				var f := frame(part.global_transform, part.size)
				f["op"] = "subtract" if part.operation == CSGShape3D.OPERATION_SUBTRACTION else "union"
				data.rock.append(f)
		return
	if node != level and node.scene_file_path != "":
		if node.scene_file_path == DOOR_SCENE:
			_add_door(node)
		return  # other gameplay scenes (puzzles, lore, monster) come in later phases
	var path := String(level.get_path_to(node))
	if path.begins_with("Puzzles/") and not path.begins_with("Puzzles/Elevator") and not path.begins_with("Puzzles/RoomLights"):
		for child in node.get_children():
			_walk(child, level)
		return
	if path.begins_with("Puzzles/Elevator/Gate") or path.begins_with("Puzzles/Elevator/DescendButton"):
		return
	if path == "SpawnPoints":
		for spawn in node.get_children():
			data.spawns.append({"p": pos(spawn.global_position), "yaw": -spawn.global_rotation_degrees.y})
		return

	if node is CSGBox3D:
		_shape("cube", node, node.size, node.material, node.use_collision)
	elif node is CSGCylinder3D:
		_shape("cylinder", node, Vector3(node.radius * 2, node.height, node.radius * 2), node.material, node.use_collision)
	elif node is CSGSphere3D:
		_shape("sphere", node, Vector3.ONE * node.radius * 2, node.material, node.use_collision)
	elif node is MultiMeshInstance3D:
		_add_trees(node)
	elif node is MeshInstance3D and node.mesh:
		_add_mesh(node, path.begins_with("Puzzles/Elevator"))
	elif node is OmniLight3D and node.is_visible_in_tree():
		data.lights.append({"p": pos(node.global_position), "color": node.light_color.to_html(false),
			"energy": node.light_energy, "range": node.omni_range * 100.0, "shadow": node.shadow_enabled,
			"flicker": node.get("brokenness") if node.get("brokenness") != null else -1.0,
			"pulse": node.get_script() != null and String(node.get_script().resource_path).ends_with("pulsing_light.gd")})
	elif node is DirectionalLight3D:
		data.moon = {"dir": vec(-node.global_basis.z), "color": node.light_color.to_html(false), "energy": node.light_energy}
	elif node is Label3D:
		var f := frame(node.global_transform, Vector3.ONE)
		data.labels.append({"p": f.p, "x": f.x, "z": f.z, "text": node.text, "color": node.modulate.to_html(false),
			"size": node.pixel_size * node.font_size * 100.0})

	for child in node.get_children():
		_walk(child, level)


func _shape(kind: String, node: Node3D, size: Vector3, mat: Material, collide: bool) -> void:
	var f := frame(node.global_transform, size)
	f["t"] = kind
	f["m"] = material_name(mat)
	f["c"] = collide
	data.shapes.append(f)


func _add_mesh(node: MeshInstance3D, collide: bool) -> void:
	var mesh := node.mesh
	var mat := node.get_surface_override_material(0)
	if mat == null:
		mat = node.material_override
	if mesh is BoxMesh:
		_shape("cube", node, mesh.size, mat, collide)
	elif mesh is PlaneMesh:
		_shape("cube", node, Vector3(mesh.size.x, 0.01, mesh.size.y), mat, false)
	elif mesh is SphereMesh:
		_shape("sphere", node, Vector3(mesh.radius * 2, mesh.height, mesh.radius * 2), mat, false)
	elif mesh is CylinderMesh:
		var kind := "cone" if mesh.top_radius < 0.01 else "cylinder"
		var r: float = maxf(mesh.top_radius, mesh.bottom_radius)
		_shape(kind, node, Vector3(r * 2, mesh.height, r * 2), mat, false)
	elif mesh is ArrayMesh and String(mesh.resource_path).contains("/prop_"):
		# A sculpted prop (barrel, crate, desk...): send a simple stand-in shape
		# of the same size (barrels as cylinders, the rest as boxes).
		var box := mesh.get_aabb()
		var holder := Node3D.new()
		node.add_child(holder)
		holder.position = box.get_center()
		var kind := "cylinder" if String(mesh.resource_path).contains("barrel") else "cube"
		var solid: bool = node.get_parent() is StaticBody3D and node.get_parent().get_child_count() > 1
		_shape(kind, holder, box.size, mat, solid)
		holder.queue_free()


## The forest: every tree part becomes a list of instances.
func _add_trees(node: MultiMeshInstance3D) -> void:
	var mm := node.multimesh
	var mesh: CylinderMesh = mm.mesh
	var kind := "cone" if mesh.top_radius < 0.01 else "cylinder"
	var r: float = maxf(mesh.top_radius, mesh.bottom_radius)
	var part := {"t": kind, "m": material_name(node.material_override), "items": []}
	# Headless Godot doesn't keep MultiMesh transforms, so read them from the
	# saved scene file (12 numbers per tree: the basis rows, then origin).
	var values := _multimesh_buffer(mm.resource_path.get_slice("::", 1))
	for i in values.size() / 12:
		var v := values.slice(i * 12, i * 12 + 12)
		var basis := Basis(Vector3(v[0], v[4], v[8]), Vector3(v[1], v[5], v[9]), Vector3(v[2], v[6], v[10]))
		var t := node.global_transform * Transform3D(basis, Vector3(v[3], v[7], v[11]))
		part.items.append(frame(t, Vector3(r * 2, mesh.height, r * 2)))
	data.trees.append(part)


func _multimesh_buffer(sub_id: String) -> Array:
	var text := FileAccess.get_file_as_string("res://scenes/chapters/chapter_1/chapter_1.tscn")
	var start := text.find('id="%s"]' % sub_id)
	var b := text.find("buffer = PackedFloat32Array(", start)
	var e := text.find(")", b)
	var numbers := text.substr(b + 28, e - b - 28).split(",")
	return Array(numbers).map(func(n: String) -> float: return n.to_float())


func _add_door(door: Node3D) -> void:
	data.doors.append({
		"p": pos(door.global_position),
		"yaw": snappedf(-door.global_rotation_degrees.y, 0.1),
		"puzzle": door.puzzle_controlled,
		"keycard": door.has_node("Lock"),
		"name": String(door.name),
	})
