extends Ability
## The Son's ability. Press Q: nearby monsters glow through walls for a few
## seconds, but ONLY on the Son's screen. He has to tell the others.

var duration := 4.0
var radius := 25.0

var _time_left := 0.0
var _sensed: Array[Node] = []
var _sound: AudioStreamPlayer


func _init() -> void:
	ability_name = "Sense"
	cooldown = 15.0


func _ready() -> void:
	_sound = AudioStreamPlayer.new()
	_sound.stream = preload("res://assets/audio/sense_pulse.wav")
	add_child(_sound)


func _on_pressed() -> void:
	if not is_ready_to_use() or _time_left > 0.0:
		return
	start_cooldown()
	_time_left = duration
	status_text = "Sensing..."
	_sound.play()
	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.global_position.distance_to(player.global_position) <= radius:
			monster.set_sensed(true)
			_sensed.append(monster)


func _process(delta: float) -> void:
	super(delta)
	if _time_left > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			_stop_sensing()


func _stop_sensing() -> void:
	for monster in _sensed:
		if is_instance_valid(monster):
			monster.set_sensed(false)
	_sensed.clear()
	status_text = ""
