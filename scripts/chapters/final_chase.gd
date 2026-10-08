extends Node
## The final chase. When `source` turns active (the blast door opens), the
## alarms go off and the Long Man bursts out at `burst_point`, faster than
## ever and never losing track of you. Run for the escape lift!

@export var source: Node
## Also starts when a player walks in here (after a restart at the
## checkpoint past the blast door).
@export var trigger: Area3D
@export var monster: Monster
@export var burst_point: Marker3D
## Where he appears when the chase starts from the tunnel trigger instead
## (after a restart there, the blast door is shut behind you).
@export var restart_point: Marker3D
@export var alarm_lights: Node3D
@export var message := "ALARM! The Long Man is loose. RUN for the lift!"
@export var chase_speed := 4.7

var _started := false
var _from_trigger := false


func _ready() -> void:
	if source and source.has_signal("active_changed"):
		source.active_changed.connect(_on_source)
	if trigger:
		trigger.body_entered.connect(func(body: Node3D) -> void:
			if body is Player:
				_from_trigger = true
				_on_source(true))
	if alarm_lights:
		alarm_lights.visible = false


## Host only decides; everyone gets the alarm.
func _on_source(active: bool) -> void:
	if not active or _started or not multiplayer.is_server():
		return
	_started = true
	_alarm.rpc()
	if monster == null:
		return
	await get_tree().create_timer(1.5).timeout
	var point := restart_point if (_from_trigger and restart_point) else burst_point
	monster.global_position = point.global_position
	monster.chase_speed = chase_speed
	monster.lose_target_time = 9999.0
	monster.stare_time = 0.6
	var nearest: Player = null
	for player: Player in get_tree().get_nodes_in_group("players"):
		if not player.is_downed and (nearest == null or \
				player.global_position.distance_to(point.global_position) < nearest.global_position.distance_to(point.global_position)):
			nearest = player
	if nearest:
		monster.server_force_chase(nearest)


@rpc("authority", "call_local", "reliable")
func _alarm() -> void:
	_started = true
	get_tree().call_group("player_hud", "show_message", message)
	if alarm_lights:
		alarm_lights.visible = true
