extends Node
## Global script (autoload) for player settings: volume, mouse sensitivity
## and brightness. Saved to the player's computer so they stay the same
## next time the game starts.

signal changed

const SAVE_PATH := "user://settings.cfg"

## 0 = silent, 1 = full volume.
var volume := 0.8
var mouse_sensitivity := 0.002
## 1 = normal. Higher is brighter.
var brightness := 1.0


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


func _apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	for world_env in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		_apply_brightness(world_env)
	changed.emit()


func _on_node_added(node: Node) -> void:
	if node is WorldEnvironment:
		_apply_brightness.call_deferred(node)


func _apply_brightness(world_env: WorldEnvironment) -> void:
	if world_env.environment:
		world_env.environment.adjustment_enabled = true
		world_env.environment.adjustment_brightness = brightness


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	volume = config.get_value("settings", "volume", volume)
	mouse_sensitivity = config.get_value("settings", "mouse_sensitivity", mouse_sensitivity)
	brightness = config.get_value("settings", "brightness", brightness)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "brightness", brightness)
	config.save(SAVE_PATH)
