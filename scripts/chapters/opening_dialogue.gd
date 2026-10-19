extends Node
## Plays the opening dialogue when the team arrives at the weather station.
## It waits for the intro cutscene to finish first, only plays once, and only
## the first time the team enters (checkpoint 0).

@export var auto_play := true
## Seconds to wait after the intro cutscene before the characters talk.
@export var delay := 2.0

var _played := false

# The opening conversation when the team arrives at the weather station
const DIALOGUE := [
	{"character": "Journalist", "text": "There it is. The Blackwater Weather Station. Or what's left of it."},
	{"character": "Guard", "text": "Thirty years since they sealed this place. Nobody's been out here since."},
	{"character": "Engineer", "text": "I remember the night they locked it down... Said it was a gas leak. They lied."},
	{"character": "Son", "text": "Seventeen men are dead. My father was the last. Whatever killed them started here."},
	{"character": "Journalist", "text": "My source said the answers are underground. In the old research levels."},
	{"character": "Guard", "text": "Then we'd better find a way in. Stay close. And keep your flashlights ready."},
	{"character": "Engineer", "text": "Something tells me we're not going to like what we find down there..."},
]


func _ready() -> void:
	if not auto_play or GameState.checkpoint_order != 0 or not multiplayer.is_server():
		return
	await _wait_for_intro()
	_trigger_dialogue.rpc()


## The host decides when the characters talk: first everyone has to be in the
## level, then the intro cutscene has to be off the screen so the two never
## overlap. If the team restarted at a checkpoint the cutscene was already
## seen and is skipped, so that part returns right away.
func _wait_for_intro() -> void:
	var waited := 0.0
	while waited < 8.0 and get_tree().get_nodes_in_group("players").size() < GameState.players.size():
		await get_tree().create_timer(0.2).timeout
		waited += 0.2

	var intro := get_node_or_null("../Cutscenes/Intro") as Cutscene
	if intro:
		waited = 0.0
		while not intro.is_done() and waited < 30.0:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
	await get_tree().create_timer(delay).timeout


@rpc("authority", "call_local", "reliable")
func _trigger_dialogue() -> void:
	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box == null or not dialogue_box.has_method("play_dialogue"):
		return
	if _played:
		return
	_played = true

	# The characters talk while nobody can move.
	get_tree().call_group("players", "set_movement_enabled", false)

	dialogue_box.play_dialogue(DIALOGUE)
	await dialogue_box.dialogue_finished

	get_tree().call_group("players", "set_movement_enabled", true)
