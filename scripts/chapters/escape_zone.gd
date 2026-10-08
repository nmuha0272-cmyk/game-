extends Area3D
## The end of the chapter: once EVERY living player is inside, the gate
## slams shut behind them (the Long Man stays on the other side) and the
## chapter is complete.

@export var gate: Node
@export var title := "CHAPTER 2 COMPLETE\n\nLevel B"
@export var message := "Chapter 2 complete! Chapter 3 is coming soon."

var _done := false


func _physics_process(_delta: float) -> void:
	if _done or not multiplayer.is_server():
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var inside := get_overlapping_bodies()
	for player: Player in players:
		if not player.is_downed and not player in inside:
			return
	_done = true
	if gate and gate.has_method("puzzle_set"):
		gate.puzzle_set(true)
	for monster in get_tree().get_nodes_in_group("monsters"):
		monster.set_physics_process(false)
	_finish.rpc()
	await get_tree().create_timer(7.0).timeout
	GameState.server_complete_chapter(message)


@rpc("authority", "call_local", "reliable")
func _finish() -> void:
	get_tree().call_group("player_hud", "show_message", "The gate slams shut. You made it...")
	await get_tree().create_timer(2.5).timeout
	get_tree().call_group("screen_fader", "fade_out", title, 1.5)
