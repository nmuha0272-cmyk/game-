// The ground and the carved underground. Picks a texture by which way a
// surface faces, in world space, so it never stretches:
//   facing up, near the surface   -> dirt and gravel (outside)
//   facing up, underground        -> concrete floor
//   walls                         -> cinder blocks
//   facing down (ceilings)        -> plain concrete
shader_type spatial;

uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_rough : filter_linear_mipmap, repeat_enable;
uniform sampler2D floor_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_rough : filter_linear_mipmap, repeat_enable;
uniform sampler2D wall_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wall_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wall_rough : filter_linear_mipmap, repeat_enable;
uniform sampler2D ceiling_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ceiling_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ceiling_rough : filter_linear_mipmap, repeat_enable;

uniform float ground_scale = 0.25;
uniform float floor_scale = 0.3;
uniform float wall_scale = 0.35;
uniform float ceiling_scale = 0.3;
// Above this height an upward face counts as "outside".
uniform float surface_height = -0.5;
uniform vec3 underground_tint : source_color = vec3(0.85, 0.9, 0.85);
uniform float normal_strength = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 unpack(vec3 n) {
	vec3 t = n * 2.0 - 1.0;
	t.xy *= normal_strength;
	return t;
}

void fragment() {
	vec3 wn = normalize(world_normal);
	vec3 w = pow(abs(wn), vec3(4.0));
	w /= (w.x + w.y + w.z);

	// Walls: project along X and along Z.
	vec2 uv_x = world_pos.zy * wall_scale;
	vec2 uv_z = world_pos.xy * wall_scale;
	vec3 alb_x = texture(wall_albedo, uv_x).rgb;
	vec3 alb_z = texture(wall_albedo, uv_z).rgb;
	float r_x = texture(wall_rough, uv_x).r;
	float r_z = texture(wall_rough, uv_z).r;
	vec3 tn_x = unpack(texture(wall_normal, uv_x).rgb);
	vec3 tn_z = unpack(texture(wall_normal, uv_z).rgb);

	// Floors and ceilings: project along Y.
	vec3 alb_y; float r_y; vec3 tn_y;
	if (wn.y > 0.0) {
		if (world_pos.y > surface_height) {
			vec2 uv = world_pos.xz * ground_scale;
			alb_y = texture(ground_albedo, uv).rgb;
			r_y = texture(ground_rough, uv).r;
			tn_y = unpack(texture(ground_normal, uv).rgb);
		} else {
			vec2 uv = world_pos.xz * floor_scale;
			alb_y = texture(floor_albedo, uv).rgb;
			r_y = texture(floor_rough, uv).r;
			tn_y = unpack(texture(floor_normal, uv).rgb);
		}
	} else {
		vec2 uv = world_pos.xz * ceiling_scale;
		alb_y = texture(ceiling_albedo, uv).rgb;
		r_y = texture(ceiling_rough, uv).r;
		tn_y = unpack(texture(ceiling_normal, uv).rgb);
	}

	vec3 albedo = alb_x * w.x + alb_y * w.y + alb_z * w.z;
	if (world_pos.y < surface_height) {
		albedo *= underground_tint;
	}
	ALBEDO = albedo;
	ROUGHNESS = r_x * w.x + r_y * w.y + r_z * w.z;

	// "Whiteout" blend of the three normal maps into a world normal.
	vec3 nx = vec3(tn_x.xy + wn.zy, abs(tn_x.z) * wn.x);
	vec3 ny = vec3(tn_y.xy + wn.xz, abs(tn_y.z) * wn.y);
	vec3 nz = vec3(tn_z.xy + wn.xy, abs(tn_z.z) * wn.z);
	vec3 n = normalize(nx.zyx * w.x + ny.xzy * w.y + nz.xyz * w.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
}
