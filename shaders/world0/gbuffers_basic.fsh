#version 130
in vec3 vcolor;
/* DRAWBUFFERS: 0 */
void main(){
	gl_FragData[0] = vec4(vcolor, 1.0);
}
