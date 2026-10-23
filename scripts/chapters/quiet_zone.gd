extends Area3D
class_name QuietZone

@export var mode: String = "quiet"
@export var pulse_interval: float = 0.0
@export var pulse_duration: float = 2.0
@export var one_time: bool = false

var _active_players: Array[Player] = []
var _pulse_timer: float = 0.0
var _in_pulse: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if pulse_interval > 0.0:
		_pulse_timer = pulse_interval

func _process(delta: float) -> void:
	if pulse_interval > 0.0:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_in_pulse = not _in_pulse
			_pulse_timer = pulse_duration if _in_pulse else pulse_interval
			for p in _active_players:
				if is_instance_valid(p):
					_update_player_pulse_state(p)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and body.is_multiplayer_authority():
		_active_players.append(body)
		GameState.server_set_voice_mode.rpc(mode, pulse_interval, _in_pulse)
		if one_time:
			set_deferred("monitoring", false)

func _on_body_exited(body: Node3D) -> void:
	if body is Player and body.is_multiplayer_authority():
		_active_players.erase(body)
		GameState.server_set_voice_mode.rpc("normal", 0.0, false)

func _update_player_pulse_state(player: Player) -> void:
	if _in_pulse:
		GameState.server_set_voice_mode.rpc("pulse_active", pulse_interval, true)
	else:
		GameState.server_set_voice_mode.rpc(mode, pulse_interval, false)