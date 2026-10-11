extends Area3D
## Knee-deep flood water. Wading through it slows you down, and every
## splash is loud: the Long Man hears it. When `drained_by` turns active
## (the pumps run), the water is gone and it all stops.

@export var drained_by: Node
@export var slow := 0.55
@export var splash_noise := 9.0
@export var splash_every := 0.7

const SPLASH := preload("res://assets/audio/water_drip.wav")

var _drained := false
var _inside := {}  # Player -> seconds until the next splash


func _ready() -> void:
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	if drained_by and drained_by.has_signal("active_changed"):
		drained_by.active_changed.connect(func(active: bool) -> void:
			if active:
				_drain())


func _drain() -> void:
	_drained = true
	for player: Player in _inside.keys():
		if is_instance_valid(player):
			player.speed_multiplier = 1.0
	_inside.clear()


func _on_entered(body: Node3D) -> void:
	if _drained or not body is Player:
		return
	_inside[body] = 0.0
	if body.is_multiplayer_authority():
		body.speed_multiplier = slow


func _on_exited(body: Node3D) -> void:
	if not body is Player:
		return
	_inside.erase(body)
	if body.is_multiplayer_authority():
		body.speed_multiplier = 1.0


func _physics_process(delta: float) -> void:
	if _drained:
		return
	for player: Player in _inside.keys():
		if not is_instance_valid(player):
			_inside.erase(player)
			continue
		if Vector2(player.velocity.x, player.velocity.z).length() < 0.5:
			continue
		_inside[player] -= delta
		if _inside[player] > 0.0:
			continue
		_inside[player] = splash_every
		var splash := AudioStreamPlayer3D.new()
		splash.stream = SPLASH
		splash.pitch_scale = randf_range(0.5, 0.75)
		splash.volume_db = 4.0
		splash.unit_size = 6.0
		add_child(splash)
		splash.global_position = player.global_position + Vector3.UP * 0.3
		splash.play()
		splash.finished.connect(splash.queue_free)
		if multiplayer.is_server():
			get_tree().call_group("monsters", "hear_noise", player.global_position, splash_noise)
