#if defined vshader

uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
out vec3 wslpos;
out vec2 uv0;

void main(){
	gl_Position = ftransform();
	uv0 = gl_MultiTexCoord0.xy;
	wslpos = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
}
#elif defined fshader
const bool colortex5MipmapEnabled = true;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform int isEyeInWater;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

#define refutil
#include "/constant.glsl"
#include "/common.glsl"

vec3 viewtoworld(mat4 matrix, vec3 pos){
	return mat3(matrix) * pos + matrix[3].xyz;
}

vec3 stoviewpos(vec2 coord, float depth){
	vec4 viewspace = gbufferProjectionInverse * vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
	return viewspace.xyz / viewspace.w;
}

in vec3 wslpos;
in vec2 uv0;

void main(){
	vec3 viewpos = stoviewpos(uv0, texture2D(depthtex0, uv0).r);
	vec3 viewpos1 = stoviewpos(uv0, texture2D(depthtex1, uv0).r);
	vec3 worldpos = viewtoworld(gbufferModelViewInverse, viewpos);
	vec3 worldpos1 = viewtoworld(gbufferModelViewInverse, viewpos1);

	vec3 color = texture2D(colortex0, uv0).rgb;
	vec4 gbdata1 = texture2D(colortex1, uv0);
	vec4 gbdata2 = texture2D(colortex2, uv0);
	vec4 gbdata3 = texture2D(colortex3, uv0);

	vec3 normal = unpacknm(gbdata1.rg);
	vec3 oalbedo = gbdata2.rgb;
	float skylightmap = gbdata1.b;
	float lightvis = gbdata1.a;
	float flag = gbdata2.a;
	float roughness = gbdata3.g;
	float f0 = gbdata3.r;

	vec3 viewdirection = normalize(-worldpos);
	vec3 halfdirection = normalize(viewdirection + wslpos);
	normal = mat3(gbufferModelViewInverse) * normal;

	float vdoth = saturate(dot(viewdirection, halfdirection));
	float ndoth = saturate(dot(normal, halfdirection));
	float ndotv = saturate(dot(normal, viewdirection));
	float ndotl = saturate(dot(normal, wslpos));

	vec3 reflectance = mix(vec3(0.04), oalbedo, f0);
	vec3 envspeccol = environmentbrdf(reflectance, roughness, ndotv);
	vec3 envreflection = textureLod(colortex5, uv0, (roughness * roughness) * 20.0).rgb;
	vec3 specref = envspeccol * envreflection;

	vec3 fresnel = fresnelschlick(reflectance, vdoth);
	float ld = distributionggx(roughness, ndoth);
	float lv = visibleggx(roughness, ndotv, ndotl);
	vec3 lightcolor = texelFetch(colortex4, ivec2(3, 17), 0).rgb;
	specref += lightcolor * fresnel * (ld * lv * tau * lightvis * ndotl);

	if(texture2D(depthtex1, uv0).r >= 0.0){
		color = mix(color, vec3(0.0), f0);
		color += specref;
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
#endif
