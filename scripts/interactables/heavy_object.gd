class_name HeavyObject
extends CharacterBody3D
## Something too heavy for most players (filing cabinets, crates).
## Only the Guard can move it, by holding Q while looking at it.
## The host moves it, and a MultiplayerSynchronizer shows that to everyone.

@export var object_name := "filing cabinet"

## Network ID of the Guard moving it (0 = nobody).
var mover_id := 0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Where the object sits relative to the Guard when he grabbed it.
var _grab_offset := Vector3.ZERO
var _noise_timer := 0.0


# Looking at it shows a hint (the Interactor calls these).
func can_interact(_by: Player) -> bool:
	return true


func get_prompt(by: Player) -> String:
	if mover_id == by.name.to_int():
		return "Moving the %s (let go of Q to drop)" % object_name
	if by.character == Characters.Id.GUARD:
		return "[Hold Q] Move the %s" % object_name
	return "Too heavy to move alone. The Guard can move this."


func interact(_by: Player) -> void:
	pass  # Pressing E does nothing. Only the Guard's Q works.


## Called on the Guard's computer when he grabs or lets go.
func request_move(by: Player, move: bool) -> void:
	if multiplayer.is_server():
		_server_move(by, move)
	else:
		_request_move.rpc_id(1, move)


@rpc("any_peer", "reliable")
func _request_move(move: bool) -> void:
	if multiplayer.is_server():
		_server_move(Player.find(get_tree(), multiplayer.get_remote_sender_id()), move)


func _server_move(by: Player, move: bool) -> void:
	if by == null:
		return
	if move and mover_id == 0 and by.character == Characters.Id.GUARD:
		mover_id = by.name.to_int()
		_grab_offset = by.global_transform.affine_inverse() * global_position
		add_collision_exception_with(by)
	elif not move and mover_id == by.name.to_int():
		remove_collision_exception_with(by)
		mover_id = 0


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var mover := Player.find(get_tree(), mover_id) if mover_id != 0 else null
	if mover_id != 0 and mover == null:
		mover_id = 0  # The Guard left the game.
	if mover:
		# Slide toward the spot in front of the Guard.
		var to_target := mover.global_transform * _grab_offset - global_position
		to_target.y = 0.0
		var move := (to_target * 8.0).limit_length(4.0)
		velocity.x = move.x
		velocity.z = move.z
		# Dragging heavy furniture is loud.
		_noise_timer -= delta
		if move.length() > 0.5 and _noise_timer <= 0.0:
			_noise_timer = 0.5
			get_tree().call_group("monsters", "hear_noise", global_position, 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	move_and_slide()
