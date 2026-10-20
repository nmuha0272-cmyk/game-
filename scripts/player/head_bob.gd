class_name HeadBob
extends Camera3D
## Bobs the camera up/down and side to side while walking.
## Emits `stepped` each time a foot "lands" so footstep sounds stay in sync.

signal stepped

@export var body: Player
## Meters walked per footstep.
@export var step_length := 1.8
@export var bob_height := 0.05
@export var bob_sway := 0.03
## How fast the camera settles back when you stop.
@export var return_speed := 8.0
## Speed that counts as "normal" bob size. Faster = bigger bob.
@export var reference_speed := 3.5

## Where the camera sits when the bob is zero. Third-person view (see
## perspective.gd) sets this to pull the camera back over the shoulder;
## first person leaves it at zero, so nothing changes there.
var camera_offset := Vector3.ZERO

var _phase := 0.0


func _process(delta: float) -> void:
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()

	if body.is_grounded and speed > 0.5:
		var old_phase := _phase
		# The phase goes up by PI for every step walked.
		_phase += speed * delta / step_length * PI
		if floorf(_phase / PI) > floorf(old_phase / PI):
			stepped.emit()

		var strength := clampf(speed / reference_speed, 0.5, 1.5)
		# At every multiple of PI the camera is at its lowest (foot lands).
		position = camera_offset + Vector3(
				sin(_phase) * bob_sway * strength,
				absf(sin(_phase)) * bob_height * strength,
				0.0)
	else:
		position = position.lerp(camera_offset, clampf(return_speed * delta, 0.0, 1.0))
