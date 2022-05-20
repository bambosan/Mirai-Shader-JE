#version 130

uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D gcolor;
uniform sampler2D gaux2;

in vec2 uv0;

#define colorSaturation 1.0
#include "/common.glsl"

// Lottes 2016, "Advanced Techniques and Optimization of HDR Color Pipelines"
vec3 lottes(vec3 color){
	const vec3 a = vec3(1.6);
	const vec3 d = vec3(0.977);
	const vec3 hdrMax = vec3(8.0);
	const vec3 midIn = vec3(0.18);
	const vec3 midOut = vec3(0.267);
	const vec3 b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) / ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
	const vec3 c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) / ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
	return pow(color, a) / (pow(color, a * d) * b + c);
}

void main(){
	vec3 color	= texture2D(gcolor, uv0).rgb;

	color = lottes(color * 1.5);
	color = mix(vec3(luminance(color)), color, colorSaturation);
	color = pow(color, vec3(1.0 / 2.2));

	gl_FragData[0] = vec4(color, 1.0);
}
