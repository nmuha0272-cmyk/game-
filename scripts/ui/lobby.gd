extends Control
## The lobby: shows who is connected, lets everyone pick a character,
## and gives the host a Start button.

signal start_requested
signal leave_requested

@onready var player_list: VBoxContainer = %PlayerList
@onready var character_buttons: HBoxContainer = %CharacterButtons
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton
@onready var hint_label: Label = %HintLabel


func _ready() -> void:
	_build_character_buttons()
	start_button.pressed.connect(func() -> void: start_requested.emit())
	leave_button.pressed.connect(func() -> void: leave_requested.emit())
	GameState.players_changed.connect(refresh)
	add_to_group("lobby_message")
	visibility_changed.connect(refresh)
	refresh()


func _build_character_buttons() -> void:
	for character in Characters.INFO:
		var info: Dictionary = Characters.INFO[character]
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 140)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.text = "%s\n%s\n\n%s" % [info.name, info.role, info.ability]
		button.pressed.connect(_on_character_pressed.bind(character, button))
		button.set_meta("character", character)
		character_buttons.add_child(button)


func _on_character_pressed(character: int, button: Button) -> void:
	var my_id := multiplayer.get_unique_id()
	# Clicking your own character again un-picks it.
	if GameState.get_character(my_id) == character:
		GameState.request_character(Characters.Id.NONE)
	else:
		GameState.request_character(character)
	# Wait for the host's answer before showing the button as picked.
	button.set_pressed_no_signal(GameState.get_character(my_id) == character)


func refresh() -> void:
	if not is_node_ready():
		return
	var my_id := multiplayer.get_unique_id()

	for child in player_list.get_children():
		child.queue_free()
	var ids := GameState.players.keys()
	ids.sort()
	for id in ids:
		var label := Label.new()
		var you := "  (you)" if id == my_id else ""
		var host := "  [host]" if id == 1 else ""
		label.text = "%s%s%s  —  %s" % [GameState.get_player_name(id), host, you,
				Characters.display_name(GameState.get_character(id))]
		player_list.add_child(label)

	for button: Button in character_buttons.get_children():
		var character: int = button.get_meta("character")
		var owner_id := GameState.get_owner_of(character)
		button.set_pressed_no_signal(owner_id == my_id)
		button.disabled = owner_id != 0 and owner_id != my_id

	var is_host := multiplayer.is_server()
	start_button.visible = is_host
	start_button.disabled = not GameState.can_start()
	if GameState.get_character(my_id) == Characters.Id.NONE:
		hint_label.text = "Pick a character."
	elif is_host and not GameState.has_enough_players():
		hint_label.text = "Subject Zero is a co-op game for 2-4 players.\nWaiting for friends to join..."
	elif is_host and not GameState.can_start():
		hint_label.text = "Waiting for everyone to pick a character..."
	elif is_host:
		hint_label.text = "Everyone is ready. Press Start!"
	else:
		hint_label.text = "Waiting for the host to start..."


func show_message(text: String) -> void:
	hint_label.text = text
