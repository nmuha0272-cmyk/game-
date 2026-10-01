extends Node
## Ping (Z or middle mouse): marks whatever you're looking at, up to 40 m
## away, for the whole team for a few seconds. "Battery", "Monster!", or
## just "Here".

const PING_SCENE := preload("res://scenes/player/ping_marker.tscn")

@export var player: Player
@export var max_distance := 40.0

var _marker: Node3D = null


func _unhandled_input(event: InputEvent) -> void:
	if not player.is_multiplayer_authority() or GameState.menu_open or player.is_downed:
		return
	if not event.is_action_pressed("ping"):
		return
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * max_distance)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	_show_ping.rpc(hit.position + hit.normal * 0.1, _describe(hit.collider))


func _describe(thing: Object) -> String:
	if thing is Monster or (thing is Node and thing.is_in_group("monsters")):
		return "Monster!"
	if "item" in thing and thing.item is Dictionary and thing.item.has("id"):
		return Items.display_name(thing.item)
	if thing is Player:
		return GameState.get_player_name(thing.name.to_int())
	if thing is Interactable and not thing.prompt_text.is_empty() and thing.prompt_text != "Interact":
		return thing.prompt_text
	return "Here"


@rpc("any_peer", "call_local", "reliable")
func _show_ping(at: Vector3, text: String) -> void:
	if multiplayer.get_remote_sender_id() != player.get_multiplayer_authority():
		return
	if is_instance_valid(_marker):
		_marker.queue_free()  # One ping per player at a time.
	_marker = PING_SCENE.instantiate()
	_marker.text = "%s: %s" % [GameState.get_player_name(player.name.to_int()), text]
	_marker.color = Characters.get_value(player.character, "color", Color.WHITE).lightened(0.4)
	player.get_parent().get_parent().add_child(_marker)  # Into the level.
	_marker.global_position = at
