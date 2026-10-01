// Old 1950s government paint: dark green below, cream above, a thin dark
// stripe between. Works in world space, so every wall lines up.
shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform float scale = 0.4;
uniform float split_height = 1.1;
uniform vec3 lower_color : source_color = vec3(0.22, 0.30, 0.24);
uniform vec3 upper_color : source_color = vec3(0.48, 0.45, 0.36);
uniform vec3 stripe_color : source_color = vec3(0.10, 0.12, 0.10);
uniform float stripe_width = 0.06;
// The bottom of the wall gets grimy.
uniform float grime_height = 0.35;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wn = normalize(world_normal);
	vec3 w = pow(abs(wn), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec2 uv_x = world_pos.zy * scale;
	vec2 uv_y = world_pos.xz * scale;
	vec2 uv_z = world_pos.xy * scale;
	vec3 base = texture(albedo_tex, uv_x).rgb * w.x + texture(albedo_tex, uv_y).rgb * w.y
			+ texture(albedo_tex, uv_z).rgb * w.z;
	float rough = texture(rough_tex, uv_x).r * w.x + texture(rough_tex, uv_y).r * w.y
			+ texture(rough_tex, uv_z).r * w.z;

	float h = world_pos.y;
	vec3 paint = h < split_height ? lower_color : upper_color;
	if (abs(h - split_height) < stripe_width * 0.5) {
		paint = stripe_color;
	}
	vec3 col = base * paint * 1.6;
	col *= mix(0.55, 1.0, smoothstep(0.0, grime_height, h));
	ALBEDO = col;
	ROUGHNESS = h < split_height ? rough * 0.75 : rough;

	vec3 tn_x = texture(normal_tex, uv_x).rgb * 2.0 - 1.0;
	vec3 tn_y = texture(normal_tex, uv_y).rgb * 2.0 - 1.0;
	vec3 tn_z = texture(normal_tex, uv_z).rgb * 2.0 - 1.0;
	vec3 nx = vec3(tn_x.xy + wn.zy, abs(tn_x.z) * wn.x);
	vec3 ny = vec3(tn_y.xy + wn.xz, abs(tn_y.z) * wn.y);
	vec3 nz = vec3(tn_z.xy + wn.xy, abs(tn_z.z) * wn.z);
	vec3 n = normalize(nx.zyx * w.x + ny.xzy * w.y + nz.xyz * w.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
}
