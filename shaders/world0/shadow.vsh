#version 130

attribute vec3 mc_Entity;

out vec2 uv0;

#include "/constant.glsl"
#include "/common.glsl"

void main(){
	vec4 pos = gl_ModelViewProjectionMatrix * gl_Vertex;
	pos.xy /= sdistort(pos.xy, shadowDistortFactor);
	pos.z *= 0.25;
	gl_Position = pos;

	uv0 = gl_MultiTexCoord0.xy;
}
