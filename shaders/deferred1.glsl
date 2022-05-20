#if defined vshader

uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;

#include "/common.glsl"

out vec3 wsunpos;
out vec3 wslpos;
out vec2 uv0;
out float sunvisibility;
out float moonvisibility;

void main(){
	gl_Position = ftransform();
	uv0 = gl_MultiTexCoord0.xy;
	sunvisibility = saturate(dot(normalize(sunPosition), normalize(upPosition)));
	moonvisibility = saturate(dot(normalize(-sunPosition), normalize(upPosition)));

	wsunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	wslpos = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
}
#elif defined fshader

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex4;

#define atmstuff
#define cloud2d
#define skystuff
#include "/constant.glsl"
#include "/common.glsl"

vec3 stoviewpos(vec2 coord, float depth){
	vec4 viewspace = gbufferProjectionInverse * vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
	return viewspace.xyz / viewspace.w;
}

vec3 viewtoworld(mat4 matrix, vec3 pos){
	return mat3(matrix) * pos + matrix[3].xyz;
}

in vec3 wsunpos;
in vec3 wslpos;
in vec2 uv0;
in float sunvisibility;
in float moonvisibility;

void main(){
	vec3 viewpos = stoviewpos(uv0, texture2D(depthtex0, uv0).r);
	vec3 viewpos1 = stoviewpos(uv0, texture2D(depthtex1, uv0).r);
	vec3 worldpos = viewtoworld(gbufferModelViewInverse, viewpos);
	vec3 worldpos1 = viewtoworld(gbufferModelViewInverse, viewpos1);

	vec3 suncolor = texelFetch(colortex4, ivec2(0, 17), 0).rgb;
	vec3 mooncolor = texelFetch(colortex4, ivec2(1, 17), 0).rgb;
	vec3 zenithcolor = texelFetch(colortex4, ivec2(2, 17), 0).rgb;

	vec3 color = texture2D(colortex0, uv0).rgb;
 	if(texture2D(depthtex0, uv0).r == 1.0){
		vec3 nworldpos1 = normalize(worldpos1);
		color = texture2D(colortex4, (touv(nworldpos1) * vec2(256.0, 128.0) + vec2(18.0, 0)) / vec2(viewWidth, viewHeight)).rgb;

		vec4 clouds2d = ccloud2d(nworldpos1, wsunpos, suncolor, mooncolor, zenithcolor);
		color = color * clouds2d.a + clouds2d.rgb;
		addskystuf(color, nworldpos1, wsunpos, suncolor, mooncolor, frameTimeCounter);
	}

	/* DRAWBUFFERS:05 */
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(color, 1.0);
}
#endif
