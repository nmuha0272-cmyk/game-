extends Label3D
## Floating name above other players' heads, like "Sam - The Engineer".
## Hidden on your own character.

@export var player: Player


func _ready() -> void:
	visible = not player.is_multiplayer_authority()
	var id := player.name.to_int()
	text = "%s\n%s" % [GameState.get_player_name(id), Characters.display_name(player.character)]
