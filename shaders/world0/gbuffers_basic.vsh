#version 130
out vec3 vcolor;
void main(){
	vcolor = gl_Color.rgb;
	gl_Position = ftransform();
}
