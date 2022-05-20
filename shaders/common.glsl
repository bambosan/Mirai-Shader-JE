
const float pi = 3.14159265;
const float hpi = 1.57079633;
const float invpi = 0.31830989;
const float tau = 6.28318531;
const float invtau = 0.15915494;
const float wior = 0.750018750469;

#define saturate(x) clamp(x, 0.0, 1.0)
#define max0(x) max(x, 0.0)
#define rotate2d(rot) mat2(cos(rot), sin(rot), -sin(rot), cos(rot))

float luminance(vec3 col){
	return dot(col, vec3(0.2125, 0.7154, 0.0721));
}

float sdistort(vec2 sp, float dfact){
	return mix(1.0, length(sp), dfact);
}

float hash12(vec2 p){
	return fract(43757.5453 * sin(dot(p, vec2(12.9898, 78.233))));
}

float hash13(vec3 p){
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec2 hash22(vec2 p){
	return fract(sin(vec2(dot(p, vec2(123.4, 748.6)), dot(p, vec2(547.3, 659.3))))*5232.85324);
}

vec2 packnm(vec3 n){
	return (n.xy * inversesqrt(n.z * 8.0 + 8.0) + 0.5);
}

vec3 unpacknm(vec2 pn){
	pn = pn * 4.0 - 2.0;
	float fn = dot(pn, pn);
	return vec3(pn * sqrt(1.0 - fn / 4.0), 1.0 - fn / 2.0);
}

vec2 touv(vec3 n){
	return vec2(atan(-n.x, n.z) * invtau + 0.5, acos(n.y) * invpi);
}

vec3 tosp(vec2 uv){
	uv *= vec2(tau, pi);
	return vec3(sin(uv.x) * sin(uv.y), cos(uv.y), -cos(uv.x) * sin(uv.y));
}

vec2 rsi(vec3 o, vec3 dir, float rad){
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, o);
	float c = dot(o, o) - (rad * rad);
	float d = (b * b) - 4.0 * a * c;
	if(d < 0.0) return vec2(1.0, -1.0);
	d = sqrt(d);
	return vec2((-b - d) / (2.0 * a), (-b + d) / (2.0 * a));
}

// https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
float rsi1(vec3 ro, vec3 rd, float rad){
	float b = dot(ro, rd);
	float c = dot(ro, ro) - rad * rad;
	if(c > 0.0 && b > 0.0) return -1.0;
	float discr = b * b - c;
	if(discr < 0.0) return -1.0;
	if(discr > b * b) return (-b + sqrt(discr));
	return -b - sqrt(discr);
}

vec2 poisson[64] = vec2[64](
	vec2(-0.04117257, -0.1597612),
	vec2(0.06731031, -0.4353096),
	vec2(-0.206701, -0.4089882),
	vec2(0.1857469, -0.2327659),
	vec2(-0.2757695, -0.159873),
	vec2(-0.2301117, 0.1232693),
	vec2(0.05028719, 0.1034883),
	vec2(0.236303, 0.03379251),
	vec2(0.1467563, 0.364028),
	vec2(0.516759, 0.2052845),
	vec2(0.2962668, 0.2430771),
	vec2(0.3650614, -0.1689287),
	vec2(0.5764466, -0.07092822),
	vec2(-0.5563748, -0.4662297),
	vec2(-0.3765517, -0.5552908),
	vec2(-0.4642121, -0.157941),
	vec2(-0.2322291, -0.7013807),
	vec2(-0.05415121, -0.6379291),
	vec2(-0.7140947, -0.6341782),
	vec2(-0.4819134, -0.7250231),
	vec2(-0.7627537, -0.3445934),
	vec2(-0.7032605, -0.13733),
	vec2(0.8593938, 0.3171682),
	vec2(0.5223953, 0.5575764),
	vec2(0.7710021, 0.1543127),
	vec2(0.6919019, 0.4536686),
	vec2(0.3192437, 0.4512939),
	vec2(0.1861187, 0.595188),
	vec2(0.6516209, -0.3997115),
	vec2(0.8065675, -0.1330092),
	vec2(0.3163648, 0.7357415),
	vec2(0.5485036, 0.8288581),
	vec2(-0.2023022, -0.9551743),
	vec2(0.165668, -0.6428169),
	vec2(0.2866438, -0.5012833),
	vec2(-0.5582264, 0.2904861),
	vec2(-0.2522391, 0.401359),
	vec2(-0.428396, 0.1072979),
	vec2(-0.06261792, 0.3012581),
	vec2(0.08908027, -0.8632499),
	vec2(0.9636437, 0.05915006),
	vec2(0.8639213, -0.309005),
	vec2(-0.03422072, 0.6843638),
	vec2(-0.3734946, -0.8823979),
	vec2(-0.3939881, 0.6955767),
	vec2(-0.4499089, 0.4563405),
	vec2(0.07500362, 0.9114207),
	vec2(-0.9658601, -0.1423837),
	vec2(-0.7199838, 0.4981934),
	vec2(-0.8982374, 0.2422346),
	vec2(-0.8048639, 0.01885651),
	vec2(-0.8975322, 0.4377489),
	vec2(-0.7135055, 0.1895568),
	vec2(0.4507209, -0.3764598),
	vec2(-0.395958, -0.3309633),
	vec2(-0.6084799, 0.02532744),
	vec2(-0.2037191, 0.5817568),
	vec2(0.4493394, -0.6441184),
	vec2(0.3147424, -0.7852007),
	vec2(-0.5738106, 0.6372389),
	vec2(0.5161195, -0.8321754),
	vec2(0.6553722, -0.6201068),
	vec2(-0.2554315, 0.8326268),
	vec2(-0.5080366, 0.8539945)
);

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

#if defined atmstuff
/*
float rayleighphase(float costheta){
	return (3.0 * (1.0 + costheta * costheta)) / (16.0 * pi);
}

float miephase(float costheta, float g){
	float gg = g * g;
	return (1.0 - gg) / (4.0 * pi * pow(1.0 + gg - 2.0 * g * costheta, 1.5));
}
*/
float rayleighphase(float cosTheta) {
	vec2 cmad = vec2(0.1, 0.28) * invpi;
	return cosTheta * cmad.x + cmad.y;
}

float miephase(float cosTheta, float g){
	float gg = g * g;
	return (gg * -0.25 + 0.25) * invpi * pow(-2.0 * (g * cosTheta) + (gg + 1.0), -1.5);
}
#endif
#if defined atmosphere
const float atmrad = pradius + atmosheight;
const mat3 exti = mat3(rayleighcoeff, miecoeff, ozonecoeff);

vec3 atmdensity(vec3 pos){
	float height = max0(length(pos) - pradius);
	float rayleigh = exp(-(height / rayleighheight));
	float mie = exp(-(height / mieheight));
 	float ozone = 1.0 / cosh((ozonepeaklevel - height) / ozonefalloff);
	return vec3(rayleigh, mie, ozone * rayleigh);
}

vec3 codlight(vec3 rayorigin, vec3 lightpos){
	float stepspacel = rsi(rayorigin, lightpos, atmrad).y / float(lightsample);
	vec3 raydirl = lightpos * stepspacel;
	vec3 rayoril = rayorigin + raydirl * atmsampoffset;

	vec3 odlight = vec3(0.0);
	for(int j = 0; j < lightsample; j++, rayoril += raydirl) odlight += atmdensity(rayoril);
	return exp(-(exti * odlight * stepspacel));
}

vec3 catmosphere(vec3 position, vec3 nworldpos, vec3 lightpos, vec3 zenithcolor){
	vec2 groundint = rsi(position, nworldpos, pradius - 1000.0);
	vec2 atmosint = rsi(position, nworldpos, atmrad);

	float startsamp = groundint.x > 0.0 && groundint.y > 0.0 ? groundint.x : atmosint.y;
	float endsamp = max0(atmosint.x);
	float stepspace = (startsamp - endsamp) / float(viewsample);

	vec3 raydirect = nworldpos * stepspace;
	vec3 rayorigin = position + nworldpos * endsamp;
	rayorigin += raydirect * atmsampoffset;

	vec3 transmittance = vec3(1.0);
	vec3 raylday = vec3(0.0);
	vec3 mieday = vec3(0.0);
	vec3 raylnight = vec3(0.0);
	vec3 mienight = vec3(0.0);
	vec3 raylamb = vec3(0.0);
	vec3 mieamb = vec3(0.0);

	vec2 costheta = vec2(dot(nworldpos, lightpos), dot(nworldpos, -lightpos));

	for(int i = 0; i < viewsample; i++, rayorigin += raydirect){
		vec3 particledens = atmdensity(rayorigin) * stepspace;
		vec3 totalscatter = exti * particledens;
		vec3 scattertransm = exp(-totalscatter);

		vec3 odview = transmittance * saturate((scattertransm - 1.0) / -totalscatter);
		vec3 odlightsun = codlight(rayorigin, lightpos);
		vec3 odlightmoon = codlight(rayorigin, -lightpos);

		raylday += rayleighcoeff * (rayleighphase(costheta.x) * particledens.x) * odview * odlightsun;
		mieday += miecoeff * (miephase(costheta.x, mieanisotropy) * particledens.y) * odview * odlightsun;

		raylnight += rayleighcoeff * (rayleighphase(costheta.y) * particledens.x) * odview * odlightmoon;
		mienight += miecoeff * (miephase(costheta.y, mieanisotropy) * particledens.y) * odview * odlightmoon;

		raylamb += rayleighcoeff * particledens.x * odview;
		mieamb += miecoeff * particledens.y * odview;
		transmittance *= scattertransm;
	}

	float moonillum = mix(0.0, moonilluminance * 0.5, smoothstep(0.2, -1.0, lightpos.y));
	vec3 dayatm = (raylday + mieday) * sunilluminance;
	vec3 nightatm = (raylnight + mienight) * moonillum;
	vec3 ambatm = (raylamb + mieamb) * zenithcolor;
	return (dayatm + nightatm + ambatm);
}

vec3 calcsky(vec3 nworldpos, vec3 lightpos, vec3 zenithcolor, float paltitude){
	vec3 position = vec3(0.0, pradius + paltitude + 500.0, 0.0);
	vec3 color = catmosphere(position, nworldpos, lightpos, zenithcolor);
	return color;
}
#endif
#if defined cloud2d
float cclouddens(vec3 position, float density, float hardness){
	vec2 movepos = (position.xz / position.y) * cloud2dheight * 0.05;
	movepos += (frameTimeCounter * cloud2dmovespeed * 0.001);
	density = 2.0 - density;
	float value = 0.0;

	for(int i = 0; i < cloud2doctave; i++){
		value += texture2D(noisetex, movepos).b * density;
		movepos *= 2.0; density *= 0.5;
		movepos += value * 0.02;
	}
	return saturate(1.0 - pow(hardness, 1.0 - value));
}

float phasemie2(float costheta){
	float mie1 = miephase(costheta, 0.8), mie2 = miephase(costheta, -0.1);
	return mix(mie1 * 0.5, mie2, 0.5);
}

vec4 ccloud2d(vec3 nworldpos, vec3 lightpos, vec3 suncolor, vec3 mooncolor, vec3 zenithcolor){
	float clouddens = cclouddens(nworldpos, cloud2ddensity, 0.4);
	float cloudod = exp(-clouddens);
	cloudod = (1.0 - cloudod) * cloudod;
	float phaselight = phasemie2(dot(nworldpos, lightpos));

	float stepspace = 1.0 / cloud2dlightstep;
	float clabsorb = 0.0;
	for(int i = 0; i < cloud2dlightstep; i++){
		clabsorb += (cclouddens(nworldpos, cloud2ddensity - 0.2, 0.2) * stepspace);
		nworldpos += (lightpos * stepspace * 0.1);
	}
	clabsorb = exp(-(clabsorb * clouddens * 30.0));

	float cdireclight = cloudod * clabsorb * phaselight;
	vec4 result = vec4((suncolor * 30.0 + mooncolor) * cdireclight + (zenithcolor * 5.0 * cloudod), clabsorb);
	return mix(result, vec4(0.0, 0.0, 0.0, 1.0), smoothstep(0.5, 0.0, nworldpos.y));
}
#endif
#if defined skystuff
// https://www.shadertoy.com/view/slSXRW
float drawsun(vec3 worldpos, vec3 sunpos){
	const float sunsize = cos(radians(1.2));
	float costheta = dot(worldpos, sunpos);
	if(costheta >= sunsize) return 1.0;

	float offset = sunsize - costheta;
	float glowlarge = exp(-offset * 5e4) * 0.5;
	float glowmbright = 1.0 / (0.02 + offset * 300.0) * 0.01;

	return (glowlarge + glowmbright);
}

float drawmoon(vec3 worldpos, vec3 moonpos){
	float size = 0.003;
	float moonpangle = radians(80.0);
	vec3 moondir = vec3(sin(moonpangle), 0.0, -cos(moonpangle));

	vec3 moonnormal = cross(worldpos, moonpos);
	float sq = size - moonnormal.x * moonnormal.x - moonnormal.y * moonnormal.y - moonnormal.z * moonnormal.z;
	moonnormal = normalize(vec3(moonnormal.xy, sqrt(sq)));
	return saturate(dot(moondir, moonnormal));
}

float simplestars(vec3 worldpos, vec3 suncolor, float timef){
	vec3 movepos = worldpos * 200.0;
	movepos.zy *= rotate2d(radians(-20.0));
	movepos.xy *= rotate2d(timef * 0.008);

	float startd = smoothstep(0.995, 1.0, hash13(floor(movepos))) * saturate(1.0 - luminance(suncolor));
	float zenith = saturate(1.0 - exp(-worldpos.y * 10.0));
	return (startd * zenith);
}

void addskystuf(inout vec3 sky, vec3 worldpos, vec3 wsunpos, vec3 suncolor, vec3 mooncolor, float timef){
	float sun = drawsun(worldpos, wsunpos);
	sky += (suncolor * sun);

	float moon = drawmoon(worldpos, -wsunpos);
	sky += (mooncolor * moon);

	float stars = simplestars(worldpos, suncolor, timef);
	sky += (stars * 0.1);
}
#endif
#if defined refutil
float visibleggx(float roughness, float ndotv, float ndotl){
	float r2 = roughness * roughness;
	float gv = ndotl * sqrt(ndotv * (ndotv - ndotv * r2) + r2);
	float gl = ndotv * sqrt(ndotl * (ndotl - ndotl * r2) + r2);
	return 0.5 / max(gv + gl, 0.00001);
}

float distributionggx(float roughness, float ndoth){
	float r2 = roughness * roughness;
	float d = (ndoth * r2 - ndoth) * ndoth + 1.0;
	return r2 / (d * d * pi);
}

float fresnelschlick(float reflectance, float vdoth){
	float fresnel = reflectance + (1.0 - reflectance) * pow((1.0 - vdoth), 5.0);
	return fresnel;
}

vec3 fresnelschlick(vec3 reflectance, float vdoth){
	vec3 fresnel = reflectance + (1.0 - reflectance) * pow((1.0 - vdoth), 5.0);
	return fresnel;
}

// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
float environmentbrdf(float reflectance, float roughness, float ndotv){
	const vec4 c0 = vec4(-1, -0.0275, -0.572, 0.022);
	const vec4 c1 = vec4(1, 0.0425, 1.04, -0.04);

	vec4 r = roughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * ndotv)) * r.x + r.y;
	vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;
	return reflectance * AB.x + AB.y;
}

vec3 environmentbrdf(vec3 reflectance, float roughness, float ndotv){
	const vec4 c0 = vec4(-1, -0.0275, -0.572, 0.022);
	const vec4 c1 = vec4(1, 0.0425, 1.04, -0.04);

	vec4 r = roughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * ndotv)) * r.x + r.y;
	vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;
	return reflectance * AB.x + AB.y;
}
#endif
