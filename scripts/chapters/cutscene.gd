class_name Cutscene
extends Node
## A short movie moment: the camera glides through a few shots with black
## bars and captions, then you get control back. The host starts it and it
## plays on everyone's screen at once. Press Space/Enter to skip it.

signal finished

## Each shot: {"from": Vector3, "from_look": Vector3, "to": Vector3,
## "to_look": Vector3, "time": seconds, "text": caption}
@export var shots: Array = []
## Play by itself when the chapter starts (only from the very beginning,
## not after restarting at a checkpoint).
@export var play_on_start := false

var playing := false
var _played := false
var _skip := false


func _ready() -> void:
	if play_on_start and multiplayer.is_server() and GameState.checkpoint_order == 0:
		await get_tree().create_timer(0.6).timeout
		server_play()


func total_time() -> float:
	var total := 0.0
	for shot in shots:
		total += shot.time
	return total


## Host only.
func server_play() -> void:
	if multiplayer.is_server() and not _played:
		_played = true
		_play.rpc()


func _unhandled_input(event: InputEvent) -> void:
	if playing and event.is_action_pressed("ui_accept"):
		_skip = true
		get_viewport().set_input_as_handled()


@rpc("authority", "call_local", "reliable")
func _play() -> void:
	playing = true
	_skip = false
	var camera := Camera3D.new()
	camera.fov = 58.0
	add_child(camera)
	camera.current = true
	GameState.menu_open = true  # freezes everyone's controls
	get_tree().call_group("player_hud", "hide")
	var bars := _make_bars()
	var caption: Label = bars.get_node("Caption")

	for shot in shots:
		if _skip:
			break
		caption.text = shot.get("text", "")
		var t := 0.0
		while t < shot.time and not _skip:
			var k := smoothstep(0.0, 1.0, t / shot.time)
			var pos: Vector3 = shot.from.lerp(shot.to, k)
			var look: Vector3 = shot.from_look.lerp(shot.to_look, k)
			camera.look_at_from_position(pos, look)
			await get_tree().process_frame
			t += get_process_delta_time()

	bars.queue_free()
	camera.queue_free()
	GameState.menu_open = false
	get_tree().call_group("player_hud", "show")
	var me := Player.find(get_tree(), multiplayer.get_unique_id())
	if me and not me.downed.is_out:
		me.get_node("Head/Camera3D").current = true
	playing = false
	finished.emit()


func _make_bars() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 30
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.88
		bar.anchor_bottom = 0.12 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(bar)
	var caption := Label.new()
	caption.name = "Caption"
	caption.anchor_left = 0.1
	caption.anchor_right = 0.9
	caption.anchor_top = 0.89
	caption.anchor_bottom = 0.99
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 26)
	caption.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	layer.add_child(caption)
	var hint := Label.new()
	hint.text = "[Space] Skip"
	hint.anchor_left = 0.85
	hint.anchor_right = 0.99
	hint.anchor_top = 0.02
	hint.anchor_bottom = 0.1
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	layer.add_child(hint)
	add_child(layer)
	return layer
