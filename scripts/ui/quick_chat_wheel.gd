extends CanvasLayer
## Quick chat wheel for players without a microphone.
## Hold RMB to open, move mouse to select, release to send.

@onready var wheel: Node2D = $Wheel
@onready var options: Array[TextureButton] = [
	$Wheel/Option1, $Wheel/Option2, $Wheel/Option3, $Wheel/Option4,
	$Wheel/Option5, $Wheel/Option6, $Wheel/Option7, $Wheel/Option8
]

var _visible := false
var _hovered_index := -1


func _ready() -> void:
	# Hide initially
	wheel.visible = false
	
	# Connect button signals
	for i in options.size():
		options[i].gui_input.connect(_on_option_gui_input.bind(i))
		options[i].mouse_entered.connect(_on_option_hovered.bind(i))
		options[i].mouse_exited.connect(_on_option_unhovered.bind(i))
	
	# Listen for noise level to show tier indicator
	VoiceChat.noise_level_changed.connect(_on_noise_level_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _visible:
		# Update hover based on mouse angle from center
		var center = wheel.get_global_rect().position + wheel.get_global_rect().size * 0.5
		var to_mouse = (event.global_position - center).normalized()
		var angle = atan2(to_mouse.y, to_mouse.x)  # -PI to PI
		
		# Convert to 0-7 index (8 options, 45 degrees each, starting at top)
		var index = int(wrapf((angle + PI / 8.0) / (PI / 4.0), 0.0, 8.0))
		_set_hovered(index)


func _on_option_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_select_option(index)


func _on_option_hovered(index: int) -> void:
	_set_hovered(index)


func _on_option_unhovered(_index: int) -> void:
	if _hovered_index == _index:
		_set_hovered(-1)


func _set_hovered(index: int) -> void:
	if _hovered_index >= 0 and _hovered_index < options.size():
		options[_hovered_index].modulate = Color(1, 1, 1, 1)
		options[_hovered_index].scale = Vector2(1, 1)
	
	_hovered_index = index
	
	if index >= 0 and index < options.size():
		options[index].modulate = Color(1, 1, 0.5, 1)
		options[index].scale = Vector2(1.1, 1.1)


func _select_option(index: int) -> void:
	if index < 0 or index >= options.size():
		return
	
	var text = options[index].text
	
	# Send as a "radio" message to nearby players
	var msg = "%s: \"%s\"" % [GameState.get_player_name(multiplayer.get_unique_id()), text]
	
	# Play locally as subtitle
	get_tree().call_group("player_hud", "show_subtitle_near", 
		player.global_position if player else global_position, 15.0, 
		GameState.get_player_name(multiplayer.get_unique_id()), text, 4.0)
	
	# Send to others via RPC
	_send_quick_chat.rpc(text)
	
	hide()


@rpc("authority", "call_local", "reliable")
func _send_quick_chat(text: String) -> void:
	# Show to all players within range
	var sender_id = multiplayer.get_remote_sender_id()
	var sender = Player.find(get_tree(), sender_id)
	if sender:
		get_tree().call_group("player_hud", "show_subtitle_near",
			sender.global_position, 15.0,
			GameState.get_player_name(sender_id), text, 4.0)


func _on_noise_level_changed(player_id: int, level: float) -> void:
	# Could add visual indicator on wheel center
	pass


func toggle() -> void:
	if _visible:
		hide()
	else:
		show()


func show() -> void:
	_visible = true
	wheel.visible = true
	wheel.scale = Vector2(0.8, 0.8)
	wheel.modulate.a = 0.0
	var tween = wheel.create_tween()
	tween.tween_property(wheel, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(wheel, "modulate:a", 1.0, 0.15)
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Reset hover
	_set_hovered(-1)


func hide() -> void:
	_visible = false
	var tween = wheel.create_tween()
	tween.tween_property(wheel, "scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(wheel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): wheel.visible = false)
	
	# Release mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Reset hover
	_set_hovered(-1)