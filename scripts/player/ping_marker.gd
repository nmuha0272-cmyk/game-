extends Node3D
## A ping marker: a glowing dot and a label (with distance) that can be
## seen through walls, then disappears after a few seconds.

@export var lifetime := 6.0

var text := "Here"
var color := Color.WHITE

@onready var _label: Label3D = $Label
@onready var _dot: MeshInstance3D = $Dot


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.albedo_color = color
	material.render_priority = 10
	_dot.material_override = material
	_label.modulate = color
	$Blip.play()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var distance := camera.global_position.distance_to(global_position) if camera else 0.0
	_label.text = "%s  %dm" % [text, roundi(distance)]
