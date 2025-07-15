shader_type spatial;
render_mode cull_front, unshaded;

uniform vec3 color : source_color = vec3(0,0,0);
uniform float thickness : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float alpha : hint_range(0.0, 1.0, 0.01) = 1.0;

void vertex() {
	VERTEX += thickness*NORMAL;
}

void fragment() {
	ALBEDO = color;
	ALPHA = alpha;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
