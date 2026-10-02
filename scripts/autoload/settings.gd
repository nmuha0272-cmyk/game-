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
## 0 = Low (fast), 1 = Medium, 2 = High (bounced light, reflections, smooth edges).
var graphics := 2
const GRAPHICS_NAMES := ["Low", "Medium", "High"]


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
	graphics = config.get_value("settings", "graphics", graphics)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "brightness", brightness)
	config.set_value("settings", "graphics", graphics)
	config.save(SAVE_PATH)
