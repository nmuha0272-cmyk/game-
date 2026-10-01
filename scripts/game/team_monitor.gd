extends Node
## Watches the team (host only). If every player is down at the same time,
## it's a wipe: the level restarts from the last checkpoint.

var _wiped := false


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or _wiped:
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	for player: Player in players:
		if not player.is_downed:
			return
	_wiped = true
	GameState.server_team_wiped()
