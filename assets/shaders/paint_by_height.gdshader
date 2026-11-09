shader_type spatial;
// Colors a model that came without textures (the new Eli from Tripo), by
// where each spot is on the body: boots, jeans, hands, belt, jacket, the
// shirt under it, skin, hair. Heights are in the model's own units (0 = feet,
// 1 = top of the head). Only until the real textures come.

uniform vec3 boots : source_color = vec3(0.13, 0.1, 0.08);
uniform vec3 jeans : source_color = vec3(0.2, 0.26, 0.38);
uniform vec3 belt : source_color = vec3(0.08, 0.07, 0.06);
uniform vec3 jacket : source_color = vec3(0.4, 0.25, 0.14);
uniform vec3 shirt : source_color = vec3(0.72, 0.71, 0.68);
uniform vec3 skin : source_color = vec3(0.74, 0.56, 0.45);
uniform vec3 hair : source_color = vec3(0.11, 0.08, 0.06);

varying vec3 body;

void vertex() {
	body = VERTEX;
}

void fragment() {
	float y = body.y;
	float side = abs(body.x);
	vec3 c = jacket;
	if (y < 0.065) c = boots;
	else if (side > 0.14 && y > 0.31 && y < 0.505) c = skin;                     // hands (fingertips too)
	else if (y < 0.45 || (side < 0.06 && body.z > 0.0 && y < 0.535)) c = jeans;  // jeans (and the top, seen in front)
	else if (y < 0.825) {
		c = jacket;
		if (side < 0.05 && y > 0.53 && y < 0.565 && body.z > 0.015) c = belt;        // belt, seen through the open jacket
		else if (side < 0.045 && y > 0.565 && body.z > -0.01) c = shirt;  // shirt under the open jacket
	}
	else if (y < 0.875) {
		// The chin and neck (the jacket collar is round the sides and back).
		if (side < 0.05 && body.z > -0.035) c = skin;
		else c = jacket;
	}
	else if (y > 0.935 || (y > 0.89 && body.z < -0.015) || (y > 0.91 && side > 0.043)) c = hair;
	else c = skin;
	ALBEDO = c;
	ROUGHNESS = 0.82;
}
