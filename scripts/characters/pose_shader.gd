class_name PoseShader
## Bends a character model that has no skeleton (made in a T-pose): arms
## down at the sides, and sitting if asked (the car on the main menu). Uses
## assets/shaders/pose_without_skeleton.gdshader; the model's own textures
## are kept, and the model file isn't changed.

const SHADER := preload("res://assets/shaders/pose_without_skeleton.gdshader")

## Where each model's shoulders, hips and knees are (its own units), and how
## far its arms swing down. Keyed by the model file's name.
const BODIES := {
	"eli": {"shoulder_x": 0.13, "shoulder_y": 0.72, "arm_drop": 62.0, "hip_y": 0.40, "knee_y": 0.22},
	"frank": {"shoulder_x": 0.12, "shoulder_y": 0.785, "arm_drop": 80.0, "hip_y": 0.42, "knee_y": 0.23},
	"journalist": {"shoulder_x": 0.145, "shoulder_y": 0.73, "arm_drop": 75.0, "hip_y": 0.33, "knee_y": 0.19},
	"engineer": {"shoulder_x": 0.125, "shoulder_y": 0.76, "arm_drop": 78.0, "hip_y": 0.39, "knee_y": 0.22},
}


## True if this model has numbers above (so it can be posed).
static func knows(model_name: String) -> bool:
	return BODIES.has(model_name)


## Puts the pose on every mesh of the model. sitting: legs bent for a seat.
static func apply(model: Node, model_name: String, sitting := false) -> void:
	if not BODIES.has(model_name):
		return
	var body: Dictionary = BODIES[model_name]
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if part.mesh == null:
			continue
		for i in part.mesh.get_surface_count():
			var old := part.get_active_material(i) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			for key: String in body:
				mat.set_shader_parameter(key, body[key])
			mat.set_shader_parameter("sit", 1.0 if sitting else 0.0)
			if old:
				mat.set_shader_parameter("albedo_color", old.albedo_color)
				if old.albedo_texture:
					mat.set_shader_parameter("albedo_texture", old.albedo_texture)
					mat.set_shader_parameter("has_texture", true)
				if old.normal_enabled and old.normal_texture:
					mat.set_shader_parameter("normal_texture", old.normal_texture)
					mat.set_shader_parameter("has_normal", true)
				var rm: Texture2D = old.roughness_texture if old.roughness_texture else old.metallic_texture
				if rm:
					mat.set_shader_parameter("rm_texture", rm)
					mat.set_shader_parameter("has_rm", true)
			part.set_surface_override_material(i, mat)
		# The bent pose reaches outside the model's original box: draw it anyway.
		part.extra_cull_margin = 1.0
