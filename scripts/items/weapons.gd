class_name Weapons
## Every weapon in the game (firearms + melee). See GAME_PLAN.md for design.

const INFO := {
	"revolver": {
		"name": ".38 Revolver", "ammo": "38", "capacity": 6, "damage": 34.0,
		"noise": 30.0, "fire_delay": 0.45, "reload_time": 2.5, "auto": false,
		"pellets": 1, "hint": "Common sidearm. Loud.",
	},
	"pistol": {
		"name": "9mm Pistol", "ammo": "9mm", "capacity": 15, "damage": 22.0,
		"noise": 26.0, "fire_delay": 0.18, "reload_time": 1.6, "auto": false,
		"pellets": 1, "hint": "Semi-auto. Moderate noise.",
	},
	"suppressed_9mm": {
		"name": "Suppressed 9mm", "ammo": "9mm", "capacity": 12, "damage": 18.0,
		"noise": 8.0, "fire_delay": 0.2, "reload_time": 1.7, "auto": false,
		"pellets": 1, "suppressed": true, "hint": "Quiet. Rarer.",
	},
	"shotgun": {
		"name": "12ga Shotgun", "ammo": "12ga", "capacity": 6, "damage": 70.0,
		"noise": 34.0, "fire_delay": 0.8, "reload_time": 2.6, "auto": false,
		"pellets": 8, "hint": "Devastating up close. Very loud.",
	},
	"smg": {
		"name": "SMG", "ammo": "9mm", "capacity": 30, "damage": 14.0,
		"noise": 28.0, "fire_delay": 0.09, "reload_time": 2.0, "auto": true,
		"pellets": 1, "hint": "Full auto. Burns ammo fast. Loud.",
	},
	"rifle": {
		"name": "Bolt-Action Rifle", "ammo": "308", "capacity": 5, "damage": 55.0,
		"noise": 36.0, "fire_delay": 1.2, "reload_time": 3.0, "auto": false,
		"pellets": 1, "hint": "High damage at range. Very loud.",
	},
	"tranq": {
		"name": "Tranquilizer Gun", "ammo": "dart", "capacity": 1, "damage": 0.0,
		"stun": 5.0, "noise": 4.0, "fire_delay": 1.0, "reload_time": 2.2,
		"auto": false, "pellets": 1, "suppressed": true,
		"hint": "Stuns a monster for 5s. Silent. Extremely rare.",
	},
	"flare_gun": {
		"name": "Flare Gun", "ammo": "flare_shell", "capacity": 1, "damage": 5.0,
		"noise": 30.0, "fire_delay": 1.0, "reload_time": 2.4, "auto": false,
		"pellets": 1, "hint": "Lights the area and draws monsters. Loud.",
	},
	"reinforced_pipe": {
		"name": "Reinforced Pipe", "type": "melee", "damage": 30.0, "speed": 0.9,
		"reach": 2.2, "max_durability": 200, "noise": 4.0,
		"craft_time": 5.0,
		"hint": "Pipe wrapped in duct tape. 2x durability.",
	},
	"improvised_axe": {
		"name": "Improvised Axe", "type": "melee", "damage": 45.0, "speed": 0.7,
		"reach": 2.2, "max_durability": 150, "noise": 6.0,
		"craft_time": 8.0,
		"hint": "Pipe with an axe head taped on. High damage, slow.",
	},
	"machete": {
		"name": "Machete", "type": "melee", "damage": 30.0, "speed": 1.3,
		"reach": 1.8, "max_durability": 120, "noise": 5.0,
		"bleed_chance": 0.25, "craft_time": 6.0,
		"hint": "Fast, causes bleeding.",
	},
	"gear_axe": {
		"name": "Gear Axe", "type": "melee", "damage": 55.0, "speed": 0.5,
		"reach": 2.4, "max_durability": 180, "noise": 8.0,
		"armor_pierce": 0.5, "craft_time": 10.0,
		"hint": "Heavy industrial axe. Pierces armor.",
	},
}

## Ammo types and their display names.
const AMMO := {
	"38": {"name": ".38 Speedloader"},
	"9mm": {"name": "9mm Mag"},
	"12ga": {"name": "12ga Shell"},
	"308": {"name": ".308 Stripper Clip"},
	"dart": {"name": "Tranq Dart"},
	"flare_shell": {"name": "Flare Shell"},
}


static func display_name(id: String) -> String:
	return INFO[id].name if INFO.has(id) else "(no weapon)"


## The ammo type a firearm takes ("" if melee or unknown).
static func ammo_type(id: String) -> String:
	return INFO[id].get("ammo", "") if INFO.has(id) else ""


## True if this weapon ID is a melee weapon.
static func is_melee(id: String) -> bool:
	return INFO.has(id) and INFO[id].get("type", "") == "melee"


## Get full info dict for a firearm.
static func get_info(id: String) -> Dictionary:
	return INFO.get(id, {})


## Get full info dict for a melee weapon.
static func get_melee_info(id: String) -> Dictionary:
	return INFO.get(id, {})


## A simple gray-box gun model (firearms).
static func make_mesh(id: String) -> Node3D:
	var holder := Node3D.new()
	var metal := Color(0.12, 0.12, 0.13)
	var grip := Color(0.2, 0.13, 0.08)

	holder.add_child(_part(Vector3(0.07, 0.12, 0.28), Vector3(0, 0, -0.02), metal))

	var barrel := float({
		"shotgun": 0.5, "rifle": 0.55, "smg": 0.24,
		"suppressed_9mm": 0.32, "tranq": 0.24, "flare_gun": 0.2,
	}.get(id, 0.22))
	holder.add_child(_part(Vector3(0.03, 0.03, barrel),
			Vector3(0, 0.03, -0.14 - barrel * 0.5), metal))

	var handle := _part(Vector3(0.05, 0.16, 0.07), Vector3(0, -0.12, 0.09), grip)
	handle.rotation_degrees.x = -18.0
	holder.add_child(handle)

	if id == "revolver":
		var cylinder := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.035
		mesh.bottom_radius = 0.035
		mesh.height = 0.06
		cylinder.mesh = mesh
		cylinder.rotation_degrees.z = 90.0
		cylinder.position = Vector3(0, 0, 0.04)
		cylinder.material_override = _material(metal)
		holder.add_child(cylinder)
	elif id == "shotgun":
		holder.add_child(_part(Vector3(0.025, 0.025, 0.34),
				Vector3(0, -0.02, -0.2), grip))

	return holder


## Gray-box melee weapon models.
static func make_melee_mesh(id: String) -> Node3D:
	var holder := Node3D.new()
	var metal := Color(0.3, 0.25, 0.2)
	var grip := Color(0.18, 0.12, 0.08)

	match id:
		"reinforced_pipe", "improvised_axe":
			# Pipe shaft
			holder.add_child(_part(Vector3(0.04, 0.04, 0.55), Vector3(0, 0, -0.15), metal))
			# Grip tape
			holder.add_child(_part(Vector3(0.05, 0.12, 0.06), Vector3(0, -0.1, 0.22), grip))
			if id == "improvised_axe":
				# Axe head (taped on)
				var head := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(0.18, 0.06, 0.03)
				head.mesh = mesh
				head.position = Vector3(0, 0.15, -0.3)
				head.material_override = _material(Color(0.4, 0.4, 0.42))
				holder.add_child(head)
				# Tape strips
				for i in 3:
					var tape := _part(Vector3(0.05, 0.01, 0.02), Vector3(0, 0.15 - i * 0.05, -0.15), Color(0.7, 0.6, 0.2))
					holder.add_child(tape)

		"machete":
			# Blade
			holder.add_child(_part(Vector3(0.03, 0.01, 0.45), Vector3(0, 0, -0.1), metal))
			# Handle
			holder.add_child(_part(Vector3(0.04, 0.1, 0.05), Vector3(0, -0.12, 0.2), grip))

		"gear_axe":
			# Heavy shaft
			holder.add_child(_part(Vector3(0.06, 0.06, 0.6), Vector3(0, 0, -0.1), metal))
			# Gear axe head
			var head := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.12
			mesh.bottom_radius = 0.12
			mesh.height = 0.08
			head.mesh = mesh
			head.rotation_degrees.x = 90
			head.position = Vector3(0, 0.18, -0.3)
			head.material_override = _material(Color(0.35, 0.35, 0.38))
			holder.add_child(head)
			# Grip
			holder.add_child(_part(Vector3(0.06, 0.14, 0.07), Vector3(0, -0.14, 0.25), grip))

	return holder


static func _part(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color)
	return instance


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	return material