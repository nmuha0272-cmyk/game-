class_name Interactor
extends RayCast3D
## An invisible laser pointing out of the camera. If it touches something
## usable (anything with a `can_interact` function), pressing E uses it.
## Abilities also use `current_target` to know what you're looking at.

## Tells others when we start or stop looking at something usable.
signal target_changed(target: Node)

@export var player: Player

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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target and not player.is_downed:
		current_target.interact(player)
