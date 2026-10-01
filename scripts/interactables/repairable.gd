class_name Repairable
extends Interactable
## Something broken that only the Engineer can fix, by holding Q while
## looking at it (generators, elevators, panels, locked security doors).
## When fixed, it emits `repaired` and runs `_on_repaired` on every computer.
##
## BACKUP: if there's no Engineer in the team, anyone can fix it by hand by
## holding E, but it takes 4 times longer.
## It can also be a PuzzleGate input (active once repaired).

signal repaired
signal active_changed(active: bool)

@export var object_name := "machine"
## Seconds of holding Q needed to fix it.
@export var repair_time := 4.0

var is_repaired := false
var is_active: bool:
	get:
		return is_repaired


func needs_repair() -> bool:
	return not is_repaired


func can_interact(_by: Player) -> bool:
	return enabled and not is_repaired


func get_hold_time(by: Player) -> float:
	if by.character != Characters.Id.ENGINEER and not GameState.team_has(Characters.Id.ENGINEER):
		return repair_time * 4.0
	return 0.0


func get_prompt(by: Player) -> String:
	if by.character == Characters.Id.ENGINEER:
		return "[Hold Q] Repair the %s" % object_name
	if not GameState.team_has(Characters.Id.ENGINEER):
		return "[Hold E] Fix the %s by hand (no Engineer, slow)" % object_name
	return "Broken %s. Only the Engineer can fix this." % object_name


## Pressing E: only works as the no-Engineer backup.
func _on_interact(_by: Player) -> void:
	if not is_repaired and not GameState.team_has(Characters.Id.ENGINEER):
		_set_repaired.rpc()


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
	active_changed.emit(true)


## Child scripts replace this (turn on lights, open doors...).
func _on_repaired() -> void:
	pass
