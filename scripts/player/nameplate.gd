extends Label3D
## Floating name above other players' heads, like "Sam - The Engineer".
## Hidden on your own character.

@export var player: Player

var _force := false


func _ready() -> void:
	visible = _force or not player.is_multiplayer_authority()
	var id := player.name.to_int()
	text = "%s\n%s" % [GameState.get_player_name(id), Characters.display_name(player.character)]


## Shows the nameplate even on your own character (used by the dialogue
## cutscene so everyone in the shot is labelled).
func set_force_visible(shown: bool) -> void:
	_force = shown
	visible = _force or not player.is_multiplayer_authority()
