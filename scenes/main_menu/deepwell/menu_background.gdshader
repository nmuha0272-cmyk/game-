// Deepwell main menu background.
// Draws the Blackwater Weather Station like an old black-and-white archive
// photo: a pale 1960s government building with a long low left wing, a
// taller center entrance block (mural over glass doors, decorative panels),
// a long right wing with big grid windows, trees and a telephone pole,
// an overcast sky and a lawn in front. Every few seconds a tall, thin shape
// appears in one of the windows.
// Shapes are laid out in "photo pixels" (a 654 x 468 grid) so they are easy
// to adjust. Everything is drawn with code, so no image files are needed.
shader_type canvas_item;

uniform float brightness : hint_range(0.3, 2.0) = 1.0;
uniform float mood : hint_range(0.0, 1.0) = 0.35; // 0 = bright day, 1 = very dark
uniform float grain_amount : hint_range(0.0, 0.3) = 0.08;
uniform float scanline_amount : hint_range(0.0, 0.5) = 0.08;
uniform float picture_scale = 1.15;   // size of the picture (in screen heights)
uniform float picture_top = 0.03;     // where the picture starts vertically
uniform bool show_figure = true;      // the shape that appears in a window

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return value;
}

// 1.0 inside the rectangle (x0, y0) to (x1, y1), in photo pixels.
float rect(vec2 q, float x0, float y0, float x1, float y1) {
	return step(x0, q.x) * step(q.x, x1) * step(y0, q.y) * step(q.y, y1);
}

// A grid window: dark glass split into cols x rows panes by pale frames.
float grid_window(vec2 q, float x0, float y0, float x1, float y1, float cols, float rows) {
	if (rect(q, x0, y0, x1, y1) < 0.5) {
		return 0.0;
	}
	vec2 local = (q - vec2(x0, y0)) / vec2(x1 - x0, y1 - y0) * vec2(cols, rows);
	vec2 f = fract(local);
	float frame = step(f.x, 0.08) + step(f.y, 0.1);
	return 1.0 - clamp(frame, 0.0, 1.0) * 0.6;
}

// Leafy tree canopy (ellipse with ragged edges).
float canopy(vec2 q, vec2 c, vec2 r) {
	float edge = fbm(q * 0.09) * 0.45;
	return step(length((q - c) / r), 0.8 + edge);
}

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(uv.x * aspect, uv.y);

	// Place the 654 x 468 "photo" against the right side of the screen.
	vec2 origin = vec2(aspect - 1.3975 * picture_scale + 0.02, picture_top);
	vec2 q = (p - origin) / picture_scale * 468.0;

	// ---- Overcast sky with big soft clouds.
	float clouds = fbm(q * 0.006 + vec2(TIME * 0.006, 0.0));
	float puffs = fbm(q * 0.015 - vec2(TIME * 0.01, 0.0));
	float shade = 0.62 + clouds * 0.3 + puffs * 0.1 - (1.0 - q.y / 300.0) * 0.12;

	// Distant tree line at the horizon on the left.
	float far_trees = step(268.0 - fbm(vec2(q.x * 0.08, 1.0)) * 40.0, q.y) * step(q.x, 60.0);
	shade = mix(shade, 0.35, far_trees);

	// ---- Lawn, sidewalks and footpath.
	if (q.y > 282.0) {
		float grass = fbm(q * vec2(0.25, 0.9)) * 0.12 + noise(q * 1.5) * 0.06;
		shade = 0.38 + grass - smoothstep(282.0, 468.0, q.y) * 0.06;
		// Back lawn is a bit lighter, front lawn a bit darker (like the photo).
		shade += step(q.y, 302.0) * 0.06;
		// Curved sidewalk on the left and straight sidewalk on the right.
		float left_walk = step(abs(q.y - (286.0 + q.x * 0.03)), 1.6) * step(q.x, 340.0);
		float right_walk = step(abs(q.y - 297.0), 2.0) * step(330.0, q.x);
		float entry_walk = step(abs(q.x - (268.0 + (q.y - 280.0) * 2.2)), 4.0 + (q.y - 280.0) * 0.2) * step(q.y, 300.0);
		float drain = rect(q, 435.0, 300.0, 450.0, 303.0) * 0.5;
		shade = mix(shade, 0.85, clamp(left_walk + right_walk + entry_walk, 0.0, 1.0));
		shade = mix(shade, 0.2, drain);
	}

	// ---- The building.
	float left_wing = rect(q, 10.0, 207.0, 186.0, 282.0);
	float center_block = rect(q, 184.0, 171.0, 356.0, 282.0);
	float right_wing = rect(q, 354.0, 176.0, 700.0, 282.0);
	if (left_wing + center_block + right_wing > 0.5) {
		// Pale concrete with soft block lines and a little dirt near the bottom.
		float blocks = step(0.94, fract(q.y / 9.0)) * 0.025 + step(0.97, fract(q.x / 18.0)) * 0.015;
		shade = 0.84 - blocks + fbm(q * 0.3) * 0.05 - smoothstep(250.0, 282.0, q.y) * 0.05;
		// The center block sticks out a little, so it's slightly brighter.
		shade += center_block * 0.03;
		// Roof trims.
		shade -= rect(q, 10.0, 207.0, 186.0, 210.0) * 0.08;
		shade -= rect(q, 184.0, 171.0, 356.0, 175.0) * 0.06;
		shade -= rect(q, 354.0, 176.0, 700.0, 179.0) * 0.08;
		// Shadow line where the center block meets each wing.
		shade -= (rect(q, 184.0, 207.0, 187.0, 282.0) + rect(q, 353.0, 176.0, 356.0, 282.0)) * 0.12;

		// Left wing windows, two rows.
		float win = 0.0;
		for (int row = 0; row < 2; row++) {
			float y0;
			if (row == 0) {
				y0 = 218.0;
			} else {
				y0 = 246.0;
			}
			win += grid_window(q, 18.0, y0, 32.0, y0 + 15.0, 1.0, 1.0);
			win += grid_window(q, 45.0, y0, 70.0, y0 + 15.0, 2.0, 1.0);
			win += grid_window(q, 82.0, y0, 106.0, y0 + 15.0, 2.0, 1.0);
			win += grid_window(q, 116.0, y0, 134.0, y0 + 15.0, 1.0, 1.0);
		}

		// Center block: four tall decorative panels, each with three small windows.
		for (int col = 0; col < 4; col++) {
			float x0;
			if (col == 0) {
				x0 = 197.0;
			} else if (col == 1) {
				x0 = 222.0;
			} else if (col == 2) {
				x0 = 292.0;
			} else {
				x0 = 317.0;
			}
			float panel = rect(q, x0, 183.0, x0 + 20.0, 272.0);
			float panel_edge = panel - rect(q, x0 + 1.5, 184.5, x0 + 18.5, 270.5);
			shade -= panel_edge * 0.07;
			shade += (panel - panel_edge) * 0.03;
			for (int r = 0; r < 3; r++) {
				float y0 = 197.0 + float(r) * 24.0;
				win += rect(q, x0 + 6.0, y0, x0 + 14.0, y0 + 11.0);
			}
		}

		// Right wing: big grid windows, two rows.
		for (int row = 0; row < 2; row++) {
			float y0;
			if (row == 0) {
				y0 = 186.0;
			} else {
				y0 = 234.0;
			}
			win += grid_window(q, 410.0, y0, 476.0, y0 + 23.0, 4.0, 2.0);
			win += grid_window(q, 524.0, y0, 591.0, y0 + 23.0, 4.0, 2.0);
			win += grid_window(q, 618.0, y0, 690.0, y0 + 23.0, 4.0, 2.0);
		}
		win = clamp(win, 0.0, 1.0);
		float glass = 0.2 + fbm(q * 0.2) * 0.06;
		shade = mix(shade, glass, win);

		// A tall, thin shape that sometimes stands in a left-wing window.
		if (show_figure) {
			float visible = step(0.82, fract(TIME / 14.0));
			float body = rect(q, 92.0, 247.0, 96.0, 261.0) + rect(q, 91.0, 244.0, 97.0, 249.0);
			shade = mix(shade, 0.04, clamp(body, 0.0, 1.0) * visible * step(0.5, win));
		}

		// Mural above the doors: a dark ornate panel inside a light frame.
		float mural = rect(q, 247.0, 186.0, 289.0, 223.0);
		float mural_frame = rect(q, 244.0, 183.0, 292.0, 226.0) - mural;
		float pattern = fbm(q * 0.25 + vec2(4.0, 1.0));
		float swirl = smoothstep(0.45, 0.55, pattern) * 0.45 + step(0.62, fbm(q * 0.6)) * 0.2;
		shade = mix(shade, 0.22 + swirl, mural);
		shade = mix(shade, 0.9, mural_frame);

		// Flat canopy over the entrance, with a shadow underneath.
		shade = mix(shade, 0.92, rect(q, 238.0, 234.0, 298.0, 239.0));
		shade -= rect(q, 240.0, 239.0, 296.0, 243.0) * 0.18;

		// Glass doors with frames, and pale steps below.
		float doors = rect(q, 250.0, 243.0, 287.0, 272.0);
		float mullion = step(0.86, fract((q.x - 250.0) / 9.25));
		shade = mix(shade, 0.16 + mullion * 0.5, doors);
		shade = mix(shade, 0.78, rect(q, 244.0, 272.0, 293.0, 282.0));
	}

	// ---- Bushes and flower beds along the base of the building.
	float bumps = abs(sin(q.x * 0.11)) * 7.0 + fbm(vec2(q.x * 0.2, 3.0)) * 6.0;
	float bush_top = 276.0 - bumps;
	float beds = step(bush_top, q.y) * step(q.y, 286.0) * (step(176.0, q.x) * step(q.x, 244.0) + step(292.0, q.x) * step(q.x, 345.0) + step(470.0, q.x) * step(q.x, 700.0));
	shade = mix(shade, 0.26 + fbm(q * 0.5) * 0.16, clamp(beds, 0.0, 1.0));

	// ---- Trees (dark, leafy) and the telephone pole.
	float trees = canopy(q, vec2(457.0, 195.0), vec2(58.0, 66.0));
	trees = max(trees, rect(q, 453.0, 240.0, 459.0, 302.0));
	trees = max(trees, canopy(q, vec2(374.0, 212.0), vec2(34.0, 44.0)));
	trees = max(trees, rect(q, 372.0, 245.0, 376.0, 323.0));
	float conifer = step(abs(q.x - 156.0), (q.y - 222.0) * 0.32) * step(222.0, q.y) * step(q.y, 284.0);
	trees = max(trees, conifer * step(0.35, fbm(q * 0.3)));
	trees = max(trees, canopy(q, vec2(8.0, 238.0), vec2(16.0, 30.0)));
	shade = mix(shade, 0.12 + fbm(q * 0.35) * 0.18, trees);

	float pole = rect(q, 48.0, 186.0, 51.0, 284.0) + rect(q, 36.0, 190.0, 64.0, 192.0);
	float wires = step(abs(q.y - (191.0 + (50.0 - q.x) * 0.06)), 0.35) * step(q.x, 50.0) * step(-60.0, q.x) * 0.6;
	shade = mix(shade, 0.12, clamp(pole + wires, 0.0, 1.0));

	// Small shadow under the big tree.
	shade -= step(abs(q.y - 300.0), 5.0) * step(abs(q.x - 455.0), 40.0) * 0.06;

	// ---- Mood: overall darkening, plus darker left side so the menu text is readable.
	shade *= mix(1.0, 0.45, mood);
	shade *= mix(0.22, 1.0, smoothstep(0.05, 0.55, uv.x));
	shade *= mix(0.5, 1.0, smoothstep(0.0, 0.18, uv.y));

	vec3 col = vec3(shade);

	// Old video tape "tracking" line, vignette, scanlines, and film grain.
	float band = smoothstep(0.006, 0.0, abs(uv.y - fract(TIME * 0.06)));
	col += vec3(band * 0.04);
	vec2 centered = (uv - 0.5) * vec2(1.2, 1.1);
	col *= clamp(1.0 - dot(centered, centered) * 1.4, 0.0, 1.0);
	col *= 1.0 - scanline_amount * (0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159));
	col += (hash(FRAGCOORD.xy + fract(TIME) * 113.0) - 0.5) * grain_amount;

	COLOR = vec4(col * brightness, 1.0);
}
