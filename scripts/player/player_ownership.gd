extends Node
## Makes sure each person only controls their own character.
## On everyone else's characters it turns off the camera, HUD and input,
## so they just show a body moving around (driven by the network).

@onready var player: Player = get_parent()


func _ready() -> void:
	var is_local := player.is_multiplayer_authority()
	player.get_node("Head/Camera3D").current = is_local
	# The visor shows which way others are looking. Hide our own so it
	# doesn't block our view.
	player.get_node("Head/Visor").visible = not is_local
	if is_local:
		return

	player.get_node("HUD").queue_free()
	player.get_node("Stamina").set_physics_process(false)
	for path in ["Head", "Head/Camera3D/Flashlight", "Head/Camera3D/InteractRay"]:
		player.get_node(path).set_process_unhandled_input(false)
	var ray: RayCast3D = player.get_node("Head/Camera3D/InteractRay")
	ray.enabled = false
	ray.set_physics_process(false)
