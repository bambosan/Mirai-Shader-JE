#if defined vshader

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;

attribute vec4 at_tangent;
attribute vec3 mc_Entity;

#include "/common.glsl"

out vec4 vcolor;
out vec4 normal;
out vec3 worldpos;
out vec3 viewpos;
out vec3 wsunpos;
out vec3 wslpos;
out vec3 nlightpos;
out mat3 tbn;
out vec2 uv0;
out vec2 uv1;
out float lightvis;

void main(){
	uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	uv1  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	vcolor = gl_Color;
	viewpos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	worldpos = mat3(gbufferModelViewInverse) * viewpos + gbufferModelViewInverse[3].xyz;
	wsunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	nlightpos = normalize(shadowLightPosition);
	wslpos = mat3(gbufferModelViewInverse) * nlightpos;
	lightvis = saturate(dot(normalize(shadowLightPosition), normalize(upPosition)));

	normal.xyz = normalize(gl_NormalMatrix * gl_Normal);
	normal.a = 0.0;
	if(mc_Entity.x == 1) normal.a = 0.1;
	if(mc_Entity.x == 6 || mc_Entity.x == 8 || mc_Entity.x == 9 || mc_Entity.x == 10 || mc_Entity.x == 11 || mc_Entity.x == 12) normal.a = 0.2;
	if(mc_Entity.x == 4) normal.a = 0.4;
	if(mc_Entity.x == 13) normal.a = 0.5;

	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tbn = transpose(mat3(tangent, binormal, normal.xyz));
	gl_Position = ftransform();
}
#elif defined fshader

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D gaux1;
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

#define atmstuff
#if defined gbwater
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float far;
uniform float near;
uniform sampler2D depthtex1;
uniform sampler2D gaux2;
#define skystuff
#define refutil
#endif
#include "/constant.glsl"
#include "/common.glsl"

float bndither = texture2D(noisetex, gl_FragCoord.xy / 256.0).r;
float invshadowres = 1.0 / shadowMapResolution;
vec3 viewtoworld(mat4 matrix, vec3 pos){ return mat3(matrix) * pos + matrix[3].xyz; }

float shadowpcf(sampler2D shadowtexx, vec3 shadowpos, float blurthick){
	float result = 0.0;
	for(int i = 0; i < PCFSample; i++){
		vec2 offsetcoord = shadowpos.xy + (rotate2d(bndither * tau) * poisson[i] * blurthick);
		result += step(shadowpos.z, texture2D(shadowtexx, offsetcoord).r);
	}
	result /= PCFSample;
	return result;
}

#ifdef EnablePCSS
float calcsdepth(vec3 shadowpos){
	float depthsample = 0.0;
	float penumbrawidth = pcssmaxbrad / shadowMapResolution;

	for(int i = 0; i < BlockerSample; i++){
		vec2 offsetcoord = shadowpos.xy + (poisson[i] * penumbrawidth);
		depthsample += max0(shadowpos.z - texture2D(shadowtex1, offsetcoord).r);
	}
	depthsample /= BlockerSample;
	return depthsample;
}
#endif

vec3 shposwbias(vec3 worldpos, float lightvis){
	vec3 shadowpos = viewtoworld(shadowModelView, worldpos);
	shadowpos = viewtoworld(shadowProjection, shadowpos);
	float dist = sdistort(shadowpos.xy, shadowDistortFactor);

	shadowpos.xy /= dist;
	shadowpos.z *= 0.25;
	shadowpos.z -= (dist * dist * invshadowres * 2.0) / lightvis;
	return shadowpos * 0.5 + 0.5;
}

#ifdef EnableSSS
vec3 subsurfaces(vec3 currlight, vec3 worldpos, vec3 wslpos, float thickness){
	if(thickness < 0.001) return currlight;

	vec3 shadowpos = viewtoworld(shadowModelView, worldpos);
	shadowpos = viewtoworld(shadowProjection, shadowpos);
	shadowpos.xy /= sdistort(shadowpos.xy, shadowDistortFactor);
	shadowpos.z *= 0.25;
	shadowpos = shadowpos * 0.5 + 0.5;

	float ssssample = 0.0;
	if(length(worldpos) < shadowDistance){
		for(int i = 0; i < sssquality; i++){
			vec2 offsetcoord = shadowpos.xy + (rotate2d(bndither * tau) * poisson[i] * thickness);
			ssssample += step(shadowpos.z, texture2D(shadowtex1, offsetcoord).r);
		}
		ssssample /= sssquality;
	}

	float phasel = miephase(saturate(1.0 - distance(normalize(worldpos), wslpos)), 0.7);
	return mix(currlight, vec3(phasel * 0.5 + 0.5), ssssample);
}
#endif

#ifdef gbwater

// trochoidal waves
// https://github.com/robobo1221/robobo1221Shaders/tree/master/shaders/lib/fragment
float calctrocoidalwave(vec2 coord, float wavelength, float movement, vec2 wavedir, float waveamp, float wavestepness){
	float k = 6.28318531 / wavelength;
	float x = sqrt(19.6 * k) * movement - (k * dot(wavedir, coord));
	float wave = sin(x) * 0.5 + 0.5;
	return waveamp * pow(wave, wavestepness);
}

float calctrocoidalwave(vec2 coord){
	float wavelength = 10.0;
	float movement = frameTimeCounter * wwspeed;
	float waveamp = 0.07;
	float wavestepness = 0.6;
	vec2 wavedir = vec2(1.0, 0.5);
	float waves = 0.0;

	for(int i = 0; i < 10; ++i){
		waves += calctrocoidalwave(coord, wavelength, movement, wavedir, waveamp, wavestepness);
		wavelength *= 0.7;
		waveamp *= 0.62;
		wavestepness *= 1.03;
		wavedir *= rotate2d(0.5);
		movement *= 1.1;
	}
	return -waves;
}

vec3 viewtoscreenp(vec3 viewposp){
	vec4 screenspace = gbufferProjection * vec4(viewposp, 1.0);
	screenspace.xyz /= screenspace.w;
	return screenspace.xyz * 0.5 + 0.5;
}

vec3 stoviewpos(vec3 screenpos){
	vec4 viewspace = gbufferProjectionInverse * vec4(screenpos * 2.0 - 1.0, 1.0);
	return viewspace.xyz / viewspace.w;
}

bool raytrace(vec3 viewposp, vec3 reflectedv, vec2 screenpos, out vec3 rtposhit){
	float raylength = ((viewposp.z + reflectedv.z * far * 1.73205080757) > -near) ? (-near - viewposp.z) / reflectedv.z : far * 1.73205080757;
	reflectedv *= raylength;

	vec3 rayorigin = vec3(screenpos, gl_FragCoord.z);
	vec3 raydirection = normalize(viewtoscreenp(viewposp + reflectedv) - rayorigin) / raysstep;
	rayorigin = rayorigin + raydirection * texture2D(noisetex, gl_FragCoord.xy / 256.0).r;

	for(int i = 0; i < raysstep; i++){
		rayorigin += raydirection;
		if(saturate(rayorigin.xy) != rayorigin.xy) break;
		float sampledepth = texture2D(depthtex1, rayorigin.xy).r;

		if(rayorigin.z > sampledepth && sampledepth > 0.56){
			for(int j = 0; j < refinestep; j++){
				raydirection *= 0.5;
				if(rayorigin.z > texture2D(depthtex1, rayorigin.xy).r) rayorigin -= raydirection; else rayorigin += raydirection;
			}
			rtposhit = rayorigin;
			return true;
		}
	}
	return false;
}
#endif


in vec4 vcolor;
in vec4 normal;
in vec3 worldpos;
in vec3 viewpos;
in vec3 wsunpos;
in vec3 wslpos;
in vec3 nlightpos;
in mat3 tbn;
in vec2 uv0;
in vec2 uv1;
in float lightvis;

#if defined gbwater
void calcwaternormal(inout vec3 normalmap){
	vec2 posxz = worldpos.xz * wwscale + cameraPosition.xz;
	float h0 = calctrocoidalwave(posxz);
	float h1 = calctrocoidalwave(posxz + vec2(wnormaloffset, 0.0));
	float h2 = calctrocoidalwave(posxz + vec2(0.0, wnormaloffset));
	float xd = (h0 - h1), yd = (h0 - h2);

	if(normal.a > 0.0 && normal.a < 0.2){
		normalmap = normalize(vec3(xd, yd, 1.0));
		normalmap = normalmap * wnormalstrength + vec3(0.0, 0.0, 1.0 - wnormalstrength);
		normalmap = (normalmap * 0.5 + 0.5) * 2.0 - 1.0;
		normalmap = normalize(normalmap * tbn);
	}
}

void calcforwardrr(inout vec4 albedo, vec3 normalmap, vec2 material, float shadowlum){
	vec3 wnormal = mat3(gbufferModelViewInverse) * normalmap;
	vec3 reflectedv = reflect(normalize(worldpos), wnormal);
	vec3 viewdirection = normalize(-worldpos);
	vec3 halfdirection = normalize(viewdirection + wslpos);

	vec3 suncolor = texelFetch(gaux1, ivec2(0, 17), 0).rgb;
	vec3 mooncolor = texelFetch(gaux1, ivec2(1, 17), 0).rgb;
	vec3 zenithcolor = texelFetch(gaux1, ivec2(2, 17), 0).rgb;

	vec3 reflcolor = texture2D(gaux1, (touv(reflectedv) * vec2(256.0, 128.0) + vec2(18.0, 0)) / vec2(viewWidth, viewHeight)).rgb;

	vec4 clouds2d = texture2D(colortex4, (touv(reflectedv) * vec2(512.0, 256.0) + vec2(0.0, 129.0)) / vec2(viewWidth, viewHeight));
	reflcolor = reflcolor * clouds2d.a + clouds2d.rgb;
	reflcolor = reflcolor * (uv1.y * uv1.y);
	suncolor *= shadowlum;
	mooncolor *= shadowlum;
	addskystuf(reflcolor, reflectedv, wsunpos, suncolor, mooncolor, frameTimeCounter);

	reflectedv = reflect(normalize(viewpos), normalmap);
	vec3 rtposhit = vec3(0.0);
	vec2 screenpos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	bool raytracehit = raytrace(viewpos, reflectedv, screenpos, rtposhit);
	if(raytracehit) reflcolor = texture2D(gaux2, rtposhit.xy).rgb;

	float vdoth = saturate(dot(viewdirection, halfdirection));
	float ndoth = saturate(dot(wnormal, halfdirection));
	float ndotv = saturate(dot(wnormal, viewdirection));
	float ndotl = saturate(dot(wnormal, wslpos));

	float lroughness = material.x * material.x;
	float envspeccol = environmentbrdf(material.y, lroughness, ndotv);
	reflcolor = envspeccol * reflcolor;

	float fresnel = fresnelschlick(material.y, vdoth);
	float ldistribution = distributionggx(material.x, ndoth);
	float lvisible = visibleggx(material.x, ndotv, ndotl);
	float splightvis = fresnel * (ldistribution * lvisible * tau * lightvis * ndotl);
	reflcolor += (suncolor + mooncolor) * splightvis;

	if(normal.a > 0.0 && normal.a < 0.2) albedo = vec4(0.0, 0.0, 0.0, 0.5);
	albedo.rgb += reflcolor;
	albedo.a = mix(albedo.a, 1.0, envspeccol + splightvis);
}
#endif

void calcforwardlight(inout vec3 albedo, out vec3 shadowlight, vec3 normalmap){
	vec3 shadowpos = shposwbias(worldpos, lightvis);
	#ifdef EnablePCSS
	float blurthick = calcsdepth(shadowpos);
	blurthick = max(pcssminbrad / shadowMapResolution, blurthick);
	#else
	float blurthick = pcfbradius / shadowMapResolution;
	#endif

	float shadowmap0 = shadowpcf(shadowtex0, shadowpos, blurthick);
	float shadowmap1 = shadowpcf(shadowtex1, shadowpos, blurthick);
	#ifdef coloredShadowMap
	vec4 shadowmapc = texture2D(shadowcolor0, shadowpos.xy);
	#endif

	shadowlight = vec3(1.0);
	if(length(worldpos) < shadowDistance){
	#ifdef coloredShadowMap
		shadowlight = mix(shadowlight, shadowmapc.rgb, pow(shadowmapc.a, 0.5)) * (shadowmap1 - shadowmap0) + shadowmap0;
	#else
		shadowlight = vec3(shadowmap1 + shadowmap0) * 0.5;
	#endif
	}

	#if !defined gbtextured
	shadowlight *= saturate(dot(nlightpos, normalmap));
	#ifdef EnableSSS
	float sssthickness = 0.0;
	if(normal.a > 0.1 && normal.a < 0.3) sssthickness = 0.005;
	shadowlight = subsurfaces(shadowlight, worldpos, wslpos, sssthickness);
	#endif
	#endif

	vec3 totallightcolor = texelFetch(gaux1, ivec2(3, 17), 0).rgb;
	vec3 amblightmap = texture2D(gaux1, (uv1 * vec2(16.0)) / vec2(viewWidth, viewHeight)).rgb;
	amblightmap += (totallightcolor * shadowlight);
	albedo *= amblightmap;
}

void extractmaterial(out vec4 albedo, out vec3 oalbedo, out vec3 normalmap, out float f0, out float roughness, out float emission){
	albedo = texture2D(texture, uv0) * vcolor;
	albedo.rgb = pow(albedo.rgb, vec3(2.2));
	oalbedo = albedo.rgb;

	normalmap = texture2D(normals, uv0).rgb * 2.0 - 1.0;
	normalmap.xy *= normaltstrength;
	normalmap = normalize(normalmap * tbn);

	vec4 speculartex = texture2D(specular, uv0);
	roughness = 1.0, f0 = 1.0, emission = 0.0;

	#if pbrformat == 1
	f0 = saturate(speculartex.g);
	emission = (speculartex.a * 255.0) < 254.5 ? saturate(speculartex.a) : 0.0;
	roughness = saturate(1.0 - speculartex.r);
	#elif pbrformat == 0

	f0 = saturate(speculartex.g);
	emission = saturate(speculartex.b);
	roughness = saturate(1.0 - speculartex.r);
	#endif
	if(normal.a > 0.0 && normal.a < 0.2){ roughness = 0.005; f0 = 0.1; }
}

void main(){
	vec4 albedo = vec4(0.0);
	vec3 normalmap = vec3(0.0);
	vec3 shadowlight = vec3(0.0);
	vec3 oalbedo = vec3(0.0);
	float f0 = 0.0;
	float emission = 0.0;
	float roughness = 0.0;

	extractmaterial(albedo, oalbedo, normalmap, f0, roughness, emission);
	#if defined gbwater
	calcwaternormal(normalmap);
	#endif
	calcforwardlight(albedo.rgb, shadowlight, normalmap);
	#if defined gbwater
	calcforwardrr(albedo, normalmap, vec2(roughness, f0), luminance(shadowlight));
	#endif

	/* DRAWBUFFERS:0123 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(packnm(normalmap), uv1.y, luminance(shadowlight));
	gl_FragData[2] = vec4(oalbedo, normal.a);
	gl_FragData[3] = vec4(f0, roughness, 0.0, 0.0);
}
#endif
