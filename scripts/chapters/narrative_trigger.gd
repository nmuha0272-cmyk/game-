extends Area3D
## Narrative trigger for Chapter 1 story beats.
## Place in the scene where specific story moments should trigger.

@export var trigger_type := "MENTOR_INTRO"
@export var checkpoint_order := 0
@export var requires_character: int = Characters.Id.NONE
@export var only_once := true

var _triggered := false

signal narrative_event(event_name: String)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# If this is a checkpoint-based trigger, listen for checkpoint reached
	if checkpoint_order > 0:
		# Find checkpoint nodes and connect
		for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
			checkpoint.reached.connect(_on_checkpoint_reached)


func _on_body_entered(body: Node3D) -> void:
	if _triggered and only_once:
		return
	if requires_character != Characters.Id.NONE:
		var player := body.get_parent()
		if player and player is Player and player.character != requires_character:
			return
	_trigger()


func _on_checkpoint_reached(checkpoint: Checkpoint) -> void:
	if _triggered and only_once:
		return
	if checkpoint.order >= checkpoint_order:
		_trigger()


func _trigger() -> void:
	if _triggered and only_once:
		return
	_triggered = true
	narrative_event.emit(trigger_type)
	
	match trigger_type:
		"MENTOR_INTRO":
			_mentor_intro()
		"MENTOR_STAIRWELL":
			_mentor_stairwell()
		"ELI_LEG_INJURY":
			_eli_leg_injury()
		"ELI_RESCUE":
			_eli_rescue()
		"VIGIL_SURVEILLANCE":
			_vigil_surveillance()
		"ELI_COLE_PROMISE":
			_eli_cole_promise()


func _mentor_intro() -> void:
	_show_dialogue("Cole", "Eli. Stay close. This place... it takes things from you.", 6.0)
	await get_tree().create_timer(1.0).timeout
	_show_dialogue("Cole", "I've kept you safe for sixteen years, son. I'm not stopping now.", 6.0)


func _mentor_stairwell() -> void:
	_show_dialogue("Cole", "Flashlights drain faster down here. Watch your battery, kid.", 5.0)
	await get_tree().create_timer(1.0).timeout
	_show_dialogue("Cole", "I've seen what happens when the lights go out. Stay near me.", 5.0)
	await get_tree().create_timer(1.0).timeout
	_show_dialogue("Eli", "You don't have to treat me like I'm still five, Cole.", 4.0)
	await get_tree().create_timer(1.0).timeout
	_show_dialogue("Cole", "You'll always be that kid to me. I promised your dad I'd bring you home. And I will.", 5.0)


func _eli_leg_injury() -> void:
	var eli := _find_eli()
	if not eli:
		return
	
	_show_dialogue("Eli", "AHH! My leg— it's pinned! I can't move!", 5.0)
	
	var cole := _find_cole()
	if cole:
		_show_dialogue("Cole", "ELI! Hang on— I'm getting you out!", 4.0)
		await get_tree().create_timer(0.5).timeout
		_show_dialogue("Cole", "Nora, Walter— help me lift this! NOW!", 4.0)
	
	# Slow Eli down significantly
	eli.movement_enabled = false
	eli.speed_multiplier = 0.1
	
	# Add injury visual
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.1, 0.1)
	light.light_energy = 0.5
	light.omni_range = 1.5
	light.position = Vector3(0, 0.5, 0)
	eli.add_child(light)
	eli.set_meta("injury_light", light)
	
	var tween = light.create_tween()
	tween.set_loops()
	tween.tween_property(light, "light_energy", 1.5, 0.5)
	tween.tween_property(light, "light_energy", 0.5, 0.5)
	
	# Tell team to help
	for player in get_tree().get_nodes_in_group("players"):
		if player != eli:
			player.inventory.server_tell("Eli's leg is trapped! Help Cole free him!")


func _eli_rescue() -> void:
	var eli := _find_eli()
	if not eli:
		return
	
	# Restore Eli
	eli.movement_enabled = true
	eli.speed_multiplier = 1.0
	
	if eli.has_meta("injury_light"):
		var light = eli.get_meta("injury_light")
		if is_instance_valid(light):
			light.queue_free()
		eli.remove_meta("injury_light")
	
	_show_dialogue("Eli", "*panting* I... I can move. Thanks, Cole.", 5.0)
	
	var cole := _find_cole()
	if cole:
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "Don't mention it. But we need to talk about what I saw on your file.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Eli", "My file? What file?", 4.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "Later. Let's get to the elevator first.", 4.0)


func _vigil_surveillance() -> void:
	var eli := _find_eli()
	var cole := _find_cole()
	var journalist := _find_player_by_character(Characters.Id.JOURNALIST)
	
	if eli:
		_show_dialogue("Eli", "Wait... Cole. What did you see?", 4.0)
		await get_tree().create_timer(1.0).timeout
	
	if cole:
		_show_dialogue("Cole", "In the personnel files. There's a VIGIL stamp on your transfer order.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "Your dad wasn't just a volunteer, Eli. He was EXPERIMENT 14.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "And someone's been tracking you. Since birth.", 5.0)
		await get_tree().create_timer(1.0).timeout
	
	if journalist:
		_show_dialogue("Nora", "VIGIL... that's the program that replaced BASTION.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Nora", "My informant mentioned them. He said they never stopped watching.", 5.0)
		await get_tree().create_timer(1.0).timeout
	
	if eli:
		_show_dialogue("Eli", "Tracking me? Since birth? You're saying... they KNEW what happened to my dad?", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Eli", "And they LET me come here? They WANTED me to find this place?", 5.0)
		await get_tree().create_timer(1.0).timeout
	
	if cole:
		_show_dialogue("Cole", "I don't know what they wanted. But I know I signed the order that sealed your dad down here.", 6.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "And I'm not letting them take you too.", 5.0)


func _eli_cole_promise() -> void:
	var eli := _find_eli()
	var cole := _find_cole()
	
	if eli and cole:
		_show_dialogue("Eli", "You knew. All this time, you knew about my dad.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "I knew he was down here. I didn't know they'd... done this to him.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Eli", "Why didn't you tell me?", 4.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "Because I was ordered not to. And because I thought... if you knew, you'd come looking.", 6.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "And I couldn't let that happen. Not until you were ready.", 5.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Eli", "Ready for what?", 4.0)
		await get_tree().create_timer(1.0).timeout
		_show_dialogue("Cole", "For the truth. For what's at the bottom of this hole.", 5.0)


func _show_dialogue(speaker: String, text: String, duration: float) -> void:
	# Show to all players near the speaker
	var speaker_player := _find_player_by_character_name(speaker)
	var position := speaker_player.global_position if speaker_player else global_position
	get_tree().call_group("player_hud", "show_subtitle_near", position, 30.0, speaker, text, duration)


func _find_eli() -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.character == Characters.Id.SON:
			return player
	return null


func _find_cole() -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.character == Characters.Id.GUARD:
			return player
	return null


func _find_player_by_character(char_id: int) -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.character == char_id:
			return player
	return null


func _find_player_by_character_name(speaker_name: String) -> Player:
	var char_id := Characters.Id.NONE
	match speaker_name:
		"Eli", "Son":
			char_id = Characters.Id.SON
		"Nora", "Journalist":
			char_id = Characters.Id.JOURNALIST
		"Walter", "Engineer":
			char_id = Characters.Id.ENGINEER
		"Cole", "Guard":
			char_id = Characters.Id.GUARD
	if char_id == Characters.Id.NONE:
		return null
	return _find_player_by_character(char_id)