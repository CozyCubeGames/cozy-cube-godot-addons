shader_type spatial;

render_mode
	cull_back,
	specular_disabled,
	vertex_lighting;

uniform vec3 off_color: source_color = vec3(0.2);
uniform vec3 on_color: source_color = vec3(0.2);
uniform vec3 glow_color: source_color = vec3(0.05, 1.0, 0.1);
uniform float glow_strength: hint_range(0.0, 10.0, 0.01) = 1.0;

varying vec3 color;
varying vec3 glow;

void vertex()
{
	int bit_flag =
		int(INSTANCE_CUSTOM.r * 4.0) << 5 |
		int(INSTANCE_CUSTOM.g * 4.0) << 3 |
		int(INSTANCE_CUSTOM.b * 4.0) << 1 |
		int(INSTANCE_CUSTOM.a * 4.0) >> 1;
	int seg_idx = int(UV.x);
	float on = sign(float(bit_flag & (1 << (6 - seg_idx))));
	color = mix(off_color, on_color, on);
	glow = glow_color * (glow_strength * on);
}

void fragment()
{
	ALBEDO = color;
	EMISSION = glow;
}
