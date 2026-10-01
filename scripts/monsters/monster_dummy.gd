extends StaticBody3D
## A stand-in monster (a tall, still shape) for testing abilities before the
## real monster AI in Phase 6. It glows when the Son senses it, and twitches
## and screeches when the Journalist's flash stuns it.
## Phase 6's real monster should keep these same functions.

@onready var _glow: MeshInstance3D = $SenseGlow
@onready var _body: Node3D = $Body
@onready var _screech: AudioStreamPlayer3D = $Screech

var is_stunned := false
var _stun_left := 0.0


func _ready() -> void:
	add_to_group("monsters")
	_glow.visible = false


## The point the camera flash aims at (its head).
func get_aim_point() -> Vector3:
	return global_position + Vector3(0.0, 2.2, 0.0)


## Only the Son's computer calls this, so only he sees the glow.
func set_sensed(sensed: bool) -> void:
	_glow.visible = sensed


## Host only: freeze the monster for a few seconds.
func stun(seconds: float) -> void:
	if multiplayer.is_server():
		_set_stunned.rpc(seconds)


@rpc("authority", "call_local", "reliable")
func _set_stunned(seconds: float) -> void:
	is_stunned = true
	_stun_left = seconds
	_screech.play()


func _process(delta: float) -> void:
	if not is_stunned:
		return
	_stun_left -= delta
	# Twitch while stunned.
	_body.position = Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03))
	if _stun_left <= 0.0:
		is_stunned = false
		_body.position = Vector3.ZERO
