#define varying in
#define texture texture

#define texture texture
#define textureCube texture
#define textureProj textureProj
#define textureLodEXT textureLod
#define textureProjLodEXT textureProjLod
#define textureCubeLodEXT textureLod
#define textureGradEXT textureGrad
#define textureProjGradEXT textureProjGrad
#define textureCubeGradEXT textureGrad

#define ORIGINAL 0
#define PHYSICAL 1
#define BLACK 2

precision highp float;
precision highp sampler2D;
precision highp usampler2D;

uniform float globalScale;

uniform float baseHue;
uniform float baseSaturation;
uniform float baseValue;

uniform float baseHue2;
uniform float baseSaturation2;
uniform float baseValue2;

uniform float baseHue3;
uniform float baseSaturation3;
uniform float baseValue3;

uniform float baseHue4;
uniform float baseSaturation4;
uniform float baseValue4;

uniform float effectHue;
uniform float effectSaturation;
uniform float effectValue;

uniform vec3 baseColor;
uniform vec3 baseColor2;
uniform vec3 baseColor3;
uniform vec3 baseColor4;
uniform vec3 effectColor;

uniform float targetFPS;
uniform float FPS;
uniform float bloomVelocityMultiplier;

uniform vec2 resolution;

layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
layout(location = 2) out vec4 gVelocity;
// layout(location = 2) out vec4 gRoughness;
// layout(location = 3) out vec4 gMetalness;

varying vec3 vNormal;
varying float fDifference;
varying vec4 vPreviousClipSpacePosition;
varying vec4 vClipSpacePosition;
flat varying int vInd;


void main() {

	vec3 n = normalize(vNormal);

	float fix = 30.0 * globalScale; //50
	float f = sqrt(step(1.0, fDifference) * min(fDifference, fix)/fix);

	vec3 previousClipSpacePosition = vPreviousClipSpacePosition.xyz / vPreviousClipSpacePosition.w;
	vec3 clipSpacePosition = vClipSpacePosition.xyz / vClipSpacePosition.w;

	//gVelocity = vec4(24.0 * normalize((clipSpacePosition - previousClipSpacePosition).xy), 0.0, 1.0);
	//gVelocity = vec4((clipSpacePosition - previousClipSpacePosition).xy, 0.0, 1.0);
	//gVelocity = vec4(0.5 * normalize((clipSpacePosition - previousClipSpacePosition).xy) + vec2(0.5), 0.0, 1.0);
	//gVelocity = vec4(0.5 * (clipSpacePosition - previousClipSpacePosition).xy + vec2(0.5), 0.0, 1.0);
	gVelocity = vec4( (144.0 / 60.0) *  5.5 * resolution * (0.5 * (clipSpacePosition - previousClipSpacePosition).xy), 0.5 * (clipSpacePosition - previousClipSpacePosition).xy); //2.0 * 5.5

#if LIGHTING == ORIGINAL

	// Somehow this type of initialization doesnt work on samsung android
	// colors[4] = float[4](baseHue, baseHue2, baseHue3, baseHue4);
	// float sats[4] = float[4](baseSaturation, baseSaturation2, baseSaturation3, baseSaturation4);
	// float values[4] = float[4](baseValue, baseValue2, baseValue3, baseValue4);
	float colors[4];
	float sats[4];
	float values[4];
	
	colors[0] = baseHue;
	colors[1] = baseHue2;
	colors[2] = baseHue3;
	colors[3] = baseHue4;

	sats[0] = baseSaturation;
	sats[1] = baseSaturation2;
	sats[2] = baseSaturation3;
	sats[3] = baseSaturation4;

	values[0] = baseValue;
	values[1] = baseValue2;
	values[2] = baseValue3;
	values[3] = baseValue4;


#if ONECOLOR == 0
	float c = (1.0 - f) * (colors[int(mod(float(vInd), 4.0))]) + effectHue * f;
	float d = (1.0 - f) * (sats[int(mod(float(vInd), 4.0))]) + effectSaturation * f;
	float e = (1.0 - f) * (values[int(mod(float(vInd), 4.0))]) + effectValue * f;
#elif ONECOLOR == 1
	float c = (1.0 - f) * baseHue + effectHue * f;
	float d = (1.0 - f) * baseSaturation + effectSaturation * f;
	float e = (1.0 - f) * baseValue + effectValue * f;
#endif

    gColor = vec4(vec3(c), 1.0);
    gNormal = vec4(n, 1.0);

#elif LIGHTING == PHYSICAL

	// Somehow this type of initialization doesnt work on samsung android
	//const vec3 colors[4] = vec3[4](baseColor, baseColor2, baseColor3, baseColor4);
	vec3 colors[4];
	colors[0] = baseColor;
	colors[1] = baseColor2;
	colors[2] = baseColor3;
	colors[3] = baseColor4;

#if ONECOLOR == 0
	vec3 albedo = (1.0 - f) * (colors[int(mod(float(vInd), 4.0))]) + effectColor * f;
#elif ONECOLOR == 1
	vec3 albedo = (1.0 - f) * baseColor + effectColor * f;
#endif

    gColor = vec4(albedo, 1.0);
    gNormal = vec4(n, 1.0);

#else
	gColor = vec4(vec3(0.0), 1.0);
    gNormal = vec4(n, 1.0);
#endif
}