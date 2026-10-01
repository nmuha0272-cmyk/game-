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
		"name": "Fuse", "shape": "cylinder", "size": Vector3(0.02, 0.08, 0),
		"color": Color(0.85, 0.8, 0.65),
		"hint": "Fits into fuse boxes to power doors and machines.",
	},
	"keycard_green": {
		"name": "Green Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.15, 0.6, 0.2),
		"hint": "Opens Green security doors. Just carry it.",
	},
	"keycard_yellow": {
		"name": "Yellow Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.85, 0.75, 0.1),
		"hint": "Opens Yellow (and Green) security doors. Just carry it.",
	},
	"keycard_red": {
		"name": "Red Keycard", "shape": "box", "size": Vector3(0.085, 0.006, 0.055),
		"color": Color(0.75, 0.1, 0.08),
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
		"hint": "Click to buzz whoever has the other walkie-talkie.",
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


## A simple placeholder 3D shape for the item (until real models in Phase 10).
static func make_mesh(id: String) -> MeshInstance3D:
	var info: Dictionary = INFO[id]
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
	return instance


## Size of a box that fits around the item (used for its collision shape).
static func get_bounds(id: String) -> Vector3:
	var info: Dictionary = INFO[id]
	if info.shape == "cylinder":
		return Vector3(info.size.x * 2.0, info.size.y, info.size.x * 2.0)
	return info.size
