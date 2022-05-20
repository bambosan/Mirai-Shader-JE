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
	wslpos = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
	wsunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
}
#elif defined fshader

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float near;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;

#define atmstuff
#define skystuff
#include "/constant.glsl"
#include "/common.glsl"

vec3 stoviewpos(vec2 coord, float depth){
	vec4 viewspace = gbufferProjectionInverse * vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
	return viewspace.xyz / viewspace.w;
}

vec3 viewtoscreenp(vec3 viewpos){
	vec4 screenspace = gbufferProjection * vec4(viewpos, 1.0);
	screenspace.xyz /= screenspace.w;
	return screenspace.xyz * 0.5 + 0.5;
}

vec3 skyreflect(vec3 reflectedv, vec3 wsunpos, vec3 wslpos, float skylm, float lightvis){
	vec3 color = texture2D(colortex4, (touv(reflectedv) * vec2(256.0, 128.0) + vec2(18.0, 0)) / vec2(viewWidth, viewHeight)).rgb;
	vec3 suncolor = texelFetch(colortex4, ivec2(0, 17), 0).rgb;
	vec3 mooncolor = texelFetch(colortex4, ivec2(1, 17), 0).rgb;
	vec3 zenithcolor = texelFetch(colortex4, ivec2(2, 17), 0).rgb;

	vec4 clouds2d = texture2D(colortex4, (touv(reflectedv) * vec2(512.0, 256.0) + vec2(0.0, 129.0)) / vec2(viewWidth, viewHeight));
	color = color * clouds2d.a + clouds2d.rgb;
	color = color * (skylm * skylm);
	suncolor *= lightvis;
	mooncolor *= lightvis;
	addskystuf(color, reflectedv, wsunpos, suncolor, mooncolor, frameTimeCounter);
	return color;
}

bool raytrace(vec3 viewpos, vec3 reflectedv, vec2 screenpos, out vec3 rtposhit){
	vec3 rayorigin = vec3(screenpos, texture2D(depthtex0, screenpos).r);
	float raylength = ((viewpos.z + reflectedv.z * far * 1.73205080757) > -near) ? (-near - viewpos.z) / reflectedv.z : far * 1.73205080757;
	reflectedv *= raylength;

	vec3 raydirection = normalize(viewtoscreenp(viewpos + reflectedv) - rayorigin) / raysstep;
	rayorigin = rayorigin + raydirection * texture2D(noisetex, gl_FragCoord.xy / 256.0).r;

	for(int i = 0; i < raysstep; i++){
		rayorigin += raydirection;
		if(saturate(rayorigin.xy) != rayorigin.xy) break;
		float sampledepth = texture2D(depthtex0, rayorigin.xy).r;

		if(rayorigin.z > sampledepth && sampledepth > 0.56){
			for(int j = 0; j < refinestep; j++){
				raydirection *= 0.5;
				if(rayorigin.z > texture2D(depthtex0, rayorigin.xy).r) rayorigin -= raydirection; else rayorigin += raydirection;
			}
			rtposhit = rayorigin;
			return true;
		}
	}
	return false;
}

in vec3 wslpos;
in vec3 wsunpos;
in vec2 uv0;

void main(){
	vec3 viewpos = stoviewpos(uv0, texture2D(depthtex1, uv0).r);
	vec3 worldpos = mat3(gbufferModelViewInverse) * viewpos;
	vec4 gbdata1 = texture2D(colortex1, uv0);
	vec3 normal = unpacknm(gbdata1.rg);
	vec3 wnormal = mat3(gbufferModelViewInverse) * normal;

	vec3 reflectedv = reflect(normalize(worldpos), wnormal);
	vec3 color = skyreflect(reflectedv, wsunpos, wslpos, gbdata1.b, gbdata1.a);

	reflectedv = reflect(normalize(viewpos), normal);
	vec3 rtposhit = vec3(0.0);
	bool raytracehit = raytrace(viewpos, reflectedv, uv0, rtposhit);
	if(raytracehit) color = texture2D(colortex0, rtposhit.xy).rgb;

	/* DRAWBUFFERS:5 */
	gl_FragData[0] = vec4(color, 1.0);
}
#endif
