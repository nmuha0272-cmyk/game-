extends SceneTree
## Exports the game's items and weapons to JSON so the Unreal version uses
## the same data. Run from the project folder:
##     godot --headless -s scripts/export/unreal_export.gd
## It writes res://unreal/SubjectZero/Content/Data/items.json

const OUT := "res://unreal/SubjectZero/Content/Data/items.json"


func _initialize() -> void:
	var data := {"items": [], "weapons": [], "ammo": []}
	for id: String in Items.INFO:
		var info: Dictionary = Items.INFO[id]
		data.items.append({
			"id": id,
			"name": info.get("name", id),
			"hint": info.get("hint", ""),
			"heavy": info.get("heavy", false),
			"extra": info.get("extra", {}),
		})
	for id: String in Weapons.INFO:
		var weapon: Dictionary = Weapons.INFO[id].duplicate()
		weapon["id"] = id
		data.weapons.append(weapon)
	for id: String in Weapons.AMMO:
		data.ammo.append({"id": id, "name": Weapons.AMMO[id].get("name", id)})
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	print("exported %d items, %d weapons, %d ammo types to %s" % [
		data.items.size(), data.weapons.size(), data.ammo.size(), OUT])
	quit()
