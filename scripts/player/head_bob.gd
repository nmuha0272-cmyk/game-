class_name HeadBob
extends Camera3D
## Bobs the camera up/down and side to side while walking.
## Emits `stepped` each time a foot "lands" so footstep sounds stay in sync.

signal stepped

@export var body: CharacterBody3D
## Meters walked per footstep.
@export var step_length := 1.8
@export var bob_height := 0.05
@export var bob_sway := 0.03
## How fast the camera settles back when you stop.
@export var return_speed := 8.0
## Speed that counts as "normal" bob size. Faster = bigger bob.
@export var reference_speed := 3.5

var _phase := 0.0


func _process(delta: float) -> void:
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()

	if body.is_on_floor() and speed > 0.5:
		var old_phase := _phase
		# The phase goes up by PI for every step walked.
		_phase += speed * delta / step_length * PI
		if floorf(_phase / PI) > floorf(old_phase / PI):
			stepped.emit()

		var strength := clampf(speed / reference_speed, 0.5, 1.5)
		# At every multiple of PI the camera is at its lowest (foot lands).
		position.y = absf(sin(_phase)) * bob_height * strength
		position.x = sin(_phase) * bob_sway * strength
	else:
		position = position.lerp(Vector3.ZERO, clampf(return_speed * delta, 0.0, 1.0))
