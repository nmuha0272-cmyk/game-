class_name Repairable
extends Interactable
## Something broken that only the Engineer can fix, by holding Q while
## looking at it (generators, elevators, panels, locked security doors).
## When fixed, it emits `repaired` and runs `_on_repaired` on every computer.

signal repaired

@export var object_name := "machine"
## Seconds of holding Q needed to fix it.
@export var repair_time := 4.0

var is_repaired := false


func needs_repair() -> bool:
	return not is_repaired


func can_interact(_by: Player) -> bool:
	return enabled and not is_repaired


func get_prompt(by: Player) -> String:
	if by.character == Characters.Id.ENGINEER:
		return "[Hold Q] Repair the %s" % object_name
	return "Broken %s. Only the Engineer can fix this." % object_name


## Called on the Engineer's computer when the progress bar fills up.
func request_repair(by: Player) -> void:
	if multiplayer.is_server():
		_server_repair(by)
	else:
		_request_repair.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_repair() -> void:
	if multiplayer.is_server():
		_server_repair(Player.find(get_tree(), multiplayer.get_remote_sender_id()))


func _server_repair(by: Player) -> void:
	if by and by.character == Characters.Id.ENGINEER and not is_repaired:
		_set_repaired.rpc()


@rpc("authority", "call_local", "reliable")
func _set_repaired() -> void:
	is_repaired = true
	_on_repaired()
	repaired.emit()


## Child scripts replace this (turn on lights, open doors...).
func _on_repaired() -> void:
	pass
