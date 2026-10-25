extends SceneTree
## Exports Chapter 1 for the Unity version (unity/Deepwell/).
## Run from the project folder with Godot 4.7:
##     godot --headless -s tools/export_for_unity.gd
##
## Writes two files into unity/Deepwell/Assets/Resources/Levels/:
## - chapter1_level.glb   all the level's static geometry: the carved rock and
##   rooms (CSG, baked), walls, props, light fixtures, the forest. Meshes that
##   players should bump into are named "COL_..." so Unity gives them colliders.
## - chapter1.json        everything else Unity builds itself: lights, doors,
##   signs, spawn points, extra box colliders, the moon, fog and ambient light,
##   items, lore notes, checkpoints, story triggers and the Long Man's patrol.
##
## Godot and glTF are right-handed; Unity is left-handed. Unity's glTF importer
## (glTFast) flips X, so this file does the same for the JSON data:
## position (x, y, z) -> (-x, y, z), rotation quaternion (x, y, z, w) -> (x, -y, -z, w).

const LEVEL := "res://scenes/chapters/chapter_1/chapter_1.tscn"
const OUT_DIR := "res://unity/Deepwell/Assets/Resources/Levels/"
const DOOR_SCENE := "res://scenes/interactables/door.tscn"
## Groups of nodes that aren't static level geometry (players, items, triggers...).
const SKIP_BRANCHES := ["Players", "Items", "ItemSpawnPoints", "Monsters", "Triggers",
	"Checkpoints", "Cutscenes", "Sound", "SpawnPoints", "Navigation", "OpeningDialogue"]

var data := {"lights": [], "doors": [], "labels": [], "spawns": [], "colliders": [],
	"items": [], "lore": [], "lore_book": [], "checkpoints": [], "triggers": [], "monster": {},
	"moon": {}, "environment": {}}
var _export_root: Node3D
var _mesh_count := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var level: Node3D = load(LEVEL).instantiate()
	level.set_script(null)  # don't run the chapter's game logic
	root.add_child(level)
	for i in 6:
		await process_frame  # let the CSG shapes build their meshes

	_export_root = Node3D.new()
	_export_root.name = "Chapter1Level"
	root.add_child(_export_root)
	_walk(level, level)
	_add_lore_book()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(_export_root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(OUT_DIR + "chapter1_level.glb"))
	var file := FileAccess.open(OUT_DIR + "chapter1.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, " "))
	file.close()
	print("unity export: glb %s, %d meshes, %d lights, %d doors, %d labels, %d spawns, %d colliders" % [
		"ok" if err == OK else "FAILED (%d)" % err, _mesh_count, data.lights.size(), data.doors.size(),
		data.labels.size(), data.spawns.size(), data.colliders.size()])
	print("unity export: %d items, %d lore, %d checkpoints, %d triggers, monster %s (%d patrol points)" % [
		data.items.size(), data.lore.size(), data.checkpoints.size(), data.triggers.size(),
		"yes" if data.monster.has("p") else "no", data.monster.get("patrol", []).size()])
	quit()


# ---------------------------------------------------------------- conversions

func pos(p: Vector3) -> Array:
	return [snappedf(-p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001)]


func rot(b: Basis) -> Array:
	var q := b.orthonormalized().get_rotation_quaternion()
	return [snappedf(q.x, 0.0001), snappedf(-q.y, 0.0001), snappedf(-q.z, 0.0001), snappedf(q.w, 0.0001)]


func color(c: Color) -> Array:
	return [snappedf(c.r, 0.001), snappedf(c.g, 0.001), snappedf(c.b, 0.001), snappedf(c.a, 0.001)]


# ---------------------------------------------------------------- walking the level

func _walk(node: Node, level: Node) -> void:
	for child in node.get_children():
		if node == level and child.name in SKIP_BRANCHES:
			if child.name == "SpawnPoints":
				for s in child.get_children():
					if s is Node3D:
						data.spawns.append({"p": pos(s.global_position), "r": rot(s.global_basis)})
			elif child.name == "ItemSpawnPoints":
				for s in child.get_children():
					if s.get("item_id") != null:
						_add_item(s)
			elif child.name == "Checkpoints":
				for c in child.get_children():
					if c is Area3D:
						_add_checkpoint(c)
			elif child.name == "Triggers":
				for t in child.get_children():
					if t is Area3D and t.get("message") != null and str(t.get("message")) != "":
						data.triggers.append(_box_of(t).merged({"message": str(t.get("message")),
							"chase": t.get("monster") != null}))
			elif child.name == "Monsters":
				_add_monster(child)
			continue
		# Interactive things (doors, puzzles, lore, items) are scenes of their own.
		# Doors become data; the rest come in later phases.
		if child.scene_file_path != "":
			if child.get("entry") is LoreEntry:
				_add_lore(child)
			elif child.scene_file_path == DOOR_SCENE:
				data.doors.append({"name": str(child.name), "p": pos(child.global_position),
					"r": rot(child.global_basis), "puzzle": bool(child.get("puzzle_controlled")),
					"locked": child.get_node_or_null("Lock") != null})
			continue
		# Puzzle movers (the fence gate, shutters, flood water...) are exported already
		# open, like puzzle doors, until the puzzles come to Unity. Gates go all the way up.
		if child is AnimatableBody3D and child.get("open_offset") is Vector3:
			var offset: Vector3 = child.get("open_offset")
			if offset.y > 0.0:
				offset.y = maxf(offset.y, 2.7)
			child.sync_to_physics = false  # otherwise the physics engine keeps it where it was
			child.position += offset
		if child is CSGShape3D:
			if child.is_root_shape():
				_add_csg(child)
			continue  # its children are part of the same baked mesh
		if child is MultiMeshInstance3D:
			_add_multimesh(child)
		elif child is MeshInstance3D and child.mesh and child.is_visible_in_tree():
			_add_mesh(child.mesh, child.global_transform, _materials_of(child), str(child.name), false)
		elif child is OmniLight3D or child is SpotLight3D:
			_add_light(child)
		elif child is Label3D and child.is_visible_in_tree():
			_add_label(child)
		elif child is DirectionalLight3D:
			data.moon = {"r": rot(child.global_basis), "color": color(child.light_color), "energy": child.light_energy}
		elif child is WorldEnvironment and child.environment:
			var env: Environment = child.environment
			data.environment = {"ambient": color(env.ambient_light_color), "ambient_energy": env.ambient_light_energy,
				"fog": env.volumetric_fog_enabled or env.fog_enabled, "fog_density": env.volumetric_fog_density,
				"fog_color": color(env.volumetric_fog_albedo)}
		elif child is CollisionShape3D and child.shape and child.get_parent() is StaticBody3D:
			_add_collider(child)
		_walk(child, level)


func _materials_of(mi: MeshInstance3D) -> Array:
	var mats := []
	for s in mi.mesh.get_surface_count():
		var m: Material = mi.material_override
		if m == null:
			m = mi.get_surface_override_material(s)
		if m == null:
			m = mi.mesh.surface_get_material(s)
		mats.append(m)
	return mats


func _add_mesh(mesh: Mesh, xform: Transform3D, mats: Array, label: String, solid: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xform
	_mesh_count += 1
	mi.name = ("COL_" if solid else "") + "%s_%d" % [label.validate_node_name(), _mesh_count]
	for s in min(mats.size(), mesh.get_surface_count()):
		if mats[s]:
			mi.set_surface_override_material(s, mats[s])
	_export_root.add_child(mi)


func _add_csg(csg: CSGShape3D) -> void:
	var mesh: ArrayMesh = csg.bake_static_mesh()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	_add_mesh(mesh, csg.global_transform, [], str(csg.name), csg.use_collision)


## The forest: one mesh per tree part, with every tree merged in.
func _add_multimesh(mmi: MultiMeshInstance3D) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null:
		return
	for s in mm.mesh.get_surface_count():
		var st := SurfaceTool.new()
		for i in mm.instance_count:
			st.append_from(mm.mesh, s, mm.get_instance_transform(i))
		var merged := st.commit()
		var mat: Material = mmi.material_override if mmi.material_override else mm.mesh.surface_get_material(s)
		_add_mesh(merged, mmi.global_transform, [mat], str(mmi.name), false)


func _add_light(light: Light3D) -> void:
	var entry := {"p": pos(light.global_position), "r": rot(light.global_basis),
		"color": color(light.light_color), "energy": light.light_energy,
		"shadow": light.shadow_enabled, "spot": light is SpotLight3D,
		"flicker": float(light.get("brokenness")) if light.get("brokenness") != null else -1.0,
		"pulse": light.get_script() != null and str(light.get_script().resource_path).ends_with("pulsing_light.gd"),
		# lights inside a puzzle's light group start dark until the puzzle is solved
		"starts_off": light.get_parent() != null and light.get_parent().get_parent() != null \
			and light.get_parent().get_parent().name == "Puzzles"}
	if light is OmniLight3D:
		entry["range"] = light.omni_range
	else:
		entry["range"] = light.spot_range
		entry["angle"] = light.spot_angle
	data.lights.append(entry)


func _add_label(label: Label3D) -> void:
	data.labels.append({"p": pos(label.global_position), "r": rot(label.global_basis),
		"text": label.text, "size": label.pixel_size * label.font_size,
		"color": color(label.modulate), "billboard": label.billboard != BaseMaterial3D.BILLBOARD_DISABLED})


func _add_collider(cs: CollisionShape3D) -> void:
	var shape := cs.shape
	var entry := {"p": pos(cs.global_position), "r": rot(cs.global_basis)}
	if shape is BoxShape3D:
		entry["box"] = [shape.size.x, shape.size.y, shape.size.z]
	elif shape is CylinderShape3D:
		entry["cylinder"] = [shape.radius, shape.height]
	elif shape is CapsuleShape3D:
		entry["cylinder"] = [shape.radius, shape.height]
	else:
		return
	data.colliders.append(entry)


# ---------------------------------------------------------------- gameplay data

func _add_item(point: Node3D) -> void:
	var id := str(point.get("item_id"))
	var info: Dictionary = Items.INFO.get(id, {})
	var c: Color = info.get("color", Color(0.8, 0.8, 0.8))
	data.items.append({"id": id, "name": str(info.get("name", id.capitalize())),
		"hint": str(info.get("hint", "")), "color": color(c), "p": pos(point.global_position),
		"lore": str(point.get("lore_id"))})


func _add_lore(node: Node3D) -> void:
	var entry: LoreEntry = node.get("entry")
	data.lore.append({"id": entry.id, "title": entry.title, "text": entry.text,
		"kind": str(node.scene_file_path.get_file().get_basename()),
		"p": pos(node.global_position), "r": rot(node.global_basis)})


func _add_checkpoint(area: Area3D) -> void:
	var cp := _box_of(area)
	cp["order"] = int(area.get("order"))
	cp["name"] = str(area.name)
	var spawns := []
	for s in area.get_children():
		if s is Marker3D:
			spawns.append({"p": pos(s.global_position)})
	cp["spawns"] = spawns
	data.checkpoints.append(cp)


## An Area3D's first box shape, as a position, rotation and size.
func _box_of(area: Area3D) -> Dictionary:
	for cs in area.get_children():
		if cs is CollisionShape3D and cs.shape is BoxShape3D:
			var size: Vector3 = cs.shape.size
			return {"p": pos(cs.global_position), "r": rot(cs.global_basis), "size": [size.x, size.y, size.z]}
	return {"p": pos(area.global_position), "r": rot(area.global_basis), "size": [2, 2, 2]}


func _add_monster(monsters: Node) -> void:
	var patrol := []
	var points := monsters.get_node_or_null("PatrolPoints")
	if points:
		for p in points.get_children():
			if p is Node3D:
				patrol.append({"p": pos(p.global_position)})
	var long_man := monsters.get_node_or_null("LongMan") as Node3D
	if long_man == null:
		return
	data.monster = {"p": pos(long_man.global_position), "r": rot(long_man.global_basis), "patrol": patrol,
		"patrol_speed": long_man.get("patrol_speed"), "investigate_speed": long_man.get("investigate_speed"),
		"chase_speed": long_man.get("chase_speed"), "catch_distance": long_man.get("catch_distance"),
		"catch_cooldown": long_man.get("catch_cooldown")}


## Every lore entry in res://lore/, so reel tapes can play theirs.
func _add_lore_book() -> void:
	for file in DirAccess.get_files_at("res://lore/"):
		if file.ends_with(".tres"):
			var entry := load("res://lore/" + file) as LoreEntry
			if entry:
				data.lore_book.append({"id": entry.id, "title": entry.title, "text": entry.text})
