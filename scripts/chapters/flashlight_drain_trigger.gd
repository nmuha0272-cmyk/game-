extends Area3D
## From here on, flashlight batteries drain (Chapter 1: the hidden stairwell).


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if multiplayer.is_server() and body is Player:
			GameState.server_set_flashlight_drain(true))
