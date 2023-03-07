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

precision highp float;
precision highp sampler2D;
precision highp usampler2D;

uniform vec3 color;
uniform float roughness;
uniform float metalness;
uniform vec3 emissiveColor;
uniform float emissiveStrength;

uniform float targetFPS;
uniform float FPS;
uniform float bloomVelocityMultiplier;

uniform vec2 resolution;

layout(location = 0) out vec4 gAlbedoRoughness;
layout(location = 1) out vec4 gNormalMetalness;
layout(location = 2) out vec4 gVelocity;
layout(location = 3) out vec4 gEmission;


varying vec3 vNormal;
varying vec4 vPreviousClipSpacePosition;
varying vec4 vClipSpacePosition;


void main() {

	vec3 n = normalize(vNormal);

	vec3 previousClipSpacePosition = vPreviousClipSpacePosition.xyz / vPreviousClipSpacePosition.w;
	vec3 clipSpacePosition = vClipSpacePosition.xyz / vClipSpacePosition.w;

	gAlbedoRoughness = vec4(color, 1.0 + roughness);
	gNormalMetalness = vec4(n, metalness);
	gVelocity = vec4( (FPS / targetFPS) *  bloomVelocityMultiplier * resolution * (0.5 * (clipSpacePosition - previousClipSpacePosition).xy), 0.5 * (clipSpacePosition - previousClipSpacePosition).xy); //2.0 * 5.5
	gEmission = vec4(emissiveColor, emissiveStrength);

}