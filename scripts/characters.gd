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
	},
	Id.JOURNALIST: {
		"name": "The Journalist",
		"role": "Stunner / Lore",
		"ability": "Camera Flash: stun a monster. Photograph evidence.",
		"held_item": "res://scenes/player/held_items/film_camera.tscn",
	},
	Id.ENGINEER: {
		"name": "The Engineer",
		"role": "Fixer",
		"ability": "Repair: fix machines and hack security doors.",
		"held_item": "res://scenes/player/held_items/wrench.tscn",
	},
	Id.GUARD: {
		"name": "The Guard (Frank)",
		"role": "Protector",
		"ability": "Strength: hold doors, move heavy things, carry teammates.",
		"held_item": "res://scenes/player/held_items/heavy_flashlight.tscn",
	},
}


static func display_name(id: int) -> String:
	return INFO[id].name if INFO.has(id) else "(not picked)"
