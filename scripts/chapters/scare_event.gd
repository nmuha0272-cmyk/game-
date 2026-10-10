extends Area3D
## A one-time scare when a player walks in here. Any mix of:
## - something appears for a moment (a face at the window), then vanishes,
## - lights die for a few seconds, then flicker back,
## - heavy footsteps walk across the ceiling,
## - a door slams shut behind you,
## - a sound, and a message.
## The host decides when; everyone sees and hears it.

@export var show_node: Node3D
@export var show_time := 0.6
@export var lights: Array[Node] = []
@export var dark_time := 0.0
@export var door: Node
@export var sound: AudioStream
@export var sound_volume_db := 0.0
@export var sound_pitch := 1.0
## Footsteps from here to there (in the level), one every 0.55 s.
@export var steps_from := Vector3.ZERO
@export var steps_to := Vector3.ZERO
@export var steps := 0
@export var message := ""

const STEP_SOUND := preload("res://assets/audio/footstep_placeholder.wav")

var _done := false


func _ready() -> void:
	if show_node:
		show_node.visible = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _done or not multiplayer.is_server() or not body is Player:
		return
	_done = true
	if door and door.has_method("puzzle_set"):
		door.puzzle_set(false)
	_play.rpc()


@rpc("authority", "call_local", "reliable")
func _play() -> void:
	_done = true
	if not message.is_empty():
		get_tree().call_group("player_hud", "show_message", message)
	if sound:
		var player := AudioStreamPlayer.new()
		player.stream = sound
		player.volume_db = sound_volume_db
		player.pitch_scale = sound_pitch
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)
	if show_node:
		show_node.visible = true
		get_tree().create_timer(show_time).timeout.connect(func() -> void: show_node.visible = false)
	if dark_time > 0.0:
		for light in lights:
			light.visible = false
		await get_tree().create_timer(dark_time).timeout
		for k in 4:
			for light in lights:
				light.visible = k % 2 == 1
			await get_tree().create_timer(0.12).timeout
	for k in steps:
		var step := AudioStreamPlayer3D.new()
		step.stream = STEP_SOUND
		step.pitch_scale = 0.45
		step.volume_db = 8.0
		step.unit_size = 10.0
		add_child(step)
		step.global_position = steps_from.lerp(steps_to, float(k) / maxf(steps - 1, 1))
		step.play()
		step.finished.connect(step.queue_free)
		await get_tree().create_timer(0.55).timeout
