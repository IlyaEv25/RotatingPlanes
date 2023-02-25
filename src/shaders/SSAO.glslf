uniform sampler2D u_normal;
uniform sampler2D u_depth;
uniform sampler2D u_noise;

uniform vec3 kernel[ KERNEL_SIZE ];

uniform vec2 resolution;

uniform float cameraNear;
uniform float cameraFar;
uniform mat4 cameraProjectionMatrix;
uniform mat4 cameraInverseProjectionMatrix;

uniform float kernelRadius;
uniform float minDistance; // avoid artifacts caused by neighbour fragments with minimal depth difference
uniform float maxDistance; // avoid the influence of fragments which are too far away

varying vec2 vUv;

#include <packing>

float geu_depth( const in vec2 screenPosition ) {

    return texture2D( u_depth, screenPosition ).x;

}

float getLinearDepth( const in vec2 screenPosition ) {

    #if PERSPECTIVE_CAMERA == 1

        float fragCoordZ = texture2D( u_depth, screenPosition ).x;
        float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );
        return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );

    #else

        return texture2D( u_depth, screenPosition ).x;

    #endif

}

float getViewZ( const in float depth ) {

    #if PERSPECTIVE_CAMERA == 1

        return perspectiveDepthToViewZ( depth, cameraNear, cameraFar );

    #else

        return orthographicDepthToViewZ( depth, cameraNear, cameraFar );

    #endif

}

vec3 getViewPosition( const in vec2 screenPosition, const in float depth, const in float viewZ ) {

    float clipW = cameraProjectionMatrix[2][3] * viewZ + cameraProjectionMatrix[3][3];

    vec4 clipPosition = vec4( ( vec3( screenPosition, depth ) - 0.5 ) * 2.0, 1.0 );

    clipPosition *= clipW; // unprojection.

    return ( cameraInverseProjectionMatrix * clipPosition ).xyz;

}

vec3 getViewNormal( const in vec2 screenPosition ) {

    vec4 normal = vec4(texture2D( u_normal, screenPosition ).xyz, 0.0);
    return (viewMatrix * normal).xyz;//unpackRGBToNormal( texture2D( u_normal, screenPosition ).xyz );

}

void main() {

    float depth = geu_depth( vUv );
    float viewZ = getViewZ( depth );

    vec3 viewPosition = getViewPosition( vUv, depth, viewZ );
    vec3 viewNormal = getViewNormal( vUv );

    vec2 noiseScale = vec2( resolution.x / 4.0, resolution.y / 4.0 );
    vec3 random = vec3( texture2D( u_noise, vUv * noiseScale ).r );

    // compute matrix used to reorient a kernel vector

    vec3 tangent = normalize( random - viewNormal * dot( random, viewNormal ) );
    vec3 bitangent = cross( viewNormal, tangent );
    mat3 kernelMatrix = mat3( tangent, bitangent, viewNormal );

    float occlusion = 0.0;

    for ( int i = 0; i < KERNEL_SIZE; i ++ ) {

        vec3 sampleVector = kernelMatrix * kernel[ i ]; // reorient sample vector in view space
        vec3 samplePoint = viewPosition + ( sampleVector * kernelRadius ); // calculate sample point

        vec4 samplePointNDC = cameraProjectionMatrix * vec4( samplePoint, 1.0 ); // project point and calculate NDC
        samplePointNDC /= samplePointNDC.w;

        vec2 samplePointUv = samplePointNDC.xy * 0.5 + 0.5; // compute uv coordinates

        float realDepth = getLinearDepth( samplePointUv ); // get linear depth from depth texture
        float sampleDepth = viewZToOrthographicDepth( samplePoint.z, cameraNear, cameraFar ); // compute linear depth of the sample view Z value
        float delta = sampleDepth - realDepth;

        if ( delta > minDistance && delta < maxDistance ) { // if fragment is before sample point, increase occlusion

            occlusion += 1.0;

        }

    }

    occlusion = clamp( occlusion / float( KERNEL_SIZE ), 0.0, 1.0 );

    gl_FragColor = vec4( vec3( 1.0 - occlusion ), 1.0 );
}