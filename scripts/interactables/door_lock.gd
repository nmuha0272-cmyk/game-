class_name DoorLock
extends Node
## Put this under a Door to lock it.
## - KEYCARD: opens for anyone carrying a keycard of this color or higher
##   (Green < Yellow < Red). The keycard is not used up.
## - JAMMED: needs a crowbar. Prying takes 3 seconds, is loud, and breaks the crowbar.
## Monsters can't get through a locked door either.

enum Kind { KEYCARD, JAMMED }

@export var kind: Kind = Kind.KEYCARD
@export_enum("green", "yellow", "red") var keycard_color := "green"
@export var pry_time := 3.0

const KEYCARD_ORDER := ["green", "yellow", "red"]

var is_locked := true

var _pryer_id := 0
var _pry_left := 0.0

@onready var door: Door = get_parent()


func get_prompt(by: Player) -> String:
	if kind == Kind.KEYCARD:
		var color := keycard_color.capitalize()
		if _has_keycard(by):
			return "[E] Unlock with your keycard (%s door)" % color
		return "Locked. Needs a %s keycard (or higher)." % color
	if _pryer_id != 0:
		return "Prying it open..."
	if by.inventory.has_item("crowbar"):
		return "[E] Pry it open with the crowbar (%ds, loud)" % pry_time
	return "Jammed shut. A crowbar could pry it open."


## Host only: someone pressed E on the locked door.
func server_try_unlock(by: Player) -> void:
	if kind == Kind.KEYCARD:
		if _has_keycard(by):
			_unlock.rpc()
			door.server_force_open()
		else:
			by.inventory.server_tell("You need a %s keycard." % keycard_color.capitalize())
	elif _pryer_id == 0 and by.inventory.has_item("crowbar"):
		_pryer_id = by.name.to_int()
		_pry_left = pry_time
		by.inventory.server_tell("Prying the door open... stay close!")
		get_tree().call_group("monsters", "hear_noise", door.global_position, 14.0)


func _process(delta: float) -> void:
	if _pryer_id == 0 or not multiplayer.is_server():
		return
	var pryer := Player.find(get_tree(), _pryer_id)
	if pryer == null or pryer.is_downed or not pryer.inventory.has_item("crowbar") \
			or pryer.global_position.distance_to(door.global_position) > 3.5:
		_pryer_id = 0  # Interrupted.
		return
	_pry_left -= delta
	if _pry_left <= 0.0:
		_pryer_id = 0
		pryer.inventory.server_remove(pryer.inventory.find_item("crowbar"))
		pryer.inventory.server_tell("The door gives way. The crowbar snaps.")
		_unlock.rpc()
		door.server_force_open()


func _has_keycard(by: Player) -> bool:
	var needed := KEYCARD_ORDER.find(keycard_color)
	for i in range(needed, KEYCARD_ORDER.size()):
		if by.inventory.has_item("keycard_" + KEYCARD_ORDER[i]):
			return true
	return false


@rpc("authority", "call_local", "reliable")
func _unlock() -> void:
	is_locked = false
