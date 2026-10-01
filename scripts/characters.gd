class_name Characters
## The four playable characters and their info, in one place.
## Other scripts use it like: Characters.INFO[Characters.Id.GUARD].name

enum Id { NONE = -1, SON, JOURNALIST, ENGINEER, GUARD }

const INFO := {
	Id.SON: {
		"name": "The Son",
		"role": "Tracker",
		"ability": "Sense: see nearby monsters through walls.",
		"held_item": "res://scenes/player/held_items/dog_tags.tscn",
		"ability_script": "res://scripts/abilities/son_sense.gd",
	},
	Id.JOURNALIST: {
		"name": "The Journalist",
		"role": "Stunner / Lore",
		"ability": "Camera Flash: stun a monster. Photograph evidence.",
		"held_item": "res://scenes/player/held_items/film_camera.tscn",
		"ability_script": "res://scripts/abilities/journalist_flash.gd",
	},
	Id.ENGINEER: {
		"name": "The Engineer",
		"role": "Fixer",
		"ability": "Repair: fix machines and hack security doors.",
		"held_item": "res://scenes/player/held_items/wrench.tscn",
		"ability_script": "res://scripts/abilities/engineer_repair.gd",
	},
	Id.GUARD: {
		"name": "The Guard (Frank)",
		"role": "Protector",
		"ability": "Strength: hold doors, move heavy things, carry teammates.",
		"held_item": "res://scenes/player/held_items/heavy_flashlight.tscn",
		"ability_script": "res://scripts/abilities/guard_strength.gd",
		# Frank is big: a bit slower, and his footsteps are louder.
		"speed_multiplier": 0.85,
		"footstep_volume_db": 5.0,
	},
}


static func display_name(id: int) -> String:
	return INFO[id].name if INFO.has(id) else "(not picked)"


## Look up one value for a character, with a fallback if it isn't set.
static func get_value(id: int, key: String, default: Variant = null) -> Variant:
	if INFO.has(id) and INFO[id].has(key):
		return INFO[id][key]
	return default
