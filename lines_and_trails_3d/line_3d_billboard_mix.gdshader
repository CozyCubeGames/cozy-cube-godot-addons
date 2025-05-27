shader_type spatial;

#define BILLBOARD
#define BLEND_MIX
#include "line_3d.gdshaderinc"

void light()
{
	vec3 c = LIGHT_COLOR / PI;
	float a = ATTENUATION;
	DIFFUSE_LIGHT += a * c;
}