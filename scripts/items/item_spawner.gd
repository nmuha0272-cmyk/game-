class_name ItemSpawner
extends MultiplayerSpawner
## Creates every item lying in the world: the ones placed with ItemSpawnPoints
## when the level starts, items players drop, and thrown flares. Only the host
## creates them; the MultiplayerSpawner copies them to everyone else, and
## removes them for everyone when they're picked up.

const WORLD_ITEM_SCENE := preload("res://scenes/items/world_item.tscn")
const FLARE_SCENE := preload("res://scenes/items/thrown_flare.tscn")

## A node whose ItemSpawnPoint children say which items go where.
@export var spawn_points: Node3D

@onready var items_root: Node = get_node(spawn_path)


static func find(tree: SceneTree) -> ItemSpawner:
	return tree.get_first_node_in_group("item_spawner")


func _ready() -> void:
	add_to_group("item_spawner")
	spawn_function = _create
	if multiplayer.is_server() and spawn_points:
		# Wait one frame so the level is fully loaded on everyone's computer.
		await get_tree().process_frame
		for point: Node3D in spawn_points.get_children():
			var item := Items.create(point.item_id)
			if not point.lore_id.is_empty():
				item["lore"] = point.lore_id
			spawn({"kind": "item", "item": item,
					"position": point.global_position, "velocity": Vector3.ZERO})


## Host only: drop an item in front of a player.
func server_drop(item: Dictionary, player: Player) -> void:
	var forward := -player.global_basis.z
	spawn({"kind": "item", "item": item,
			"position": player.global_position + forward * 0.6 + Vector3.UP * 1.1,
			"velocity": forward * 1.5 + player.velocity * 0.5})


## Host only: throw a lit flare from a player's hand.
func server_throw_flare(player: Player) -> void:
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var forward := -camera.global_basis.z
	spawn({"kind": "flare", "position": camera.global_position + forward * 0.5,
			"velocity": forward * 9.0 + Vector3.UP * 2.0 + player.velocity * 0.5})


## Runs on every computer to build what the host spawned.
func _create(data: Dictionary) -> Node:
	var node: RigidBody3D
	if data.kind == "flare":
		node = FLARE_SCENE.instantiate()
	else:
		node = WORLD_ITEM_SCENE.instantiate()
		node.item = data.item
	node.position = data.position
	node.linear_velocity = data.velocity
	return node
