class_name Perspective
extends Node
## First/third person toggle (C key, local player only).
##
## Third person pulls the camera back over the shoulder, shows your own
## body (it is shadow-only in first person, because the camera sits inside
## your head) and hides the first-person view-models: the held item, the
## gear hand and the weapon, which would float in front of the camera.
## The actual camera position still belongs to head_bob.gd — this script
## only sets the offset it sits at, so bob, scares and cutscenes keep
## working the same way they do in first person.

@export var player: Player

## Where the camera hangs relative to your head: right, up, back.
const SHOULDER := Vector3(0.5, 0.25, 2.4)
## Never pull closer to the head than this when a wall is in the way.
const MIN_SCALE := 0.3
## Only world geometry stops the camera (layer 1).
const WORLD_MASK := 1

var third_person := false:
	set(value):
		third_person = value
		if is_node_ready():
			_apply()

@onready var _head: Node3D = player.get_node("Head")
@onready var _camera: HeadBob = player.get_node("Head/Camera3D")


func _ready() -> void:
	if not player.is_multiplayer_authority():
		# Other people's view of you is never our business.
		set_process(false)
		set_process_unhandled_input(false)
		return
	
	# Apply saved perspective setting
	third_person = Settings.camera_perspective == 1
	_apply()


func _process(_delta: float) -> void:
	if third_person:
		_camera.camera_offset = _offset_with_wall_check()


func _apply() -> void:
	_camera.camera_offset = _offset_with_wall_check() if third_person else Vector3.ZERO
	# The view-models live on the camera itself; hide them in third person.
	for path in ["HeldItem", "GearHand", "WeaponHand"]:
		var view_model := _camera.get_node_or_null(path)
		if view_model:
			view_model.visible = not third_person
	_set_own_body_visible(third_person)


## In third person your own model has to be drawn normally, in first person
## it is shadow-only (the camera is inside the head, so you'd see the
## inside of your own skull otherwise).
func _set_own_body_visible(shown: bool) -> void:
	var setting := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shown \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var body: Node3D = player.get_node_or_null("BodyMesh")
	if body == null:
		return
	for part in body.find_children("*", "MeshInstance3D", true, false):
		part.cast_shadow = setting


## Same offset, but shortened if there is a wall right behind us.
func _offset_with_wall_check() -> Vector3:
	var offset := SHOULDER
	var full := offset.length()
	var from: Vector3 = _head.global_position
	var to: Vector3 = from + _head.global_transform.basis * offset
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK, [player.get_rid()])
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return offset
	var dist: float = from.distance_to(hit.position)
	return offset * clampf((dist - 0.15) / full, MIN_SCALE, 1.0)
