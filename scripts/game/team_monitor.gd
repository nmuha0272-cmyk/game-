extends Node
## Watches the team (host only). The team lives or dies together:
## there is no "knocked down". If ANYONE goes down (the Long Man catches
## them, gas, a fall...), they die, and so does everyone else: the whole
## team restarts from the last checkpoint.

## DEBUG: Press F1 to toggle god mode (you can't die).
var god_mode := false
var _wiped := false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		god_mode = not god_mode
		get_tree().call_group("player_hud", "show_message", 
			"God Mode: " + ("ON (You can't die)" if god_mode else "OFF"))


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or _wiped or god_mode:
		return
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player.is_downed:
			_wiped = true
			# A moment first, so the one who got caught sees the whole jump scare.
			await get_tree().create_timer(2.4).timeout
			GameState.server_team_wiped("%s died...\nso EVERYONE dies. Back to the last checkpoint." % \
					Characters.display_name(player.character))
			return
