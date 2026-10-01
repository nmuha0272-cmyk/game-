class_name Interactable
extends StaticBody3D
## Base script for anything the player can look at and press E on.
##
## Pressing E asks the host, and the host runs `_on_interact`, so every
## computer agrees on what happened. Child scripts override `_on_interact`
## and use an RPC with "call_local" to show the result on every computer.

signal interacted(by: Player)

## Shown on screen as "[E] <prompt_text>".
@export var prompt_text := "Interact"
@export var enabled := true


## Can this player use it right now? (Controls whether the prompt shows.)
func can_interact(_by: Player) -> bool:
	return enabled


## Seconds you must hold E to use it (0 = a normal press).
func get_hold_time(_by: Player) -> float:
	return 0.0


## The text shown on screen while looking at it.
func get_prompt(_by: Player) -> String:
	return "[E] " + prompt_text


## Called on the computer of the player who pressed E.
func interact(by: Player) -> void:
	if not can_interact(by):
		return
	if multiplayer.is_server():
		_server_interact(by)
	else:
		_request_interact.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_interact() -> void:
	if not multiplayer.is_server():
		return
	var by := Player.find(get_tree(), multiplayer.get_remote_sender_id())
	if by and can_interact(by):
		_server_interact(by)


func _server_interact(by: Player) -> void:
	_on_interact(by)
	interacted.emit(by)


## Runs on the HOST. Child scripts replace this with what the object does.
func _on_interact(_by: Player) -> void:
	pass
