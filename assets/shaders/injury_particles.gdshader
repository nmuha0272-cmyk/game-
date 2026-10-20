shader_type particles;

render_mode disable_depth, unshaded;

uniform sampler2D texture_particle;
uniform float time;

void vertex() {
	// Particles stay near the player's leg
	TRANSFORM[3].y = 0.5 + sin(time * 5.0) * 0.1;
	
	// Flicker
	float flicker = step(0.5, fract(TIME * 20.0 + INDEX * 0.1));
	COLOR.a *= flicker * 0.3;
	
	// Red tint for blood/injury
	COLOR.rgb = vec3(1.0, 0.2, 0.1);
}

void fragment() {
	COLOR = texture(texture_particle, UV) * COLOR;
}