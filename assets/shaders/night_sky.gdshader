// A cold night sky: dark gradient, a hazy full moon, and faint stars.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.005, 0.008, 0.02);
uniform vec3 horizon_color : source_color = vec3(0.04, 0.05, 0.07);
uniform vec3 ground_color : source_color = vec3(0.01, 0.01, 0.012);
uniform vec3 moon_direction = vec3(0.45, 0.35, 0.82);
uniform vec3 moon_color : source_color = vec3(0.85, 0.88, 1.0);
uniform float star_density = 0.0025;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = d.y;
	vec3 col = up > 0.0 ? mix(horizon_color, top_color, pow(up, 0.5)) : ground_color;

	// Stars: only some cells on a grid get a tiny dot. Fewer near the horizon.
	if (up > 0.05) {
		vec3 cell = floor(d * 300.0);
		float h = hash(cell);
		if (h < star_density) {
			vec3 center = (cell + 0.5) / 300.0;
			float dist = length(d - normalize(center)) * 300.0;
			float twinkle = 0.6 + 0.4 * sin(TIME * (2.0 + h * 900.0));
			col += vec3(0.8, 0.85, 1.0) * smoothstep(0.6, 0.0, dist) * twinkle * smoothstep(0.05, 0.4, up);
		}
	}

	// The moon: a disc with a soft glow around it.
	float m = dot(d, normalize(moon_direction));
	col += moon_color * smoothstep(0.9993, 0.9996, m) * 1.5;
	col += moon_color * pow(max(m, 0.0), 300.0) * 0.25;
	col += moon_color * pow(max(m, 0.0), 12.0) * 0.03;
	COLOR = col;
}
