extends Ability
## The Journalist's camera flash. Press Q: a bright flash stuns monsters in
## front of her and photographs any evidence she is pointing at.
## The host checks what the flash hit, so every computer agrees.

var stun_time := 2.0
var flash_range := 12.0
## How far from the center of the screen the flash still counts (degrees).
var flash_angle := 35.0

var _light: OmniLight3D
var _sound: AudioStreamPlayer3D


func _init() -> void:
	ability_name = "Camera Flash"
	cooldown = 15.0


func _ready() -> void:
	# Everyone gets a copy of the flash light and sound, so all players see it.
	var camera := player.get_node("Head/Camera3D")
	_light = OmniLight3D.new()
	_light.light_color = Color(0.95, 0.97, 1.0)
	_light.light_energy = 0.0
	_light.omni_range = 14.0
	_light.position = Vector3(0.0, 0.0, -0.6)
	camera.add_child(_light)
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = preload("res://assets/audio/camera_flash.wav")
	camera.add_child(_sound)


func _on_pressed() -> void:
	if not is_ready_to_use():
		return
	start_cooldown()
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	_play_flash()
	get_tree().call_group("player_hud", "flash_screen")
	if multiplayer.is_server():
		_server_flash(origin, forward)
	else:
		_request_flash.rpc_id(1, origin, forward)


@rpc("any_peer", "reliable")
func _request_flash(origin: Vector3, forward: Vector3) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == owner_id():
		_server_flash(origin, forward)


## Host only: show the flash to everyone, then stun and photograph.
func _server_flash(origin: Vector3, forward: Vector3) -> void:
	_show_flash.rpc()
	if not is_local():
		_play_flash()
	for monster in get_tree().get_nodes_in_group("monsters"):
		if _is_caught_in_flash(origin, forward, monster.get_aim_point(), monster):
			monster.stun(stun_time)
	for evidence in get_tree().get_nodes_in_group("evidence"):
		if _is_caught_in_flash(origin, forward, evidence.global_position, evidence):
			evidence.photograph(player)


@rpc("any_peer", "reliable")
func _show_flash() -> void:
	# The Journalist already saw her own flash.
	if multiplayer.get_remote_sender_id() == 1 and not is_local():
		_play_flash()


func _play_flash() -> void:
	_light.light_energy = 18.0
	create_tween().tween_property(_light, "light_energy", 0.0, 0.35)
	_sound.play()


## In range, inside the cone, and not hidden behind a wall?
func _is_caught_in_flash(origin: Vector3, forward: Vector3, point: Vector3, target: Node) -> bool:
	var to_target := point - origin
	if to_target.length() > flash_range:
		return false
	if rad_to_deg(forward.angle_to(to_target)) > flash_angle:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, point)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target or target.is_ancestor_of(hit.collider)
