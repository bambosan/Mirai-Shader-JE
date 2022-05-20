#version 130
/******************************************
const int colortex0Format = RGB16;
const int colortex1Format = RGBA8;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16;
const int colortex5Format = RGB16;

const bool colortex0Clear = true;
const bool colortex1Clear = true;
const bool colortex2Clear = true;
const bool colortex3Clear = true;
const bool colortex4Clear = false;
const bool colortex5Clear = true;
const int noiseTextureResolution = 256;
******************************************/
#define fshader
#include "/composite.glsl"
