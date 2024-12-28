shader_type spatial;

render_mode
	depth_draw_never,
	blend_mix,
	cull_back,
	specular_disabled;


uniform sampler2D vp_tex : source_color, repeat_disable, filter_linear_mipmap_anisotropic, hint_default_white;


void fragment()
{
	vec4 c = texture(vp_tex, UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	SPECULAR = 0.0;
}
