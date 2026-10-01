class_name Checkpoint
extends Area3D
## A checkpoint. When a (standing) player walks into it, it becomes the
## team's restart point: everyone's gear is saved, and anyone who bled out
## comes back here. If the whole team goes down, the level restarts here.
## Checkpoints only count going forward (a higher `order` than the last one).

@export var order := 1

## Where players appear. Uses the Marker3D children (or this spot if none).
func get_spawn_position(index: int) -> Vector3:
	var markers := get_children().filter(func(child: Node) -> bool: return child is Marker3D)
	if markers.is_empty():
		return global_position + Vector3(index * 0.9, 0.0, 0.0)
	return markers[index % markers.size()].global_position


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server() or not body is Player or body.is_downed:
		return
	if order <= GameState.checkpoint_order:
		return
	GameState.server_reach_checkpoint(self)
	# Bring back anyone who bled out.
	var index := 0
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player.downed.is_out:
			player.downed.server_respawn(get_spawn_position(index))
			index += 1
