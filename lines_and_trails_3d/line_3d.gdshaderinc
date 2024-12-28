render_mode
#ifdef BLEND_MIX
	blend_mix,
	depth_draw_never,
#endif
#ifdef BLEND_ADD
	blend_add,
	depth_draw_never,
#endif
#ifdef UNLIT
	unshaded,
#else
	specular_disabled,
#endif
#ifdef BILLBOARD
	skip_vertex_transform,
#endif
	cull_disabled;

#ifndef CUSTOM_VERTEX
#ifdef BILLBOARD
void vertex() {
	vec3 p = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	VERTEX = p + UV.y * normalize(cross(p, t));
	NORMAL = (VIEW_MATRIX * vec4(0, 1, 0, 0)).xyz;
	UV.y = (sign(UV.y) + 1.0) / 2.0;
}
#endif
#endif

#ifndef CUSTOM_PROPERTIES
uniform sampler2D color_tex : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform float tex_tile_factor = 1.0;
uniform float tex_offset = 0.0;
#endif

#ifndef CUSTOM_FRAGMENT
void fragment() {
	vec4 c = texture(color_tex, vec2(UV.x * tex_tile_factor + tex_offset, UV.y));
	ALBEDO = COLOR.rgb * c.rgb;
#if defined(BLEND_MIX) || defined(BLEND_ADD)
	ALPHA = COLOR.a * c.a;
#endif
	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
}
#endif