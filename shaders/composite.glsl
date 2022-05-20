#if defined vshader

uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;

out vec3 wslpos;
out vec3 wsunpos;
out vec2 uv0;

void main(){
	gl_Position = ftransform();
	uv0 = gl_MultiTexCoord0.xy;

	wsunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	wslpos = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
}
#elif defined fshader

uniform sampler2D colortex0;

#include "/common.glsl"

in vec3 wslpos;
in vec3 wsunpos;
in vec2 uv0;

const float sunPathRotation = -30.0;

void main(){
	vec3 color = texture2D(colortex0, uv0).rgb;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
#endif
