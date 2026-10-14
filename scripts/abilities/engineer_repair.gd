extends Ability
## The Engineer's ability. Hold Q while looking at something broken to fix
## it (generators, panels, security doors). Only he can do this.
## Letting go or looking away resets the progress.

var _target: Repairable = null
var _elapsed := 0.0
var _click_timer := 0.0
var _sound: AudioStreamPlayer3D


func _init() -> void:
	ability_name = "Repair"


func _ready() -> void:
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = preload("res://assets/audio/repair_click.wav")
	player.add_child.call_deferred(_sound)


func _physics_process(delta: float) -> void:
	if not is_local():
		return
	var target := interactor.current_target as Repairable
	var holding := Input.is_action_pressed("ability") and not player.is_downed
	if not holding or target == null or not target.needs_repair():
		_reset()
		return
	if target != _target:
		_target = target
		_elapsed = 0.0

	if _is_sabotaged():
		# The Wired reverses your work while it is close.
		_elapsed = maxf(_elapsed - delta, 0.0)
		progress = clampf(_elapsed / target.repair_time, 0.0, 1.0)
		status_text = "It's sabotaging your repair!"
	else:
		_elapsed += delta
		progress = clampf(_elapsed / target.repair_time, 0.0, 1.0)
		status_text = "Repairing the %s..." % target.object_name

	_click_timer -= delta
	if _click_timer <= 0.0:
		_click_timer = 0.3
		_sound.pitch_scale = randf_range(0.9, 1.15)
		_sound.play()

	if progress >= 1.0:
		target.request_repair(player)
		_reset()


## The Wired (and anything with sabotages_repair) undoes repairs when close.
func _is_sabotaged() -> bool:
	for node in get_tree().get_nodes_in_group("monsters"):
		var monster := node as Monster
		if monster and monster.sabotages_repair \
				and monster.global_position.distance_to(player.global_position) <= 12.0:
			return true
	return false


func _reset() -> void:
	_target = null
	_elapsed = 0.0
	progress = -1.0
	status_text = ""
