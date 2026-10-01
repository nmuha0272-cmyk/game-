class_name Evidence
extends StaticBody3D
## Something the Journalist can photograph with her camera flash.
## Taking the photo tells everyone. (In Phase 9, photos unlock journal entries.)

signal photographed(by: Player)

@export var evidence_name := "Evidence"
## Optional story entry the photo unlocks in the journal.
@export var lore_entry: LoreEntry

var is_photographed := false


func _ready() -> void:
	add_to_group("evidence")


# Only the Journalist sees a hint when looking at it.
func can_interact(by: Player) -> bool:
	return not is_photographed and by.character == Characters.Id.JOURNALIST


func get_prompt(_by: Player) -> String:
	return "Evidence: %s   [Q] Photograph it" % evidence_name


func interact(_by: Player) -> void:
	pass


## Host only: called by the camera flash.
func photograph(by: Player) -> void:
	if multiplayer.is_server() and not is_photographed:
		_set_photographed.rpc(by.name.to_int())
		if lore_entry:
			GameState.server_unlock_lore(lore_entry.id, by.name.to_int())


@rpc("authority", "call_local", "reliable")
func _set_photographed(by_id: int) -> void:
	is_photographed = true
	get_tree().call_group("player_hud", "show_message",
			"%s photographed: %s" % [GameState.get_player_name(by_id), evidence_name])
	photographed.emit(Player.find(get_tree(), by_id))
