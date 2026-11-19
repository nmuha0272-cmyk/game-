class_name StudioLogo
extends CanvasLayer
## The Deep Static Games logo intro. Plays once when the game starts, on top of
## everything (the main menu waits underneath, paused). Any key, mouse click or
## controller button skips it.
##
## The video is res://assets/video/deep_static_intro.ogv (Godot plays .ogv).
## The same intro as an .mp4 and the logo pictures are in the studio_logo folder.

signal finished

const VIDEO_PATH := "res://assets/video/deep_static_intro.ogv"

var _video: VideoStreamPlayer
var _skip_label: Label
var _done := false
var _was_paused := false


## Shows the logo if it should play this time. Returns null when it's skipped
## (no video file, or a test run with no screen).
static func play_on(parent: Node) -> StudioLogo:
	if DisplayServer.get_name() == "headless" or "--playtest" in OS.get_cmdline_user_args():
		return null
	if not ResourceLoader.exists(VIDEO_PATH):
		return null
	var logo := StudioLogo.new()
	parent.add_child(logo)
	return logo


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)

	_video = VideoStreamPlayer.new()
	_video.stream = load(VIDEO_PATH)
	_video.expand = true
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_finish)
	add_child(_video)

	_skip_label = Label.new()
	_skip_label.text = "Press any key to skip"
	_skip_label.modulate = Color(1, 1, 1, 0)
	_skip_label.add_theme_font_size_override("font_size", 16)
	_skip_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 28)
	_skip_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_skip_label)

	# The menu underneath waits until the logo is gone.
	_was_paused = get_tree().paused
	get_tree().paused = true
	_video.play()
	var t := create_tween()
	t.tween_interval(1.0)
	t.tween_property(_skip_label, "modulate:a", 0.55, 0.6)


func _input(event: InputEvent) -> void:
	if _done:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventJoypadButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	_video.stop()
	get_tree().paused = _was_paused
	finished.emit()
	# A quick fade from black into the menu.
	_video.visible = false
	_skip_label.visible = false
	var black := get_child(0) as ColorRect
	var t := create_tween()
	t.tween_property(black, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)
