shader_type spatial;
render_mode
	cull_disabled,
	blend_add,
	unshaded;


uniform vec4 color: source_color = vec4(1, 1, 1, 1.0);
uniform float scroll_speed: hint_range(-1.0, 1.0) = 0.05;
uniform float fade_power: hint_range(0, 10) = 5;
uniform sampler2D beam_tex: source_color, filter_linear_mipmap, hint_default_white, repeat_enable;


void fragment()
{
	float b1 = texture(beam_tex, vec2(UV.x + TIME * scroll_speed, 1.0 - UV.y)).r;
	float b2 = texture(beam_tex, vec2(UV.x + TIME * scroll_speed * 0.5, 1.0 - UV.y)).r;
	ALBEDO = COLOR.rgb * color.rgb;
	ALPHA = COLOR.a * color.a * clamp(pow(UV.y, fade_power), 0, 1) * (b1 + b2);
}
