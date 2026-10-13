extends Node
## A decontamination airlock: two doors that are never open at the same
## time. Press any of its buttons: the open door shuts, the chamber hisses
## for a few seconds, then the other door opens. The Long Man can't get
## through a shut airlock door either.

@export var outer_door: Node
@export var inner_door: Node
@export var buttons: Array[Node] = []
@export var cycle_time := 6.0
@export var hiss: AudioStreamPlayer3D
@export var mist: Node3D

var _inner_open := false
var _cycling := false


func _ready() -> void:
	for button in buttons:
		button.active_changed.connect(func(active: bool) -> void:
			if active:
				_on_button())
	if mist:
		mist.visible = false
	if multiplayer.is_server():
		outer_door.puzzle_set.call_deferred(true)


func _on_button() -> void:
	if not multiplayer.is_server() or _cycling:
		return
	_cycling = true
	(inner_door if _inner_open else outer_door).puzzle_set(false)
	_show_cycle.rpc(true)
	await get_tree().create_timer(cycle_time).timeout
	_inner_open = not _inner_open
	(inner_door if _inner_open else outer_door).puzzle_set(true)
	_show_cycle.rpc(false)
	_cycling = false


@rpc("authority", "call_local", "reliable")
func _show_cycle(on: bool) -> void:
	if mist:
		mist.visible = on
	if hiss:
		if on:
			hiss.play()
		else:
			hiss.stop()
	if on:
		get_tree().call_group("player_hud", "show_message", "DECONTAMINATION CYCLE... stay inside the chamber.")
