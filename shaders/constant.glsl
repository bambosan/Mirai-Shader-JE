#define pradius 6731e3
#define atmosheight 100e3
#define rayleighheight 8e3
#define mieheight 1.2e3
#define ozonepeaklevel 30e3
#define ozonefalloff 3e3
#define rayleighcoeff vec3(5.8e-6, 1.35e-5, 3.31e-5)
#define miecoeff vec3(10e-6)
#define ozonecoeff vec3(3.426, 8.298, 0.356) * 0.06 * 10e-5
#define mieanisotropy 0.75
#define viewsample 8
#define lightsample 3
#define atmsampoffset 0.4
#define sunilluminance 2.5
#define moonilluminance 1.0

#define cloud2dheight 0.4
#define cloud2ddensity 1.0 //[1.0 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1]
#define cloud2doctave 6
#define cloud2dlightstep 4
#define cloud2dmovespeed 0.5

#define coloredShadowMap
//#define EnablePCSS
#define EnableSSS
const float shadowDistance = 100.0; //[100.0 150.0 200.0 250.0 300.0 350.0 400.0 450.0 500.0 550.0 600.0 650.0 700.0]
const int shadowMapResolution = 512; //[512 1024 2048 4096 8192 16384]
#define shadowDistortFactor 0.85 //[0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95]
#define BlockerSample 10 //[5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30]
#define PCFSample 8 //[8 16 32 64]
#define pcfbradius 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define pcssminbrad 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define pcssmaxbrad 16.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0]
#define ShadowSaturation 0.5 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define normaltstrength 1.0
#define sssquality 8 //[8 16 32 64]
#define pbrformat 1

#define raysstep 30 //[10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150]
#define refinestep 5 //[5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
#define wwscale 0.6 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define wwspeed 0.3 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define wnormalstrength 2.5 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define wnormaloffset 0.2 //[0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define watertex
#define wtransparency 0.3 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 1.0]
#define wbrightness 0.6 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 1.0]
#define waterdensity 0.3 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define wreflectance 0.05 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.012 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2]
