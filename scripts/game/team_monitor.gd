extends Node
## Watches the team (host only). The team lives or dies together:
## if ANYONE bleeds out (nobody helped them up in time), or everyone is
## down at the same time, it's a wipe: everyone restarts from the last
## checkpoint.

var _wiped := false


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or _wiped:
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var all_down := true
	for player: Player in players:
		if player.downed.is_out:
			_wipe("%s didn't make it...\nEveryone goes back to the last checkpoint." % Characters.display_name(player.character))
			return
		if not player.is_downed:
			all_down = false
	if all_down:
		_wipe("Everyone is down...\nBack to the last checkpoint.")


func _wipe(text: String) -> void:
	_wiped = true
	GameState.server_team_wiped(text)
