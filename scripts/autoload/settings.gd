extends Node
## Global script (autoload) for player settings: volume, mouse sensitivity,
## brightness and graphics quality. Saved to the player's computer so they stay the same
## next time the game starts.

signal changed

const SAVE_PATH := "user://settings.cfg"

## 0 = silent, 1 = full volume.
var volume := 0.8
var mouse_sensitivity := 0.002
## 1 = normal. Higher is brighter.
var brightness := 1.0
## How bright your flashlight is. 1 = normal.
var flashlight_brightness := 1.0
## 0 = Low (fast), 1 = Medium, 2 = High (bounced light, reflections, smooth edges).
var graphics := 2
const GRAPHICS_NAMES := ["Low", "Medium", "High"]

## The controls the player is allowed to change, and the name shown in the menu.
const REMAP_ACTIONS := [
	["move_forward", "Move forward"],
	["move_back", "Move backward"],
	["move_left", "Move left"],
	["move_right", "Move right"],
	["jump", "Jump"],
	["sprint", "Sprint"],
	["crouch", "Crouch"],
	["interact", "Interact / use"],
	["flashlight", "Flashlight"],
	["ability", "Character ability"],
	["drop_item", "Drop item"],
	["journal", "Journal"],
	["ping", "Ping (mark a spot)"],
	["weapon_toggle", "Draw / holster weapon"],
	["reload", "Reload weapon"],
	["drop_weapon", "Drop weapon"],
]
## Changes the player has made: action name -> key code. Key codes are positive,
## mouse buttons are stored as the negative button number. Empty = the defaults.
var _controls: Dictionary = {}


func _ready() -> void:
	_load()
	_apply()
	# Apply brightness to every level's environment when it loads.
	get_tree().node_added.connect(_on_node_added)


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply()
	_save()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.006)
	_save()
	changed.emit()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.8)
	_apply()
	_save()


func set_flashlight_brightness(value: float) -> void:
	flashlight_brightness = clampf(value, 0.4, 2.0)
	_save()
	changed.emit()


func set_graphics(value: int) -> void:
	graphics = clampi(value, 0, 2)
	_apply()
	_save()


func _apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	for world_env in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		_apply_brightness(world_env)
	_apply_graphics_to_viewport()
	changed.emit()


func _on_node_added(node: Node) -> void:
	if node is WorldEnvironment:
		_apply_brightness.call_deferred(node)


func _apply_brightness(world_env: WorldEnvironment) -> void:
	var env := world_env.environment
	if env == null:
		return
	env.adjustment_enabled = true
	env.adjustment_brightness = brightness
	# Graphics quality. High: light bounces off walls (SDFGI), soft bounce
	# shadows (SSIL) and shiny floors reflect (SSR). Low turns the heavy stuff off.
	env.sdfgi_enabled = graphics >= 2
	env.sdfgi_use_occlusion = true
	env.sdfgi_energy = 0.7
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.2
	env.ssil_enabled = graphics >= 1
	env.ssil_intensity = 0.8
	env.ssr_enabled = graphics >= 2
	env.ssr_max_steps = 48
	env.ssao_enabled = graphics >= 1
	env.volumetric_fog_enabled = graphics >= 1
	env.fog_enabled = graphics == 0  # cheap fog instead of volumetric fog
	env.fog_density = 0.03
	env.fog_light_color = Color(0.05, 0.06, 0.08)


func _apply_graphics_to_viewport() -> void:
	var viewport := get_tree().root
	viewport.msaa_3d = Viewport.MSAA_2X if graphics >= 2 else Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if graphics == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(4096 if graphics >= 2 else 2048, true)
	viewport.positional_shadow_atlas_size = 4096 if graphics >= 1 else 2048
	RenderingServer.directional_soft_shadow_filter_set_quality(
			RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if graphics >= 2 else RenderingServer.SHADOW_QUALITY_HARD)
	RenderingServer.positional_soft_shadow_filter_set_quality(
			RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if graphics >= 2 else RenderingServer.SHADOW_QUALITY_HARD)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	volume = config.get_value("settings", "volume", volume)
	mouse_sensitivity = config.get_value("settings", "mouse_sensitivity", mouse_sensitivity)
	brightness = config.get_value("settings", "brightness", brightness)
	flashlight_brightness = config.get_value("settings", "flashlight_brightness", flashlight_brightness)
	graphics = config.get_value("settings", "graphics", graphics)
	_controls.clear()
	for pair in REMAP_ACTIONS:
		var action: String = pair[0]
		if config.has_section_key("input", action):
			_controls[action] = int(config.get_value("input", action))
	_apply_controls()


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "brightness", brightness)
	config.set_value("settings", "flashlight_brightness", flashlight_brightness)
	config.set_value("settings", "graphics", graphics)
	for action in _controls:
		config.set_value("input", action, _controls[action])
	config.save(SAVE_PATH)


## The key or mouse button currently bound to an action, as display text.
func action_key_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	return _event_text(events[0])


## Binds one action to a key or mouse button and remembers it for next time.
func set_action_key(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	var cleaned := _clean_event(event)
	if cleaned == null:
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, cleaned)
	_controls[action] = _event_code(cleaned)
	_save()


## Puts every control back to the keys the game ships with.
func reset_controls() -> void:
	_controls.clear()
	InputMap.load_from_project_settings()
	_save()


func _apply_controls() -> void:
	for action in _controls:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var event := _make_event(_controls[action])
		if event != null:
			InputMap.action_add_event(action, event)


func _event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var names := ["", "Left click", "Right click", "Middle click"]
		if event.button_index <= 3:
			return names[event.button_index]
		return "Mouse %d" % event.button_index
	return "?"


func _clean_event(event: InputEvent) -> InputEvent:
	var code := _event_code(event)
	if code == 0:
		return null
	return _make_event(code)


func _event_code(event: InputEvent) -> int:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		return int(code)
	if event is InputEventMouseButton:
		return -int(event.button_index)
	return 0


func _make_event(code: int) -> InputEvent:
	if code == 0:
		return null
	if code < 0:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = -code
		return mouse
	var key := InputEventKey.new()
	key.physical_keycode = code
	return key
