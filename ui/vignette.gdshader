shader_type canvas_item;
// Darkens the screen edges and adds a little film grain.

uniform float strength : hint_range(0.0, 1.0) = 0.7;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.25;
uniform float outer_radius : hint_range(0.0, 1.5) = 0.8;
uniform float grain : hint_range(0.0, 0.3) = 0.06;

float random(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float dist = distance(UV, vec2(0.5));
	float vignette = smoothstep(inner_radius, outer_radius, dist) * strength;
	float noise = random(UV + fract(TIME)) * grain;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(vignette + noise, 0.0, 1.0));
}
