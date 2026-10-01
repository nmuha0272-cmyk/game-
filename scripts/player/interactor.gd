class_name Interactor
extends RayCast3D
## An invisible laser pointing out of the camera. If it touches something
## usable (anything with a `can_interact` function), pressing E uses it.
## Some things need E held down for a while (`get_hold_time`); keep looking
## at them and holding E until the bar fills.
## Abilities also use `current_target` to know what you're looking at.

## Tells others when we start or stop looking at something usable.
signal target_changed(target: Node)

@export var player: Player

## 0 to 1 while holding E on something; -1 when not holding.
var hold_progress := -1.0

var _hold_target: Node = null
var _hold_time := 0.0
var _held_for := 0.0

## What we're looking at. Becomes null if that object is removed
## (for example an item someone else just picked up).
var current_target: Node = null:
	get:
		return current_target if is_instance_valid(current_target) else null


func _ready() -> void:
	# Don't let the ray hit our own body.
	if player:
		add_exception(player)


func _physics_process(_delta: float) -> void:
	var found: Node = null
	var hit := get_collider()
	if hit and hit.has_method("can_interact") and hit.can_interact(player):
		found = hit

	if found != current_target:
		current_target = found
		target_changed.emit(found)
	_update_hold(_delta)


func _update_hold(delta: float) -> void:
	if _hold_target == null:
		return
	var still_holding := Input.is_action_pressed("interact") and not player.is_downed
	if not is_instance_valid(_hold_target) or current_target != _hold_target or not still_holding:
		_cancel_hold()
		return
	_held_for += delta
	hold_progress = clampf(_held_for / _hold_time, 0.0, 1.0)
	if _held_for >= _hold_time:
		var target := _hold_target
		_cancel_hold()
		target.interact(player)


func _cancel_hold() -> void:
	_hold_target = null
	hold_progress = -1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target and not player.is_downed:
		var hold_time: float = current_target.get_hold_time(player) \
				if current_target.has_method("get_hold_time") else 0.0
		if hold_time > 0.0:
			_hold_target = current_target
			_hold_time = hold_time
			_held_for = 0.0
			hold_progress = 0.0
		else:
			current_target.interact(player)
