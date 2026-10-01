extends Interactable
## A file, poster or personal item in the world. Press E to read it: it goes
## into everyone's journal and opens on your screen.
##
## Personal items only unlock for their owner (the Son's dog tags only open
## for the Son). Others see "This belongs to ___" and have to bring them over.
## The owner says a voice line out loud (a subtitle for everyone nearby).
## BACKUP: if the owner isn't in the team, anyone can read it.

@export var entry: LoreEntry
## How far away teammates can hear the owner's voice line.
@export var voice_range := 15.0


func get_prompt(by: Player) -> String:
	if _owner_must_find(by):
		return "This belongs to %s." % Characters.display_name(entry.owner_character)
	if entry.id in GameState.journal:
		return "[E] Read again: %s" % entry.title
	return "[E] %s: %s" % ["Look at" if entry.type == LoreEntry.Type.PERSONAL else "Read", entry.title]


func _on_interact(by: Player) -> void:
	if _owner_must_find(by):
		var owner_name := Characters.display_name(entry.owner_character)
		by.inventory.server_tell("This belongs to %s. Bring them here." % owner_name)
		return
	var first_time := not entry.id in GameState.journal
	GameState.server_unlock_lore(entry.id, by.name.to_int())
	var is_owner := by.character == entry.owner_character
	if first_time and entry.type == LoreEntry.Type.PERSONAL and is_owner and not entry.voice_line.is_empty():
		_say_voice_line.rpc(by.name.to_int())
	# Open the journal on the reader's screen.
	if by.is_multiplayer_authority():
		_open_for_reader()
	else:
		_open_for_reader.rpc_id(by.get_multiplayer_authority())


func _owner_must_find(by: Player) -> bool:
	if entry.type != LoreEntry.Type.PERSONAL or entry.owner_character < 0:
		return false
	return by.character != entry.owner_character and GameState.team_has(entry.owner_character)


@rpc("authority", "call_local", "reliable")
func _say_voice_line(speaker_id: int) -> void:
	get_tree().call_group("player_hud", "show_subtitle_near", global_position, voice_range,
			GameState.get_player_name(speaker_id), entry.voice_line, 5.0)


@rpc("authority", "reliable")
func _open_for_reader() -> void:
	get_tree().call_group("journal", "open_entry", entry.id)
