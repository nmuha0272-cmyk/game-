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
	# --- Pack upgrades: found in the world, click to wear. They never go
	# away, they just make the inventory bigger (see Inventory.MAX_SLOTS).
	"pouch": {
		"name": "Field Pouch", "shape": "box", "size": Vector3(0.17, 0.13, 0.08),
		"color": Color(0.42, 0.34, 0.2),
		"hint": "Click to strap it on: adds 1 gear slot (up to 8).",
		"extra": {"pack_slots": 1},
	},
	"backpack": {
		"name": "Backpack", "shape": "box", "size": Vector3(0.26, 0.34, 0.16),
		"color": Color(0.24, 0.32, 0.24),
		"hint": "Click to strap it on: adds 2 gear slots (up to 8).",
		"extra": {"pack_slots": 2},
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
	"fuel_can": {
		"name": "Fuel Can", "shape": "box", "size": Vector3(0.28, 0.36, 0.16),
		"color": Color(0.7, 0.12, 0.08),
		"hint": "Fuel for the power room generator.",
	},
	"ammo_38": {
		"name": ".38 Speedloader", "shape": "box", "size": Vector3(0.04, 0.11, 0.04),
		"color": Color(0.75, 0.65, 0.3), "shiny": true,
		"hint": "Reloads your .38 Revolver. Click to add to your gun.",
		"extra": {"ammo_type": "38", "rounds": 6},
	},
	"ammo_9mm": {
		"name": "9mm Mag", "shape": "box", "size": Vector3(0.035, 0.13, 0.025),
		"color": Color(0.6, 0.6, 0.62), "shiny": true,
		"hint": "Reloads 9mm weapons. Click to add to your gun.",
		"extra": {"ammo_type": "9mm", "rounds": 15},
	},
	"ammo_12ga": {
		"name": "12ga Shells", "shape": "cylinder", "size": Vector3(0.02, 0.11, 0),
		"color": Color(0.7, 0.2, 0.12),
		"hint": "Reloads the shotgun. Click to add to your gun.",
		"extra": {"ammo_type": "12ga", "rounds": 6},
	},
	"ammo_308": {
		"name": ".308 Stripper Clip", "shape": "box", "size": Vector3(0.02, 0.12, 0.02),
		"color": Color(0.7, 0.55, 0.25), "shiny": true,
		"hint": "Reloads the bolt-action rifle. Click to add to your gun.",
		"extra": {"ammo_type": "308", "rounds": 5},
	},
	"ammo_dart": {
		"name": "Tranq Dart", "shape": "cylinder", "size": Vector3(0.015, 0.12, 0),
		"color": Color(0.3, 0.7, 0.6), "shiny": true,
		"hint": "Reloads the tranquilizer gun. Click to add to your gun.",
		"extra": {"ammo_type": "dart", "rounds": 1},
	},
	"ammo_flare_shell": {
		"name": "Flare Shell", "shape": "cylinder", "size": Vector3(0.022, 0.09, 0),
		"color": Color(0.8, 0.25, 0.1),
		"hint": "Reloads the flare gun. Click to add to your gun.",
		"extra": {"ammo_type": "flare_shell", "rounds": 1},
	},
	# --- Weapons lying in the world (armories, dead security). Picking one up
	# puts it in your single weapon slot; you can drop it again like any item.
	"weapon_revolver": {
		"name": ".38 Revolver", "shape": "box", "size": Vector3(0.24, 0.14, 0.05),
		"color": Color(0.32, 0.3, 0.3),
		"hint": "Pick it up to arm yourself. Draw it with 4.",
		"extra": {"weapon": "revolver", "loaded": 6, "reserve": {"38": 6}},
	},
	"weapon_pistol": {
		"name": "9mm Pistol", "shape": "box", "size": Vector3(0.24, 0.14, 0.05),
		"color": Color(0.28, 0.28, 0.3),
		"hint": "Pick it up to arm yourself. Draw it with 4.",
		"extra": {"weapon": "pistol", "loaded": 15, "reserve": {"9mm": 15}},
	},
	"weapon_suppressed_9mm": {
		"name": "Suppressed 9mm", "shape": "box", "size": Vector3(0.34, 0.14, 0.05),
		"color": Color(0.22, 0.24, 0.24),
		"hint": "Quiet. Pick it up to arm yourself.",
		"extra": {"weapon": "suppressed_9mm", "loaded": 12, "reserve": {"9mm": 12}},
	},
	"weapon_shotgun": {
		"name": "12ga Shotgun", "shape": "box", "size": Vector3(0.55, 0.14, 0.05),
		"color": Color(0.3, 0.22, 0.16),
		"hint": "Devastating up close. Pick it up to arm yourself.",
		"extra": {"weapon": "shotgun", "loaded": 6, "reserve": {"12ga": 6}},
	},
	"weapon_smg": {
		"name": "SMG", "shape": "box", "size": Vector3(0.4, 0.18, 0.06),
		"color": Color(0.2, 0.2, 0.22),
		"hint": "Full auto. Pick it up to arm yourself.",
		"extra": {"weapon": "smg", "loaded": 30, "reserve": {"9mm": 30}},
	},
	"weapon_rifle": {
		"name": "Bolt-Action Rifle", "shape": "box", "size": Vector3(0.6, 0.14, 0.05),
		"color": Color(0.26, 0.2, 0.14),
		"hint": "High damage at range. Pick it up to arm yourself.",
		"extra": {"weapon": "rifle", "loaded": 5, "reserve": {"308": 5}},
	},
	"weapon_tranq": {
		"name": "Tranquilizer Gun", "shape": "box", "size": Vector3(0.28, 0.14, 0.05),
		"color": Color(0.2, 0.32, 0.3),
		"hint": "Stuns a monster. Pick it up to arm yourself.",
		"extra": {"weapon": "tranq", "loaded": 1, "reserve": {"dart": 1}},
	},
	"weapon_flare_gun": {
		"name": "Flare Gun", "shape": "box", "size": Vector3(0.24, 0.16, 0.05),
		"color": Color(0.5, 0.2, 0.12),
		"hint": "Lights the area and draws monsters. Pick it up to arm yourself.",
		"extra": {"weapon": "flare_gun", "loaded": 1, "reserve": {"flare_shell": 1}},
	},
	# --- Craftable Melee Weapons ---
	"weapon_improvised_axe": {
		"name": "Improvised Axe", "shape": "box", "size": Vector3(0.6, 0.18, 0.08),
		"color": Color(0.35, 0.25, 0.15),
		"hint": "Pipe with an axe head taped on. High damage, slow.",
		"extra": {"weapon": "improvised_axe", "durability": 150, "max_durability": 150},
	},
	"weapon_machete": {
		"name": "Machete", "shape": "box", "size": Vector3(0.5, 0.1, 0.04),
		"color": Color(0.25, 0.25, 0.28),
		"hint": "Fast, causes bleeding.",
		"extra": {"weapon": "machete", "durability": 120, "max_durability": 120},
	},
	"weapon_gear_axe": {
		"name": "Gear Axe", "shape": "box", "size": Vector3(0.7, 0.22, 0.1),
		"color": Color(0.3, 0.3, 0.35),
		"hint": "Heavy industrial axe. Pierces armor.",
		"extra": {"weapon": "gear_axe", "durability": 180, "max_durability": 180},
	},
	# --- Crafting Ingredients ---
	"bandage": {
		"name": "Bandage", "shape": "box", "size": Vector3(0.08, 0.04, 0.02),
		"color": Color(0.9, 0.9, 0.85),
		"hint": "Crafting ingredient. Combine with Antiseptic to make a Med Kit.",
		"extra": {"max_stack": 10},
	},
	"antiseptic": {
		"name": "Antiseptic", "shape": "cylinder", "size": Vector3(0.025, 0.08, 0),
		"color": Color(0.6, 0.8, 0.9),
		"hint": "Crafting ingredient. Combine with Bandage to make a Med Kit.",
		"extra": {"max_stack": 10},
	},
	"gunpowder": {
		"name": "Gunpowder", "shape": "cylinder", "size": Vector3(0.04, 0.1, 0),
		"color": Color(0.2, 0.18, 0.15),
		"hint": "Crafting ingredient. Combine with Empty Shells to make Ammo.",
		"extra": {"max_stack": 10},
	},
	"empty_shells": {
		"name": "Empty Shells", "shape": "box", "size": Vector3(0.06, 0.04, 0.06),
		"color": Color(0.65, 0.55, 0.4),
		"hint": "Crafting ingredient. Combine with Gunpowder to make Ammo.",
		"extra": {"max_stack": 10},
	},
	"duct_tape": {
		"name": "Duct Tape", "shape": "cylinder", "size": Vector3(0.05, 0.03, 0),
		"color": Color(0.7, 0.6, 0.2),
		"hint": "Crafting ingredient. Used in many recipes.",
		"extra": {"max_stack": 10},
	},
	"pipe": {
		"name": "Pipe", "shape": "cylinder", "size": Vector3(0.03, 0.4, 0),
		"color": Color(0.4, 0.35, 0.3),
		"hint": "Crafting ingredient. Base for melee weapons.",
		"extra": {"max_stack": 10},
	},
	"alarm_clock": {
		"name": "Alarm Clock", "shape": "box", "size": Vector3(0.1, 0.08, 0.1),
		"color": Color(0.5, 0.5, 0.55),
		"hint": "Crafting ingredient. Combine with Battery to make a Sound Lure.",
		"extra": {"max_stack": 5},
	},
	"cloth": {
		"name": "Cloth", "shape": "box", "size": Vector3(0.15, 0.02, 0.1),
		"color": Color(0.8, 0.75, 0.7),
		"hint": "Crafting ingredient. Combine with Alcohol + Lighter for Fire Bottle.",
		"extra": {"max_stack": 10},
	},
	"alcohol": {
		"name": "Alcohol", "shape": "cylinder", "size": Vector3(0.04, 0.15, 0),
		"color": Color(0.7, 0.85, 0.95),
		"hint": "Crafting ingredient. Combine with Cloth + Lighter for Fire Bottle.",
		"extra": {"max_stack": 10},
	},
	"lighter": {
		"name": "Lighter", "shape": "box", "size": Vector3(0.03, 0.05, 0.015),
		"color": Color(0.2, 0.2, 0.2),
		"hint": "Crafting ingredient. Combine with Cloth + Alcohol for Fire Bottle.",
		"extra": {"max_stack": 5},
	},
	"axe_head": {
		"name": "Axe Head", "shape": "box", "size": Vector3(0.18, 0.12, 0.04),
		"color": Color(0.35, 0.35, 0.38),
		"hint": "Crafting ingredient. Combine with Pipe + Duct Tape for Improvised Axe.",
		"extra": {"max_stack": 5},
	},
	"scrap_metal": {
		"name": "Scrap Metal", "shape": "box", "size": Vector3(0.12, 0.08, 0.04),
		"color": Color(0.45, 0.45, 0.48),
		"hint": "Crafting ingredient. Combine for Machete.",
		"extra": {"max_stack": 10},
	},
	"heavy_pipe": {
		"name": "Heavy Pipe", "shape": "cylinder", "size": Vector3(0.05, 0.5, 0),
		"color": Color(0.3, 0.28, 0.25),
		"hint": "Crafting ingredient. Combine with Gears + Duct Tape for Gear Axe.",
		"extra": {"max_stack": 5},
	},
	"gears": {
		"name": "Gears", "shape": "box", "size": Vector3(0.08, 0.08, 0.03),
		"color": Color(0.4, 0.4, 0.42),
		"hint": "Crafting ingredient. Combine with Heavy Pipe + Duct Tape for Gear Axe.",
		"extra": {"max_stack": 5},
	},
	# --- Recipe Notes (pickup to unlock for team) ---
	"recipe_ammo": {
		"name": "Note: Ammo Recipe", "shape": "paper",
		"color": Color(0.8, 0.75, 0.5),
		"hint": "Shows how to craft ammo: Gunpowder + Empty Shells.",
		"extra": {"recipe_unlock": "ammo"},
	},
	"recipe_axe": {
		"name": "Note: Axe Recipe", "shape": "paper",
		"color": Color(0.8, 0.75, 0.5),
		"hint": "Shows how to craft an Improvised Axe: Pipe + Axe Head + Duct Tape.",
		"extra": {"recipe_unlock": "improvised_axe"},
	},
	"recipe_machete": {
		"name": "Note: Machete Recipe", "shape": "paper",
		"color": Color(0.8, 0.75, 0.5),
		"hint": "Shows how to craft a Machete: Scrap Metal x2 + Duct Tape + Pipe.",
		"extra": {"recipe_unlock": "machete"},
	},
	"recipe_gear_axe": {
		"name": "Note: Gear Axe Recipe", "shape": "paper",
		"color": Color(0.8, 0.75, 0.5),
		"hint": "Shows how to craft a Gear Axe: Heavy Pipe + Gears + Duct Tape.",
		"extra": {"recipe_unlock": "gear_axe"},
	},
	# --- Throwable Outputs ---
	"sound_lure": {
		"name": "Sound Lure", "shape": "cylinder", "size": Vector3(0.06, 0.12, 0),
		"color": Color(0.7, 0.6, 0.2),
		"hint": "Throw to create a loud noise distraction for 8 seconds.",
		"extra": {"throwable": "sound_lure"},
	},
	"fire_bottle": {
		"name": "Fire Bottle", "shape": "cylinder", "size": Vector3(0.07, 0.18, 0),
		"color": Color(0.8, 0.2, 0.1),
		"hint": "Throw to create a wall of fire monsters won't cross for 8 seconds.",
		"extra": {"throwable": "fire_bottle"},
	},
	# --- Melee Outputs (reinforced pipe) ---
	"reinforced_pipe": {
		"name": "Reinforced Pipe", "shape": "cylinder", "size": Vector3(0.04, 0.55, 0),
		"color": Color(0.45, 0.35, 0.25),
		"hint": "Pipe wrapped in duct tape. 2x durability.",
		"extra": {"weapon": "reinforced_pipe", "durability": 200, "max_durability": 200},
	},
}

## How much slower everyone except the Guard moves while carrying something heavy.
const HEAVY_SPEED_MULTIPLIER := 0.55


## A fresh item of this type, ready to put in an inventory.
static func create(id: String) -> Dictionary:
	var item := {"id": id}
	# Deep copy: nested data (like a gun's spare ammo) must not be shared.
	item.merge(INFO[id].get("extra", {}).duplicate(true))
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


## True if the item in hand is a weapon (gun or melee).
static func is_weapon(item: Dictionary) -> bool:
	return not item.is_empty() and item.has("weapon")


## True if the item is an ammo box (ammo_38, ammo_9mm, etc.).
static func is_ammo(item: Dictionary) -> bool:
	return not item.is_empty() and item.id.begins_with("ammo_")


## The weapon id inside a weapon item ("" if it isn't one).
static func weapon_id(item: Dictionary) -> String:
	return str(item.get("weapon", "")) if is_weapon(item) else ""


## True if the weapon is a melee weapon (vs firearm).
static func is_melee(item: Dictionary) -> bool:
	if not is_weapon(item):
		return false
	var w_id := weapon_id(item)
	return Weapons.is_melee(w_id)


## The item's 3D look: its real model if it has one (see "model"), sized to
## fit, or else a simple shape. layers: which render layers it's drawn on.
static func make_mesh(id: String, layers := 1) -> Node3D:
	var info: Dictionary = INFO[id]
	if info.has("weapon"):
		return Weapons.make_mesh(str(info.weapon))
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
