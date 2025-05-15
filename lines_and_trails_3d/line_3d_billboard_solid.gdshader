shader_type spatial;

#define BILLBOARD
#include "line_3d.gdshaderinc"

void light()
{
	vec3 c = LIGHT_COLOR / PI;
	float a = ATTENUATION;
	DIFFUSE_LIGHT += a * c;
}