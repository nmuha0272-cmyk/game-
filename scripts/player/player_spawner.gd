extends MultiplayerSpawner
## Creates a player for each person in the lobby when the level loads, and
## removes them if they leave. Only the host decides when to spawn. The MultiplayerSpawner
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
	multiplayer.peer_disconnected.connect(_remove_player)
	var ids: Array = GameState.players.keys()
	if ids.is_empty():
		# Running the level by itself (no lobby), e.g. "Run This Scene" in the editor.
		ids = [1]
	ids.sort()
	for id in ids:
		_add_player(id)


## Host only: pick a spawn point and tell every computer to create the player.
func _add_player(id: int) -> void:
	if players.has_node(str(id)) or players.get_child_count() >= NetworkManager.MAX_PLAYERS:
		return
	var data := {"id": id, "character": GameState.get_character(id),
			"position": Vector3.ZERO, "yaw": 0.0}
	var point := _free_spawn_point()
	if point:
		data.position = point.position
		data.yaw = point.rotation.y
	# Restarting after a wipe: appear at the last checkpoint instead.
	var checkpoint := _current_checkpoint()
	if checkpoint:
		data.position = checkpoint.get_spawn_position(players.get_child_count())
	var player := spawn(data)
	# Give back the gear they had at the checkpoint (once everyone has the player).
	if GameState.checkpoint_inventories.has(id):
		var slots: Array = GameState.checkpoint_inventories[id].duplicate(true)
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_instance_valid(player):
				player.inventory.server_set_slots(slots))


func _current_checkpoint() -> Checkpoint:
	if GameState.checkpoint_name.is_empty():
		return null
	for checkpoint: Checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		if checkpoint.name == GameState.checkpoint_name:
			return checkpoint
	return null


## Runs on every computer. Builds the player from the host's spawn data.
func _create_player(data: Dictionary) -> Node:
	var player := PLAYER_SCENE.instantiate()
	# The name is the player's network ID. The player uses it to know who controls it.
	player.name = str(data.id)
	player.character = data.character
	player.position = data.position
	player.rotation.y = data.yaw
	return player


func _remove_player(id: int) -> void:
	if not players.has_node(str(id)):
		return
	var player: Player = players.get_node(str(id))
	# Drop everything they carried so the team doesn't lose it.
	var spawner := ItemSpawner.find(get_tree())
	for slot in Inventory.SLOT_COUNT:
		var item := player.inventory.server_remove(slot)
		if spawner and not item.is_empty():
			spawner.server_drop(item, player)
	player.queue_free()


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
