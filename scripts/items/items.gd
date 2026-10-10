class_name Items
## Every gear item in the game, in one place. An item in an inventory is a
## small Dictionary like {"id": "gas_mask", "filter": 45.0}.

const INFO := {
	"battery": {
		"name": "Battery", "shape": "cylinder", "size": Vector3(0.025, 0.09, 0),
		"color": Color(0.85, 0.7, 0.15),
		"hint": "Click to recharge your flashlight.",
	},
	"fuse": {
		"name": "Fuse", "shape": "cylinder", "size": Vector3(0.025, 0.1, 0),
		"color": Color(0.85, 0.8, 0.65), "model": "res://assets/models/props/fuse.glb",
		"hint": "Fits into fuse boxes to power doors and machines.",
	},
	"keycard_green": {
		"name": "Green Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.15, 0.6, 0.2), "model": "res://assets/models/props/card_a.glb", "model_turn": Vector3(-90, 0, 0),
		"hint": "Opens Green security doors. Just carry it.",
	},
	"keycard_yellow": {
		"name": "Yellow Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.85, 0.75, 0.1), "model": "res://assets/models/props/card_b.glb", "model_turn": Vector3(-90, 90, 0),
		"hint": "Opens Yellow (and Green) security doors. Just carry it.",
	},
	"keycard_red": {
		"name": "Red Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.75, 0.1, 0.08), "model": "res://assets/models/props/card_a.glb", "model_turn": Vector3(-90, 0, 0),
		"tint": Color(1.0, 0.25, 0.2),
		"hint": "Opens every security door. Just carry it.",
	},
	"crowbar": {
		"name": "Crowbar", "shape": "box", "size": Vector3(0.025, 0.6, 0.025),
		"color": Color(0.55, 0.12, 0.08),
		"hint": "Pries open jammed doors (breaks after one use).",
	},
	"flare": {
		"name": "Flare", "shape": "cylinder", "size": Vector3(0.02, 0.22, 0),
		"color": Color(0.8, 0.15, 0.1),
		"hint": "Click to throw. Lights the area and distracts monsters for 10 seconds.",
	},
	"medkit": {
		"name": "Med Kit", "shape": "box", "size": Vector3(0.2, 0.12, 0.08),
		"color": Color(0.85, 0.85, 0.82),
		"hint": "Click while looking at a downed teammate up close to revive them.",
	},
	"gas_mask": {
		"name": "Gas Mask", "shape": "box", "size": Vector3(0.18, 0.16, 0.12),
		"color": Color(0.2, 0.26, 0.2),
		"hint": "Protects you in toxic gas while the filter lasts. Just carry it.",
		"extra": {"filter": 45.0},
	},
	"walkie": {
		"name": "Walkie-Talkie", "shape": "box", "size": Vector3(0.06, 0.18, 0.04),
		"color": Color(0.1, 0.1, 0.1),
		"hint": "Click to radio your team (they see where you are). Careful: the Long Man hears the static!",
	},
	"reel_tape": {
		"name": "Reel Tape", "shape": "cylinder", "size": Vector3(0.07, 0.02, 0),
		"color": Color(0.35, 0.22, 0.12),
		"hint": "Play it on a tape machine to hear what's on it.",
	},
	"car_battery": {
		"name": "Car Battery", "shape": "box", "size": Vector3(0.32, 0.22, 0.18),
		"color": Color(0.12, 0.12, 0.14),
		"hint": "Heavy! Powers a heavy machine. Only the Guard can carry it at full speed.",
		"heavy": true,
	},
}

## How much slower everyone except the Guard moves while carrying something heavy.
const HEAVY_SPEED_MULTIPLIER := 0.55


## A fresh item of this type, ready to put in an inventory.
static func create(id: String) -> Dictionary:
	var item := {"id": id}
	item.merge(INFO[id].get("extra", {}).duplicate())
	return item


static func display_name(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var text: String = INFO[item.id].name
	if item.has("filter"):
		text += " (%ds)" % ceili(item.filter)
	return text


static func is_heavy(item: Dictionary) -> bool:
	return not item.is_empty() and INFO[item.id].get("heavy", false)


## The item's 3D look: its real model if it has one (see "model"), sized to
## fit, or else a simple shape. layers: which render layers it's drawn on.
static func make_mesh(id: String, layers := 1) -> Node3D:
	var info: Dictionary = INFO[id]
	if info.has("model") and ResourceLoader.exists(info.model):
		var model := fit_model(info.model, get_bounds(id), info.get("model_turn", Vector3.ZERO), info.get("tint", Color.WHITE))
		for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			part.layers = layers
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return model
	var instance := MeshInstance3D.new()
	if info.shape == "cylinder":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = info.size.x
		cylinder.bottom_radius = info.size.x
		cylinder.height = info.size.y
		instance.mesh = cylinder
	else:
		var box := BoxMesh.new()
		box.size = info.size
		instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = info.color
	material.roughness = 0.6
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.layers = layers
	return instance


## A model (.glb) turned by `turn` (degrees) and shrunk so its longest side
## matches the longest side of `bounds`, centred on the origin.
static func fit_model(path: String, bounds: Vector3, turn := Vector3.ZERO, tint := Color.WHITE) -> Node3D:
	var holder := Node3D.new()
	var model: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(model)
	var box := AABB()
	var first := true
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var node: Node = part
		while node != model and node is Node3D:
			xf = (node as Node3D).transform * xf
			node = node.get_parent()
		var part_box := xf * part.get_aabb()
		box = part_box if first else box.merge(part_box)
		first = false
		if tint != Color.WHITE and part.mesh:
			for i in part.mesh.get_surface_count():
				var mat := part.mesh.surface_get_material(i)
				if mat is StandardMaterial3D:
					var tinted := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					tinted.albedo_color = tinted.albedo_color * tint
					part.set_surface_override_material(i, tinted)
	var turn_basis := Basis.from_euler(turn * (PI / 180.0))
	var turned := Transform3D(turn_basis) * box
	var longest := maxf(turned.size.x, maxf(turned.size.y, turned.size.z))
	var scale := maxf(bounds.x, maxf(bounds.y, bounds.z)) / maxf(longest, 0.0001)
	model.transform = Transform3D(turn_basis.scaled(Vector3.ONE * scale), -turned.get_center() * scale)
	return holder


## Size of a box that fits around the item (used for its collision shape).
static func get_bounds(id: String) -> Vector3:
	var info: Dictionary = INFO[id]
	if info.shape == "cylinder":
		return Vector3(info.size.x * 2.0, info.size.y, info.size.x * 2.0)
	return info.size
