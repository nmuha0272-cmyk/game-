class_name Weapons
## Every gun in the game, in one place (see GAME_PLAN.md, "Weapons and
## Ammunition"). A weapon lives in the player's single weapon slot and is
## separate from the three gear slots.
##
## Every gunshot (except the suppressed ones and the tranq) is LOUD: it calls
## hear_noise on all monsters, so firing always risks drawing them in.

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
}

## Ammo types and their display names. Magazines are NOT universal: each
## weapon takes one specific type.
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


## The ammo type a weapon takes ("" if unknown).
static func ammo_type(id: String) -> String:
	return INFO[id].get("ammo", "") if INFO.has(id) else ""


## A simple gray-box gun model, built from boxes (no animations yet).
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
