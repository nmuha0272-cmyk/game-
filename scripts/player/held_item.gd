extends Node3D
## Shows the character's permanent item (dog tags, camera, wrench or
## heavy flashlight) in the lower right of the first-person view.

## Render layer for held items. The flashlight is set to skip this layer,
## so the item right in front of the lens doesn't get blasted white.
const HELD_ITEM_LAYER := 2

@export var player: Player


func _ready() -> void:
	var character := player.character
	if not Characters.INFO.has(character):
		return
	var scene: PackedScene = load(Characters.INFO[character].held_item)
	var item := scene.instantiate()
	add_child(item)
	for mesh in item.find_children("*", "GeometryInstance3D"):
		mesh.layers = HELD_ITEM_LAYER
