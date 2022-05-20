#if defined vshader

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float eyeAltitude;

#define atmstuff
#define atmosphere
#include "/constant.glsl"
#include "/common.glsl"

out vec3 wsunpos;
out vec3 position;
out vec3 suncolor;
out vec3 mooncolor;
out vec3 zenithcolor;
out float sunvisibility;
out float moonvisibility;
out float expsunvis;
out float expmoonvis;

void main(){
	gl_Position = ftransform();
	wsunpos = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	position = vec3(0.0, pradius + eyeAltitude + 500.0, 0.0);
	suncolor = codlight(position, wsunpos) * sunilluminance * 0.4;
	suncolor = mix(vec3(luminance(suncolor)), suncolor, 1.5);
	mooncolor = codlight(position, -wsunpos) * moonilluminance * 0.4;
	zenithcolor = catmosphere(position, vec3(0.0, 1.0, 0.0), wsunpos, vec3(0.0)) * 2.0;
	sunvisibility = saturate(dot(normalize(sunPosition), normalize(upPosition)));
	moonvisibility = saturate(dot(normalize(-sunPosition), normalize(upPosition)));
	expsunvis = saturate(1.0 - exp(-sunvisibility * 10.0));
	expmoonvis = saturate(1.0 - exp(-moonvisibility * 10.0));
}
#elif defined fshader

uniform float eyeAltitude;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform sampler2D noisetex;

#define atmstuff
#define atmosphere
#define cloud2d
#include "/constant.glsl"
#include "/common.glsl"

in vec3 wsunpos;
in vec3 position;
in vec3 suncolor;
in vec3 mooncolor;
in vec3 zenithcolor;
in float sunvisibility;
in float moonvisibility;
in float expsunvis;
in float expmoonvis;

void main(){
	/* DRAWBUFFERS:4 */
	gl_FragData[0] = vec4(0.1,0.0,0.1,1.0);

	if(gl_FragCoord.x < 17.0 && gl_FragCoord.y < 17.0){
		vec2 texcoord16x16 = gl_FragCoord.xy / vec2(16.0);
		float skylmcoord = saturate(pow(texcoord16x16.y, 3.0) + texcoord16x16.y * 0.1);
		float blocklmcoord = saturate(pow(texcoord16x16.x, 5.0) + texcoord16x16.x * 0.2) * (1.0 - saturate(expsunvis * texcoord16x16.y * (1.0 - rainStrength)));
		vec3 ambcolor = mix(vec3(luminance(zenithcolor)), zenithcolor, ShadowSaturation);
		ambcolor = mix(vec3(0.01), ambcolor * 2.0, max(expsunvis, expmoonvis));
		gl_FragData[0].rgb = (ambcolor * skylmcoord) + (vec3(1.0, 0.55, 0.2) * blocklmcoord);
	}

	if(gl_FragCoord.x > 17.0 && gl_FragCoord.x < 275.0 && gl_FragCoord.y < 129.0){
		vec2 texcoord256x256 = (gl_FragCoord.xy - vec2(18.0, 0)) / vec2(256.0, 128.0);
		vec3 worldpos = tosp(texcoord256x256);
		gl_FragData[0].rgb = calcsky(worldpos, wsunpos, zenithcolor, eyeAltitude);
	}

	if(gl_FragCoord.x < 513.0 && gl_FragCoord.y > 128.0 && gl_FragCoord.y < 386.0){
		vec2 texcoord512x256 = (gl_FragCoord.xy - vec2(0.0, 129.0)) / vec2(512.0, 256.0);
		vec3 worldpos = tosp(texcoord512x256);
		vec4 clouds2d = ccloud2d(worldpos, wsunpos, suncolor, mooncolor, zenithcolor);
		gl_FragData[0] = clouds2d;
	}

	if(gl_FragCoord.x < 1.0 && gl_FragCoord.y > 17.0 && gl_FragCoord.y < 18.0) gl_FragData[0].rgb = suncolor;

	if(gl_FragCoord.x > 1.0 && gl_FragCoord.x < 2.0 && gl_FragCoord.y > 17.0 && gl_FragCoord.y < 18.0) gl_FragData[0].rgb = vec3(length(mooncolor));

	if(gl_FragCoord.x > 2.0 && gl_FragCoord.x < 3.0 && gl_FragCoord.y > 17.0 && gl_FragCoord.y < 18.0) gl_FragData[0].rgb = zenithcolor;

	if(gl_FragCoord.x > 3.0 && gl_FragCoord.x < 4.0 && gl_FragCoord.y > 17.0 && gl_FragCoord.y < 18.0) gl_FragData[0].rgb = suncolor * expsunvis + (vec3(length(mooncolor)) * expmoonvis * 0.02);
}
#endif
