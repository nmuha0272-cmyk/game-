@tool
extends Marker3D
## Marks where an item appears when the level starts. Pick the item in the
## Inspector. The host's ItemSpawner creates the real item here.

@export_enum("battery", "fuse", "keycard_green", "keycard_yellow", "keycard_red",
		"crowbar", "flare", "medkit", "gas_mask", "walkie", "reel_tape",
		"car_battery", "fuel_can", "ammo_38", "ammo_9mm", "ammo_12ga",
		"ammo_308", "ammo_dart", "ammo_flare_shell",
		"weapon_revolver", "weapon_pistol", "weapon_suppressed_9mm",
		"weapon_shotgun", "weapon_smg", "weapon_rifle", "weapon_tranq",
		"weapon_flare_gun") var item_id := "battery"
## For reel tapes: which lore entry is recorded on it (lore/<id>.tres).
@export var lore_id := ""
