extends Control
## Deepwell home screen (main menu).
##
## Buttons: Host Game, Join Game, Settings, Credits, Quit.
## - Host/Join call the NetworkManager autoload (built in Phase 3) if it exists.
##   If it doesn't exist yet, the menu shows a message and emits a signal instead.
## - Settings are saved to user://settings.cfg so other scripts can read them.
## - Optional sounds: put files at AMBIENCE_PATH and CLICK_PATH and they play
##   automatically. The menu works fine without them.

signal host_requested(port: int)
## CONTINUE (only shown when there's a save): play on from the save.
signal continue_requested
signal join_requested(ip: String, port: int)
## Only used when `embedded`: the game's own Settings menu should open.
signal settings_requested

## True when this menu runs inside the game's main scene (scenes/main.tscn).
## Then it only emits signals: main.gd does the hosting/joining and opens the
## game's own Settings (so the two don't fight over settings.cfg).
var embedded := false

const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"
const AMBIENCE_PATH := "res://assets/audio/menu_ambience.ogg"
const CLICK_PATH := "res://assets/audio/ui_click.ogg"
const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_PORT := 7777

## Turn off when this menu is shown on top of another scene (like the car).
@export var show_background := true
## Turn off when another scene handles what happens after Host/Join.
@export var auto_go_to_lobby := true

# Colors: aged paper text, amber highlight, emergency red.
const COLOR_TEXT := Color("d9d3c1")
const COLOR_DIM := Color("7b786c")
const COLOR_HIGHLIGHT := Color("e8b04a")
const COLOR_RED := Color("c0392b")
const COLOR_PANEL := Color(0.04, 0.05, 0.045, 0.94)

## The studio's fonts (same as the logo and the website). Falls back to the
## computer's fonts if they're missing.
const FONT_TITLE := "res://assets/fonts/Oswald-Bold.woff2"
const FONT_HEAD := "res://assets/fonts/Oswald-Regular.woff2"
const FONT_MONO := "res://assets/fonts/IBMPlexMono-400.woff2"
const FONT_MONO_BOLD := "res://assets/fonts/IBMPlexMono-500.woff2"
const STUDIO_LOGO := "res://assets/ui/deep_static_logo.png"
## A line under the buttons that says what the selected one does.
const BUTTON_HINTS := {
	"ContinueButton": "Pick up where your team left off.",
	"HostButton": "Start a game. Friends can join you (1-4 players).",
	"JoinButton": "Join a friend's game with their IP address.",
	"SettingsButton": "Volume, mouse, brightness, fullscreen, subtitles.",
	"CreditsButton": "Who made Deepwell.",
	"QuitButton": "Leave the game.",
}

var _hint_label: Label
var _signal_line: Control

@onready var background: ColorRect = $Background
@onready var title: Label = $Content/Layout/TitleBlock/Title
@onready var kicker: Label = $Content/Layout/TitleBlock/Kicker
@onready var subtitle: Label = $Content/Layout/TitleBlock/Subtitle
@onready var main_buttons: VBoxContainer = $Content/Layout/MainButtons
@onready var host_button: Button = $Content/Layout/MainButtons/HostButton
@onready var join_button: Button = $Content/Layout/MainButtons/JoinButton
@onready var settings_button: Button = $Content/Layout/MainButtons/SettingsButton
@onready var credits_button: Button = $Content/Layout/MainButtons/CreditsButton
@onready var quit_button: Button = $Content/Layout/MainButtons/QuitButton

@onready var join_panel: PanelContainer = $JoinPanel
@onready var ip_input: LineEdit = $JoinPanel/Margin/VBox/IPInput
@onready var port_input: LineEdit = $JoinPanel/Margin/VBox/PortInput
@onready var connect_button: Button = $JoinPanel/Margin/VBox/Buttons/ConnectButton
@onready var join_back_button: Button = $JoinPanel/Margin/VBox/Buttons/BackButton

@onready var webrtc_panel: PanelContainer = $WebRTCPanel
@onready var webrtc_role: OptionButton = $WebRTCPanel/Margin/VBox/RoleOption
@onready var webrtc_invite_display: TextEdit = $WebRTCPanel/Margin/VBox/InviteDisplay
@onready var webrtc_invite_input: LineEdit = $WebRTCPanel/Margin/VBox/InviteInput
@onready var webrtc_generate_button: Button = $WebRTCPanel/Margin/VBox/Buttons/GenerateCodeButton
@onready var webrtc_join_code_button: Button = $WebRTCPanel/Margin/VBox/Buttons/JoinCodeButton
@onready var webrtc_copy_code_button: Button = $WebRTCPanel/Margin/VBox/Buttons/CopyCodeButton
@onready var webrtc_back_button: Button = $WebRTCPanel/Margin/VBox/BackButton
@onready var webrtc_status: Label = $WebRTCPanel/Margin/VBox/StatusLabel

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var volume_slider: HSlider = $SettingsPanel/Margin/VBox/Grid/VolumeSlider
@onready var sensitivity_slider: HSlider = $SettingsPanel/Margin/VBox/Grid/SensitivitySlider
@onready var brightness_slider: HSlider = $SettingsPanel/Margin/VBox/Grid/BrightnessSlider
@onready var fullscreen_toggle: CheckButton = $SettingsPanel/Margin/VBox/Grid/FullscreenToggle
@onready var settings_back_button: Button = $SettingsPanel/Margin/VBox/BackButton

@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var credits_back_button: Button = $CreditsPanel/Margin/VBox/BackButton

@onready var camera_label: Label = $CameraLabel
@onready var rec_label: Label = $RecLabel
@onready var status_label: Label = $StatusLabel
@onready var version_label: Label = $VersionLabel
@onready var fade: ColorRect = $Fade
@onready var flicker_timer: Timer = $FlickerTimer
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var _config := ConfigFile.new()
var _status_tween: Tween
## Security-camera clock starts at 3:47:12 AM and counts up.
var _camera_seconds := 3 * 3600 + 47 * 60 + 12.0


func _ready() -> void:
	_apply_theme()
	_decorate()
	background.visible = show_background
	camera_label.visible = show_background
	rec_label.visible = show_background
	_load_settings()
	_connect_signals()
	_setup_audio()
	_show_panel(null)

	# Fade in from black.
	fade.color = Color.BLACK
	fade.show()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 2.0).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fade.hide)

	flicker_timer.start(randf_range(2.0, 5.0))
	_set_status("SIGNAL: NONE", COLOR_DIM)


## Called by other scenes (like the car) to bring the main buttons back.
func show_main_buttons() -> void:
	_show_panel(null)
	_set_status("SIGNAL: NONE", COLOR_DIM)


func _process(delta: float) -> void:
	# Tick the security-camera clock and blink the red REC dot.
	_camera_seconds += delta
	var total := int(_camera_seconds)
	var dot := "●" if fmod(_camera_seconds, 1.0) < 0.6 else "  "
	rec_label.text = "%s REC   10-14-2015   %02d:%02d:%02d" % [dot, total / 3600 % 24, total / 60 % 60, total % 60]
	if _signal_line and _signal_line.is_visible_in_tree():
		_signal_line.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not main_buttons.visible:
		_show_panel(null)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- Setup

func _connect_signals() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if embedded and game_state and game_state.has_save():
		var continue_button := host_button.duplicate() as Button
		continue_button.name = "ContinueButton"
		continue_button.text = "CONTINUE"
		main_buttons.add_child(continue_button)
		main_buttons.move_child(continue_button, 0)
		continue_button.pressed.connect(func() -> void:
			_set_status("LOADING YOUR SAVE...", COLOR_HIGHLIGHT)
			continue_requested.emit())
	for button: Button in main_buttons.get_children():
		_style_menu_button(button)
	for button: Button in [connect_button, join_back_button, settings_back_button, credits_back_button, webrtc_back_button, webrtc_generate_button, webrtc_join_code_button, webrtc_copy_code_button]:
		_style_menu_button(button)

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	connect_button.pressed.connect(_on_connect_pressed)
	ip_input.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	join_back_button.pressed.connect(_show_panel.bind(null))
	settings_back_button.pressed.connect(_show_panel.bind(null))
	credits_back_button.pressed.connect(_show_panel.bind(null))
	webrtc_back_button.pressed.connect(_show_panel.bind(null))
	webrtc_generate_button.pressed.connect(_on_webrtc_generate_code)
	webrtc_join_code_button.pressed.connect(_on_webrtc_join_code)
	webrtc_copy_code_button.pressed.connect(_on_webrtc_copy_code)

	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	flicker_timer.timeout.connect(_on_flicker_timeout)


## The selected button gets a red bar, slides right a little and turns amber
## (from the theme), and the hint line says what it does.
func _style_menu_button(button: Button) -> void:
	button.set_meta("base_text", button.text)
	button.mouse_entered.connect(func() -> void: button.grab_focus())
	button.focus_entered.connect(func() -> void:
		if _hint_label and BUTTON_HINTS.has(str(button.name)):
			_hint_label.text = BUTTON_HINTS[str(button.name)])
	button.pressed.connect(_play_click)


func _setup_audio() -> void:
	if ResourceLoader.exists(AMBIENCE_PATH):
		ambience.stream = load(AMBIENCE_PATH)
		ambience.play()
	if ResourceLoader.exists(CLICK_PATH):
		click_player.stream = load(CLICK_PATH)


func _play_click() -> void:
	if click_player.stream:
		click_player.play()


# ---------------------------------------------------------------- Panels

## Shows one panel (or the main buttons when panel is null).
func _show_panel(panel: Control) -> void:
	for p: Control in [join_panel, webrtc_panel, settings_panel, credits_panel]:
		p.visible = p == panel
	main_buttons.visible = panel == null

	if panel == null:
		host_button.grab_focus()
	elif panel == join_panel:
		ip_input.grab_focus()
		ip_input.caret_column = ip_input.text.length()
	elif panel == webrtc_panel:
		webrtc_role.grab_focus()
	elif panel == settings_panel:
		volume_slider.grab_focus()
	else:
		credits_back_button.grab_focus()


# ---------------------------------------------------------------- Networking

func _on_settings_pressed() -> void:
	if embedded:
		settings_requested.emit()
	else:
		_show_panel(settings_panel)


## Shows a line of text under the buttons (main.gd uses this for errors).
func show_status(text: String, is_error := false) -> void:
	_set_status(text.to_upper(), COLOR_RED if is_error else COLOR_HIGHLIGHT)


func _on_host_pressed() -> void:
	_set_status("STARTING SERVER ON PORT %d..." % DEFAULT_PORT, COLOR_HIGHLIGHT)
	host_requested.emit(DEFAULT_PORT)
	if embedded:
		return

	var network := get_node_or_null("/root/NetworkManager")
	if network and network.has_method("host_game"):
		network.host_game(DEFAULT_PORT)
		if auto_go_to_lobby:
			_go_to_lobby()
	elif auto_go_to_lobby:
		_set_status("NETWORKMANAGER NOT FOUND (BUILD PHASE 3 FIRST)", COLOR_RED)


## Join: the IP box. Once internet play (WebRTC) is switched on, it first asks
## "LAN or Internet?".
func _on_join_pressed() -> void:
	if _internet_play_available():
		_show_join_options()
	else:
		_show_panel(join_panel)


## Internet play needs the WebRTCSignaling autoload (switched off for now, see
## scripts/autoload/disabled_webrtc/README.md).
func _internet_play_available() -> bool:
	return get_node_or_null("/root/WebRTCSignaling") != null


func _show_join_options() -> void:
	# A choice: LAN (ENet) or Internet (WebRTC).
	var choice_panel := PanelContainer.new()
	choice_panel.name = "JoinChoicePanel"
	choice_panel.set_anchors_preset(Control.PRESET_CENTER)
	choice_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	choice_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	choice_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var label := Label.new()
	label.text = "HOW DO YOU WANT TO CONNECT?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	vbox.add_child(label)

	var choices := [
		["LOCAL NETWORK (LAN / DIRECT IP)", join_panel],
		["INTERNET (WebRTC - NO PORT FORWARDING)", webrtc_panel],
		["BACK", null],
	]
	for choice: Array in choices:
		var button := Button.new()
		button.text = choice[0]
		button.custom_minimum_size = Vector2(0, 60)
		var target: Control = choice[1]
		button.pressed.connect(func() -> void:
			choice_panel.queue_free()
			_show_panel(target))
		vbox.add_child(button)
		_style_menu_button(button)

	main_buttons.visible = false
	add_child(choice_panel)
	vbox.get_child(1).grab_focus()


func _on_connect_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	var port := int(port_input.text) if port_input.text.is_valid_int() else DEFAULT_PORT
	if ip.is_empty():
		_set_status("ENTER THE HOST'S IP ADDRESS", COLOR_RED)
		ip_input.grab_focus()
		return

	_set_status("CONNECTING TO %s:%d..." % [ip, port], COLOR_HIGHLIGHT)
	_save_setting("network", "last_ip", ip)
	join_requested.emit(ip, port)
	if embedded:
		return

	var network := get_node_or_null("/root/NetworkManager")
	if network and network.has_method("join_game"):
		network.join_game(ip, port)
		if auto_go_to_lobby:
			_go_to_lobby()
	elif auto_go_to_lobby:
		_set_status("NETWORKMANAGER NOT FOUND (BUILD PHASE 3 FIRST)", COLOR_RED)


func _go_to_lobby() -> void:
	if not ResourceLoader.exists(LOBBY_SCENE):
		_set_status("LOBBY SCENE NOT FOUND (BUILD PHASE 4 FIRST)", COLOR_RED)
		return
	fade.show()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	tween.tween_callback(get_tree().change_scene_to_file.bind(LOBBY_SCENE))


func _on_quit_pressed() -> void:
	fade.show()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.6)
	tween.tween_callback(get_tree().quit)


func _on_credits_pressed() -> void:
	_show_panel(credits_panel)


# ---------------------------------------------------------------- Settings

func _load_settings() -> void:
	_config.load(SETTINGS_PATH)  # Missing file is fine; defaults are used.
	volume_slider.value = _config.get_value("audio", "master_volume", 80.0)
	sensitivity_slider.value = _config.get_value("controls", "mouse_sensitivity", 1.0)
	brightness_slider.value = _config.get_value("video", "brightness", 1.0)
	fullscreen_toggle.button_pressed = _config.get_value("video", "fullscreen", false)
	ip_input.text = _config.get_value("network", "last_ip", "127.0.0.1")
	port_input.text = str(DEFAULT_PORT)
	if not embedded:  # in the game, Settings (the autoload) owns these
		_apply_volume(volume_slider.value)
		_apply_brightness(brightness_slider.value)


func _save_setting(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	_config.save(SETTINGS_PATH)


func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_setting("audio", "master_volume", value)


func _apply_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))


func _on_sensitivity_changed(value: float) -> void:
	_save_setting("controls", "mouse_sensitivity", value)


func _on_brightness_changed(value: float) -> void:
	_apply_brightness(value)
	_save_setting("video", "brightness", value)


func _apply_brightness(value: float) -> void:
	var material := background.material as ShaderMaterial
	if material:
		material.set_shader_parameter("brightness", value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	_save_setting("video", "fullscreen", enabled)


# ---------------------------------------------------------------- Effects

## Makes the title flicker like a dying fluorescent light.
func _on_flicker_timeout() -> void:
	var tween := create_tween()
	for i in randi_range(2, 4):
		tween.tween_property(title, "modulate:a", randf_range(0.1, 0.5), 0.04)
		tween.tween_property(title, "modulate:a", 1.0, randf_range(0.04, 0.1))
	flicker_timer.start(randf_range(3.0, 8.0))


func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	if _status_tween:
		_status_tween.kill()
	status_label.modulate.a = 1.0


# ---------------------------------------------------------------- Theme

func _load_font(path: String, fallback_bold := false) -> Font:
	if ResourceLoader.exists(path):
		var font := load(path) as Font
		if font:
			return font
	var system := SystemFont.new()
	system.font_names = PackedStringArray(["Courier Prime", "Courier New", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	if fallback_bold:
		system.font_weight = 800
	return system


func _apply_theme() -> void:
	var mono := _load_font(FONT_MONO)
	var bold := _load_font(FONT_TITLE, true)
	var head := _load_font(FONT_HEAD, true)

	var t := Theme.new()
	t.default_font = mono
	t.default_font_size = 20

	# Menu buttons: tall condensed letters; the selected one gets a red bar.
	var button_font := FontVariation.new()
	button_font.base_font = head
	button_font.spacing_glyph = 3
	t.set_font("font", "Button", button_font)
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0, 0, 0, 0)
	plain.content_margin_left = 16
	plain.content_margin_right = 24
	plain.content_margin_top = 2
	plain.content_margin_bottom = 2
	var lit := plain.duplicate() as StyleBoxFlat
	lit.bg_color = Color(0.55, 0.05, 0.06, 0.22)
	lit.border_color = COLOR_RED
	lit.border_width_left = 4
	lit.content_margin_left = 30
	lit.shadow_color = Color(0.7, 0.05, 0.05, 0.18)
	lit.shadow_size = 8
	for state in ["normal", "disabled"]:
		t.set_stylebox(state, "Button", plain)
	for state in ["hover", "pressed", "focus"]:
		t.set_stylebox(state, "Button", lit)
	t.set_color("font_color", "Button", COLOR_TEXT)
	t.set_color("font_hover_color", "Button", COLOR_HIGHLIGHT)
	t.set_color("font_focus_color", "Button", COLOR_HIGHLIGHT)
	t.set_color("font_hover_pressed_color", "Button", COLOR_RED)
	t.set_color("font_pressed_color", "Button", COLOR_RED)
	t.set_font_size("font_size", "Button", 27)
	t.set_constant("outline_size", "Button", 0)

	t.set_color("font_color", "Label", COLOR_TEXT)

	var panel := StyleBoxFlat.new()
	panel.bg_color = COLOR_PANEL
	panel.border_color = COLOR_DIM
	panel.set_border_width_all(1)
	panel.border_width_left = 4
	panel.border_color = COLOR_DIM
	t.set_stylebox("panel", "PanelContainer", panel)

	var field := StyleBoxFlat.new()
	field.bg_color = Color(0, 0, 0, 0.5)
	field.border_color = COLOR_DIM
	field.border_width_bottom = 2
	field.set_content_margin_all(10)
	var field_focus := field.duplicate() as StyleBoxFlat
	field_focus.border_color = COLOR_HIGHLIGHT
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_color("font_color", "LineEdit", COLOR_TEXT)
	t.set_color("caret_color", "LineEdit", COLOR_HIGHLIGHT)

	var track := StyleBoxFlat.new()
	track.bg_color = Color(COLOR_DIM, 0.5)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = COLOR_HIGHLIGHT
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var slider_focus := StyleBoxFlat.new()
	slider_focus.draw_center = false
	slider_focus.border_color = COLOR_HIGHLIGHT
	slider_focus.set_border_width_all(1)
	slider_focus.set_expand_margin_all(6)
	t.set_stylebox("focus", "HSlider", slider_focus)
	t.set_color("font_color", "CheckButton", COLOR_TEXT)
	t.set_color("font_focus_color", "CheckButton", COLOR_HIGHLIGHT)
	t.set_color("font_hover_color", "CheckButton", COLOR_HIGHLIGHT)
	t.set_stylebox("focus", "CheckButton", slider_focus)

	theme = t

	# Big stenciled title with a red "glitch" shadow.
	var title_font := FontVariation.new()
	title_font.base_font = bold
	title_font.spacing_glyph = 12
	var title_settings := LabelSettings.new()
	title_settings.font = title_font
	title_settings.font_size = 118
	title_settings.font_color = COLOR_TEXT
	title_settings.shadow_color = Color(COLOR_RED, 0.6)
	title_settings.shadow_offset = Vector2(6, 0)
	title_settings.shadow_size = 0
	title.label_settings = title_settings

	var spaced := FontVariation.new()
	spaced.base_font = _load_font(FONT_MONO_BOLD)
	spaced.spacing_glyph = 4
	for label: Label in [kicker, subtitle]:
		label.add_theme_font_override("font", spaced)
		label.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", COLOR_DIM)
	subtitle.add_theme_color_override("font_color", COLOR_RED)

	for header: Label in get_tree().get_nodes_in_group("panel_header"):
		header.add_theme_font_override("font", spaced)
		header.add_theme_font_size_override("font_size", 26)
		header.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
	for small: Label in get_tree().get_nodes_in_group("small_label"):
		small.add_theme_font_size_override("font_size", 16)
		small.add_theme_color_override("font_color", COLOR_DIM)

	for cam: Label in [camera_label, rec_label]:
		cam.add_theme_font_override("font", spaced)
		cam.add_theme_font_size_override("font_size", 16)
	camera_label.add_theme_color_override("font_color", COLOR_DIM)
	rec_label.add_theme_color_override("font_color", COLOR_RED)

	status_label.add_theme_font_override("font", spaced)
	status_label.add_theme_font_size_override("font_size", 15)
	version_label.add_theme_font_override("font", spaced)
	version_label.add_theme_font_size_override("font_size", 15)
	version_label.add_theme_color_override("font_color", COLOR_DIM)


## Extra touches: the red signal line under the title, a tagline, a hint for
## the selected button, the studio logo, film grain, and a fade-in.
func _decorate() -> void:
	var block := title.get_parent()
	_signal_line = Control.new()
	_signal_line.custom_minimum_size = Vector2(560, 34)
	_signal_line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_signal_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_signal_line.draw.connect(_draw_signal_line)
	block.add_child(_signal_line)
	block.move_child(_signal_line, title.get_index() + 1)

	var tagline := Label.new()
	tagline.text = "Eight people went in. Nobody came out."
	tagline.add_theme_font_override("font", _load_font(FONT_MONO))
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.add_theme_color_override("font_color", COLOR_TEXT)
	block.add_child(tagline)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", COLOR_DIM)
	var layout := main_buttons.get_parent()
	layout.add_child(_hint_label)
	layout.move_child(_hint_label, main_buttons.get_index() + 1)
	main_buttons.visibility_changed.connect(func() -> void: _hint_label.visible = main_buttons.visible)
	main_buttons.add_theme_constant_override("separation", 2)
	(get_node("Content") as MarginContainer).add_theme_constant_override("margin_top", 40)
	(get_node("Content") as MarginContainer).add_theme_constant_override("margin_bottom", 84)

	# The studio logo in the bottom right corner.
	if ResourceLoader.exists(STUDIO_LOGO):
		var logo := TextureRect.new()
		logo.texture = load(STUDIO_LOGO)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.anchor_left = 1.0
		logo.anchor_right = 1.0
		logo.anchor_top = 1.0
		logo.anchor_bottom = 1.0
		logo.offset_left = -228
		logo.offset_right = -48
		logo.offset_top = -190
		logo.offset_bottom = -70
		logo.modulate = Color(1, 1, 1, 0.85)
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(logo)

	# Film grain, scan lines and dark corners over the picture (under the text).
	var grain := ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
float rand(vec2 c) { return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float corners = smoothstep(0.38, 0.95, distance(uv, vec2(0.5)));
	float noise = rand(floor(uv * vec2(640.0, 360.0)) + fract(TIME * 7.0) * 61.0);
	float lines = step(0.5, fract(uv.y * 270.0));
	COLOR = vec4(vec3(noise), 0.0);
	COLOR.a = corners * 0.7 + lines * 0.04 + noise * 0.035;
	COLOR.rgb *= (1.0 - corners);
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	grain.material = material
	add_child(grain)
	move_child(grain, 1 if show_background else 0)

	# Fade in: the title first, then the buttons one by one.
	var tween := create_tween()
	title.get_parent().modulate.a = 0.0
	tween.tween_interval(0.6)
	tween.tween_property(title.get_parent(), "modulate:a", 1.0, 1.2)
	for button: Control in main_buttons.get_children():
		button.modulate.a = 0.0
		tween.parallel().tween_property(button, "modulate:a", 1.0, 0.5).set_delay(0.9 + button.get_index() * 0.12)


## A red heartbeat line, like the studio logo, with a spike that travels along it.
func _draw_signal_line() -> void:
	var w := _signal_line.size.x
	var h := _signal_line.size.y
	var mid := h * 0.5
	var beat := fmod(_camera_seconds * 0.35, 1.0)
	var points := PackedVector2Array()
	var x := 0.0
	while x <= w:
		var t := x / w
		var y := mid
		var d := t - beat
		if absf(d) < 0.04:
			y = mid - sin((d + 0.04) / 0.08 * TAU) * mid * 0.9
		elif d > -0.12 and d < -0.04:
			y = mid + sin(x * 0.9) * 2.0
		points.append(Vector2(x, y))
		x += 3.0
	_signal_line.draw_polyline(points, Color(COLOR_RED, 0.25), 7.0, true)
	_signal_line.draw_polyline(points, Color(0.85, 0.12, 0.12), 2.5, true)


# ---------------------------------------------------------------- WebRTC Internet Play

func _on_webrtc_generate_code() -> void:
	var network = get_node_or_null("/root/NetworkManager")
	if not network:
		webrtc_status.text = "ERROR: NetworkManager not found"
		return
	
	webrtc_role.disabled = true
	webrtc_generate_button.disabled = true
	webrtc_status.text = "CREATING OFFER..."
	
	network.webrtc_offer_created.connect(_on_webrtc_offer_created)
	network.host_game_webrtc()

func _on_webrtc_offer_created(offer: String) -> void:
	var network = get_node_or_null("/root/NetworkManager")
	if network:
		network.webrtc_offer_created.disconnect(_on_webrtc_offer_created)
	
	var signaling = network._webrtc_signaling
	if signaling:
		var code = signaling.generate_invite_code()
		if code != "":
			_on_invite_code_ready(code)
		else:
			signaling.offer_created.connect(func(offer: String) -> void:
				signaling.offer_created.disconnect()
				var c = signaling.generate_invite_code()
				if c != "":
					_on_invite_code_ready(c)
			)


func _on_invite_code_ready(code: String) -> void:
	var network = get_node_or_null("/root/NetworkManager")
	if network and network._webrtc_signaling:
		network._webrtc_signaling.invite_code_ready.disconnect(_on_invite_code_ready)
	
	webrtc_invite_display.text = code
	webrtc_status.text = "INVITE CODE READY! SHARE THIS WITH FRIENDS:"
	webrtc_copy_code_button.disabled = false
	webrtc_generate_button.disabled = false


func _on_webrtc_copy_code() -> void:
	DisplayServer.clipboard_set(webrtc_invite_display.text)
	webrtc_status.text = "INVITE CODE COPIED! SEND TO FRIENDS."


# ---------------------------------------------------------------- Theme


func _on_webrtc_join_code() -> void:
	var code = webrtc_invite_input.text.strip_edges().to_upper()
	if code.is_empty():
		webrtc_status.text = "ENTER AN INVITE CODE"
		return
	
	if not code.begins_with("DW-"):
		code = "DW-" + code
	
	var network = get_node_or_null("/root/NetworkManager")
	if not network:
		webrtc_status.text = "ERROR: NetworkManager not found"
		return
	
	webrtc_status.text = "CONNECTING..."
	webrtc_join_code_button.disabled = true
	
	var signaling = network._webrtc_signaling
	if signaling:
		signaling.invite_code_received.connect(_on_invite_code_received)
	
	network.join_game_webrtc_with_code(code)

func _on_invite_code_received(code: String) -> void:
	var network = get_node_or_null("/root/NetworkManager")
	if network and network._webrtc_signaling:
		network._webrtc_signaling.invite_code_received.disconnect(_on_invite_code_received)
	
	webrtc_status.text = "CONNECTED! WAITING FOR HOST..."


# ---------------------------------------------------------------- Theme
