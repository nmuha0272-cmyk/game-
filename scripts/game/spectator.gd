extends Node
## When you bleed out, watch through a teammate's eyes until the team
## reaches the next checkpoint. Click to switch to another teammate.

@export var player: Player

var _watching: Player = null


func _process(_delta: float) -> void:
	if not player.is_multiplayer_authority():
		return
	var out := player.downed.is_out
	if out and (_watching == null or not is_instance_valid(_watching) or _watching.is_downed):
		_watch_next()
	elif not out and _watching:
		_watching = null
		player.get_node("Head/Camera3D").current = true


func _unhandled_input(event: InputEvent) -> void:
	if player.is_multiplayer_authority() and player.downed.is_out and event.is_action_pressed("use_item"):
		_watch_next()


func _watch_next() -> void:
	var alive := get_tree().get_nodes_in_group("players").filter(
			func(other: Player) -> bool: return other != player and not other.is_downed)
	if alive.is_empty():
		return
	var index := (alive.find(_watching) + 1) % alive.size()
	_watching = alive[index]
	_watching.get_node("Head/Camera3D").current = true


func watched_name() -> String:
	return GameState.get_player_name(_watching.name.to_int()) if is_instance_valid(_watching) else ""
