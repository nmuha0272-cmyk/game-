// The "found footage" look over the whole screen: dark corners (vignette),
// moving film grain, a tiny bit of color fringing at the edges, and a slow
// flicker in brightness. Turn it down in Settings if it's too much.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float vignette = 0.55;
uniform float grain = 0.035;
uniform float fringe = 0.0008;
// Extra darkness and redness when hurt (set from the HUD when downed).
uniform float hurt : hint_range(0.0, 1.0) = 0.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - 0.5;
	float dist = length(from_center);

	// Color fringing grows toward the edges.
	vec2 shift = from_center * dist * fringe * 40.0 * strength;
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	// Vignette.
	float v = smoothstep(0.85, 0.2, dist * (1.0 + vignette * strength));
	col *= mix(1.0, v, strength);

	// Grain that changes every frame.
	float n = rand(uv * vec2(1920.0, 1080.0) + fract(TIME * 7.13)) - 0.5;
	col += n * grain * strength;

	// Slow, subtle brightness flicker.
	col *= 1.0 - 0.015 * strength * sin(TIME * 23.0) * sin(TIME * 3.7);

	// Hurt: red, darker edges.
	col = mix(col, col * vec3(1.0, 0.35, 0.3), hurt * smoothstep(0.1, 0.6, dist));

	COLOR = vec4(col, 1.0);
}
