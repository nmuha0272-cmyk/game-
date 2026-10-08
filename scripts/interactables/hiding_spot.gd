class_name HidingSpot
extends Interactable
## A metal locker you can hide in: press E to get in, E again to get out.
## While you're inside, the Long Man can't see or hear you... unless he SAW
## you climb in. Then he walks straight over and drags you out.

const CREAK := preload("res://assets/audio/door_creak.wav")

## Network ID of whoever is inside (0 = empty). The same on every computer.
var occupant := 0

var _sound: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("hiding_spots")
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = CREAK
	_sound.pitch_scale = 1.4
	_sound.volume_db = -6.0
	_sound.position = Vector3(0, 1.0, 0.3)
	add_child(_sound)


func can_interact(by: Player) -> bool:
	var id := by.name.to_int()
	return enabled and not by.is_downed and (occupant == id or (occupant == 0 and not HidingSpot.is_hidden(by)))


func get_prompt(by: Player) -> String:
	return "[E] Get out" if occupant == by.name.to_int() else "[E] Hide in the locker"


func _on_interact(by: Player) -> void:
	var id := by.name.to_int()
	if occupant == id:
		_set_occupant.rpc(0, id)
	elif occupant == 0:
		# Did he see you get in? (Asked before you vanish from his sight.)
		get_tree().call_group("monsters", "server_saw_hide", by, self)
		_set_occupant.rpc(id, id)


## Where the person inside stands.
func inside_position() -> Vector3:
	return global_transform * Vector3(0, 0.02, -0.03)


## Host only: the Long Man found you. Out you come.
func server_drag_out() -> Player:
	var who := Player.find(get_tree(), occupant)
	if occupant != 0:
		_set_occupant.rpc(0, occupant)
	return who


@rpc("authority", "call_local", "reliable")
func _set_occupant(id: int, who: int) -> void:
	occupant = id
	_sound.play()
	var player := Player.find(get_tree(), who)
	if player and player.is_multiplayer_authority():
		if id != 0:
			player.hiding_spot = self
			player.global_position = inside_position()
			player.rotation.y = global_rotation.y
			get_tree().call_group("player_hud", "show_message", "Hiding. Stay quiet... (E to get out)")
		else:
			player.hiding_spot = null
			player.global_position = global_transform * Vector3(0, 0.05, 0.85)


## Is this player hiding in any locker right now?
static func is_hidden(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	var id := player.name.to_int()
	for spot in player.get_tree().get_nodes_in_group("hiding_spots"):
		if spot.occupant == id:
			return true
	return false
