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

uniform vec2 resolution;

layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
layout(location = 2) out vec4 gVelocity;
// layout(location = 2) out vec4 gRoughness;
// layout(location = 3) out vec4 gMetalness;

varying vec3 vNormal;
varying vec4 vPreviousClipSpacePosition;
varying vec4 vClipSpacePosition;


void main() {

	vec3 n = normalize(vNormal);

	vec3 previousClipSpacePosition = vPreviousClipSpacePosition.xyz / vPreviousClipSpacePosition.w;
	vec3 clipSpacePosition = vClipSpacePosition.xyz / vClipSpacePosition.w;

	gVelocity = vec4( (144.0 / 60.0) *  5.5 * resolution * (0.5 * (clipSpacePosition - previousClipSpacePosition).xy), 0.5 * (clipSpacePosition - previousClipSpacePosition).xy); //2.0 * 5.5

}