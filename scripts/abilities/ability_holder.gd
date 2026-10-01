extends Node
## Gives the player their character's ability (Sense, Camera Flash, Repair
## or Strength). Every computer creates it, so the ability's network
## messages reach the same node everywhere.

@export var player: Player

var ability: Ability = null


func _ready() -> void:
	var path: String = Characters.get_value(player.character, "ability_script", "")
	if path.is_empty():
		return
	ability = load(path).new()
	ability.name = "Ability"
	ability.setup(player)
	add_child(ability)
	ability.set_multiplayer_authority(player.get_multiplayer_authority())
