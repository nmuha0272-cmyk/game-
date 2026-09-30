extends MultiplayerSpawner
## Creates a player for each person in the game, and removes them when
## they leave. Only the host decides when to spawn. The MultiplayerSpawner
## then runs `_create_player` on every computer, so everyone makes the same
## player in the same spot.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

## A node whose children (Marker3D) mark where players appear.
@export var spawn_points: Node3D

@onready var players: Node = get_node(spawn_path)


func _ready() -> void:
	# Every computer needs to know how to build a player from spawn data.
	spawn_function = _create_player
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	# The host is always player 1. Also add anyone already connected.
	_add_player(1)
	for id in multiplayer.get_peers():
		_add_player(id)


## Host only: pick a spawn point and tell every computer to create the player.
func _add_player(id: int) -> void:
	if players.has_node(str(id)) or players.get_child_count() >= NetworkManager.MAX_PLAYERS:
		return
	var data := {"id": id, "position": Vector3.ZERO, "yaw": 0.0}
	var point := _free_spawn_point()
	if point:
		data.position = point.position
		data.yaw = point.rotation.y
	spawn(data)


## Runs on every computer. Builds the player from the host's spawn data.
func _create_player(data: Dictionary) -> Node:
	var player := PLAYER_SCENE.instantiate()
	# The name is the player's network ID. The player uses it to know who controls it.
	player.name = str(data.id)
	player.position = data.position
	player.rotation.y = data.yaw
	return player


func _remove_player(id: int) -> void:
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()


## Picks the spawn point furthest from any existing player.
func _free_spawn_point() -> Node3D:
	if not spawn_points or spawn_points.get_child_count() == 0:
		return null
	var best: Node3D = null
	var best_distance := -1.0
	for point: Node3D in spawn_points.get_children():
		var nearest := INF
		for other: Node3D in players.get_children():
			nearest = minf(nearest, point.position.distance_to(other.position))
		if nearest > best_distance:
			best_distance = nearest
			best = point
	return best
