shader_type spatial;


render_mode
	depth_draw_opaque,
	cull_back,
	specular_disabled;


uniform sampler2D vp_tex : source_color, repeat_disable, filter_linear_mipmap_anisotropic, hint_default_white;


void fragment()
{
	vec3 c = texture(vp_tex, UV).xyz;
	ALBEDO = c;
	EMISSION = c * c;
	SPECULAR = 0.0;
}
