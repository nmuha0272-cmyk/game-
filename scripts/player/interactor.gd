class_name Interactor
extends RayCast3D
## An invisible laser pointing out of the camera. If it touches an
## Interactable, pressing E (interact) uses it.

## Tells the HUD when we start or stop looking at something usable.
signal target_changed(target: Interactable)

@export var player: CollisionObject3D

var current_target: Interactable = null


func _ready() -> void:
	# Don't let the ray hit our own body.
	if player:
		add_exception(player)


func _physics_process(_delta: float) -> void:
	var found: Interactable = null
	var hit := get_collider()
	if hit is Interactable and hit.enabled:
		found = hit

	if found != current_target:
		current_target = found
		target_changed.emit(found)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target:
		current_target.interact(player)
