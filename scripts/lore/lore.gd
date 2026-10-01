class_name Lore
## Finds lore entries by id. Each entry lives in res://lore/<id>.tres.

const FOLDER := "res://lore/"
const TAB_NAMES := ["Files", "Tapes", "Photos", "Personal"]


static func get_entry(id: String) -> LoreEntry:
	var path := FOLDER + id + ".tres"
	return load(path) if ResourceLoader.exists(path) else null
