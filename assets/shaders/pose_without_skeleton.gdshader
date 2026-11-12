shader_type spatial;
// Poses a character model that has no skeleton (made in a T-pose): the arms
// come down to the sides, and optionally the legs bend to sit (the car on
// the main menu). The model file isn't changed: this only moves the points as
// they're drawn. Positions are in the model's own units (0 = feet, ~1 = head),
// with the model facing +Z.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_texture = false;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = false;
uniform sampler2D rm_texture : hint_default_white, filter_linear_mipmap, repeat_enable;  // roughness (G), metallic (B)
uniform bool has_rm = false;

uniform float shoulder_x = 0.14;   // where the arms start (left/right of the middle)
uniform float shoulder_y = 0.74;   // shoulder height
uniform float arm_drop = 75.0;     // degrees the arms swing down
uniform float sit = 0.0;           // 1 = sitting
uniform float hip_y = 0.42;        // where the legs start
uniform float knee_y = 0.23;       // knee height
uniform vec3 glow_color : source_color = vec3(0.91, 0.69, 0.29);  // highlight (picking a character)
uniform float glow = 0.0;

vec2 turn(vec2 p, float a) {
	return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

void vertex() {
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	vec3 t = TANGENT;
	// Arms: everything out past the shoulder (and not down at the hips) swings down.
	float side = sign(v.x);
	float arm = smoothstep(shoulder_x - 0.015, shoulder_x + 0.035, abs(v.x)) * step(shoulder_y - 0.16, v.y);
	if (arm > 0.0) {
		float a = -radians(arm_drop) * arm * side;
		vec2 pivot = vec2(side * shoulder_x, shoulder_y);
		v.xy = pivot + turn(v.xy - pivot, a);
		n.xy = turn(n.xy, a);
		t.xy = turn(t.xy, a);
	}
	// Sitting: the thighs swing forward to flat, the shins hang down from the knees.
	if (sit > 0.5 && v.y < hip_y) {
		if (v.y > knee_y) {
			float dy = v.y - hip_y;
			v.yz = vec2(hip_y + v.z, -dy);
			n.yz = vec2(n.z, -n.y);
			t.yz = vec2(t.z, -t.y);
		} else {
			float thigh = hip_y - knee_y;
			v.y += thigh;
			v.z += thigh;
		}
	}
	VERTEX = v;
	NORMAL = n;
	TANGENT = t;
}

void fragment() {
	vec4 c = albedo_color;
	if (has_texture) c *= texture(albedo_texture, UV);
	ALBEDO = c.rgb;
	EMISSION = glow_color * glow;
	if (has_normal) NORMAL_MAP = texture(normal_texture, UV).rgb;
	if (has_rm) {
		vec4 rm = texture(rm_texture, UV);
		ROUGHNESS = rm.g;
		METALLIC = rm.b * 0.3;
	} else {
		ROUGHNESS = 0.8;
	}
}
