extends PuzzleInput
## A job only one character knows how to do, like the Journalist developing
## photos in the darkroom. Hold E to do it.
##
## BACKUP: if that character isn't in the team at all, anyone can do it,
## just much slower. That way every puzzle can still be beaten with fewer
## than 4 players.

@export var required_character: Characters.Id = Characters.Id.JOURNALIST
@export var action_text := "develop the photos"
@export var done_text := "The photos are developed."
@export var work_time := 6.0
@export var backup_time := 20.0


func get_hold_time(by: Player) -> float:
	if is_active or not requirement_met():
		return 0.0
	if by.character == required_character:
		return work_time
	if not GameState.team_has(required_character):
		return backup_time
	return 0.0


func get_prompt(by: Player) -> String:
	if is_active:
		return done_text
	if not requirement_met():
		return requires_message
	var who := Characters.display_name(required_character)
	if by.character == required_character:
		return "[Hold E] %s (%ds)" % [action_text.capitalize(), work_time]
	if not GameState.team_has(required_character):
		return "[Hold E] %s without %s (slow, %ds)" % [action_text.capitalize(), who, backup_time]
	return "Only %s knows how to %s." % [who, action_text]


func _on_interact(by: Player) -> void:
	var allowed := by.character == required_character or not GameState.team_has(required_character)
	if allowed and requirement_met():
		server_set_active(true)
