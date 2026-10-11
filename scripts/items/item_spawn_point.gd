@tool
extends Marker3D
## Marks where an item appears when the level starts. Pick the item in the
## Inspector. The host's ItemSpawner creates the real item here.

@export_enum("battery", "fuse", "keycard_green", "keycard_yellow", "keycard_red",
		"crowbar", "flare", "medkit", "gas_mask", "walkie", "reel_tape",
		"car_battery", "fuel_can") var item_id := "battery"
## For reel tapes: which lore entry is recorded on it (lore/<id>.tres).
@export var lore_id := ""
