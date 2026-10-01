class_name Door
extends Interactable
## A door anyone can open or close with E. The Guard can hold it shut with Q,
## and then nobody can open it (in Phase 6, monsters won't be able to either).

@export var open_angle := -100.0
@export var swing_time := 0.6

var is_open := false
## Network ID of the Guard holding it shut (0 = nobody).
var held_by := 0

@onready var _sound: AudioStreamPlayer3D = $Sound


func is_held() -> bool:
	return held_by != 0


func get_prompt(by: Player) -> String:
	var by_id := by.name.to_int()
	if held_by == by_id:
		return "Holding the door shut (let go of Q to release)"
	if is_held():
		return "%s is holding the door shut" % GameState.get_player_name(held_by)
	var text := "[E] Close door" if is_open else "[E] Open door"
	if by.character == Characters.Id.GUARD and not is_open:
		text += "   [Hold Q] Hold it shut"
	return text


func _on_interact(_by: Player) -> void:
	if not is_held():
		_set_open.rpc(not is_open)


## Called on the Guard's computer when he starts or stops holding the door.
func request_hold(by: Player, hold: bool) -> void:
	if multiplayer.is_server():
		_server_hold(by, hold)
	else:
		_request_hold.rpc_id(1, hold)


@rpc("any_peer", "reliable")
func _request_hold(hold: bool) -> void:
	if multiplayer.is_server():
		_server_hold(Player.find(get_tree(), multiplayer.get_remote_sender_id()), hold)


func _server_hold(by: Player, hold: bool) -> void:
	if by == null:
		return
	var by_id := by.name.to_int()
	if hold and not is_open and held_by == 0 and by.character == Characters.Id.GUARD:
		_set_held.rpc(by_id)
	elif not hold and held_by == by_id:
		_set_held.rpc(0)


func _process(_delta: float) -> void:
	# If the Guard who was holding the door leaves the game, let go.
	if multiplayer.is_server() and held_by != 0 and Player.find(get_tree(), held_by) == null:
		_set_held.rpc(0)


@rpc("authority", "call_local", "reliable")
func _set_open(value: bool) -> void:
	is_open = value
	var angle := open_angle if is_open else 0.0
	create_tween().tween_property(self, "rotation_degrees:y", angle, swing_time) \
			.set_trans(Tween.TRANS_SINE)
	_sound.pitch_scale = randf_range(0.9, 1.1)
	_sound.play()


@rpc("authority", "call_local", "reliable")
func _set_held(guard_id: int) -> void:
	held_by = guard_id
