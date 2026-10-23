extends Ability
## The Son's ability. Press Q: nearby monsters glow through walls for a few
## seconds, but ONLY on the Son's screen. He has to tell the others.
## He also sees his teammates through walls, wherever they are (blue, or red
## if they're down), so he can guide everyone back together.

var duration := 4.0
var radius := 25.0

var _time_left := 0.0
var _sensed: Array[Node] = []
var _sound: AudioStreamPlayer

const ALLY_COLOR := Color(0.35, 0.7, 1.0, 0.4)
const ALLY_DOWN_COLOR := Color(1.0, 0.2, 0.2, 0.5)


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
	_sound.play()
	var scrambled := _scrambler_near()
	status_text = "Sense scrambled!" if scrambled else "Sensing..."
	_show_teammates(true)
	var pool := get_tree().get_nodes_in_group("monsters")
	if scrambled:
		# The Long Man jumbles the signal into false echoes: a random handful
		# of monsters glow, wherever they really are.
		pool.shuffle()
		for i in mini(2, pool.size()):
			pool[i].set_sensed(true)
			_sensed.append(pool[i])
	else:
		for monster in pool:
			if monster.global_position.distance_to(player.global_position) <= radius:
				monster.set_sensed(true)
				_sensed.append(monster)


## The Long Man (and anything else with scrambles_sense) wrecks Sense when close.
func _scrambler_near() -> bool:
	for node in get_tree().get_nodes_in_group("monsters"):
		var monster := node as Monster
		if monster and monster.scrambles_sense \
				and monster.global_position.distance_to(player.global_position) <= radius:
			return true
	return false


func _process(delta: float) -> void:
	super(delta)
	if _time_left > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			_stop_sensing()


## Teammates glow through walls on the Son's screen only (this code only runs
## on his computer, and the glow is added locally).
func _show_teammates(show: bool) -> void:
	for other: Player in get_tree().get_nodes_in_group("players"):
		if other == player:
			continue
		var glow := other.get_node_or_null("SenseAllyGlow") as MeshInstance3D
		if glow == null:
			if not show:
				continue
			glow = MeshInstance3D.new()
			glow.name = "SenseAllyGlow"
			var mesh := CapsuleMesh.new()
			mesh.radius = 0.45
			mesh.height = 1.9
			glow.mesh = mesh
			glow.position.y = 0.95
			glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.no_depth_test = true
			mat.render_priority = 10
			glow.material_override = mat
			other.add_child(glow)
		var color := ALLY_DOWN_COLOR if other.is_downed else ALLY_COLOR
		(glow.material_override as StandardMaterial3D).albedo_color = color
		glow.visible = show


func _stop_sensing() -> void:
	_show_teammates(false)
	for monster in _sensed:
		if is_instance_valid(monster):
			monster.set_sensed(false)
	_sensed.clear()
	status_text = ""
