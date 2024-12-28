shader_type spatial;

render_mode
	depth_draw_opaque,
	cull_back,
	unshaded,
	specular_disabled;


uniform sampler2D vp_tex : source_color, repeat_disable, filter_linear_mipmap_anisotropic, hint_default_white;


void fragment()
{
	ALBEDO = texture(vp_tex, UV).xyz;
}
