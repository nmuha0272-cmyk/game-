extends AudioStreamPlayer3D
## Plays a footstep sound whenever the head bob says a foot landed.
## Crouching is quiet, sprinting is loud.

@export var player: Player
@export var head_bob: HeadBob
@export var walk_volume_db := -8.0
@export var sprint_volume_db := 0.0
@export var crouch_volume_db := -20.0


func _ready() -> void:
	head_bob.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	if player.is_crouching:
		volume_db = crouch_volume_db
	elif player.is_sprinting:
		volume_db = sprint_volume_db
	else:
		volume_db = walk_volume_db
	# Small random pitch change so steps don't sound identical.
	pitch_scale = randf_range(0.9, 1.1)
	play()
