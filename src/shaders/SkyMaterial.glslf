#version 300 es
#define varying in
layout(location = 0) out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define gl_FragDepthEXT gl_FragDepth
#define texture2D texture
#define textureCube texture
#define texture2DProj textureProj
#define texture2DLodEXT textureLod
#define texture2DProjLodEXT textureProjLod
#define textureCubeLodEXT textureLod
#define texture2DGradEXT textureGrad
#define texture2DProjGradEXT textureProjGrad
#define textureCubeGradEXT textureGrad
precision highp float;
precision highp int;
#define HIGH_PRECISION
#define SHADER_NAME ShaderMaterial
#define USE_ENVMAP
#define ENVMAP_MODE_REFLECTION
#define ENVMAP_TYPE_CUBE_UV
#define ENVMAP_BLENDING_NONE
#define FLIP_SIDED
uniform mat4 viewMatrix;
uniform vec3 cameraPosition;
uniform bool isOrthographic;
#define TONE_MAPPING
#ifndef saturate
    #define saturate( a ) clamp( a, 0.0, 1.0 )
#endif

const float Epsilon = 0.0000001;
#define absEps(x) abs(x)+Epsilon
#define FRESNEL_MAXIMUM_ON_ROUGH 0.25
#define CUBEUV_TEXEL_WIDTH 0.0013020833333333333
#define CUBEUV_TEXEL_HEIGHT 0.0009765625
#define CUBEUV_MAX_MIP 8.0
uniform float roughness;
uniform float toneMappingExposure;
uniform sampler2D brdf;

varying vec3 vNormal;
varying vec3 vWorldPosition;

float pow5(float value) {
    float sq = value*value;
    return sq*sq*value;
}

vec3 getReflectanceFromAnalyticalBRDFLookup_Jones(float VdotN, vec3 reflectance0, vec3 reflectance90, float smoothness) {
    float weight = mix(FRESNEL_MAXIMUM_ON_ROUGH, 1.0, smoothness);
    return reflectance0+weight*(reflectance90-reflectance0)*pow5(saturate(1.0-VdotN));
}

vec3 LinearToneMapping( vec3 color ) {
    return toneMappingExposure * color;
}
vec3 ReinhardToneMapping( vec3 color ) {
    color *= toneMappingExposure;
    return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 OptimizedCineonToneMapping( vec3 color ) {
    color *= toneMappingExposure;
    color = max( vec3( 0.0 ), color - 0.004 );
    return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
    vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
    vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
    return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
    const mat3 ACESInputMat = mat3(
    vec3( 0.59719, 0.07600, 0.02840 ), vec3( 0.35458, 0.90834, 0.13383 ), vec3( 0.04823, 0.01566, 0.83777 )
    );
    const mat3 ACESOutputMat = mat3(
    vec3(  1.60475, -0.10208, -0.00327 ), vec3( -0.53108, 1.10813, -0.07276 ), vec3( -0.07367, -0.00605, 1.07602 )
    );
    color *= toneMappingExposure; // / 0.6;
    color = ACESInputMat * color;
    color = RRTAndODTFit( color );
    color = ACESOutputMat * color;
    return color; //saturate( color );
}

float gamma = 2.2;

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	//color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 RomBinDaHouseToneMapping(vec3 color)
{
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 filmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	//color = pow(color, vec3(1. / gamma));
	return color;
}
vec3 CustomToneMapping( vec3 color ) {
    return color;
}
vec3 toneMapping( vec3 color ) {
    return ACESFilmicToneMapping( color );
}
#define OPAQUE
vec4 LinearToLinear( in vec4 value ) {
    return value;
}
vec4 LinearTosRGB( in vec4 value ) {
    return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}
vec4 linearToOutputTexel( vec4 value ) {
    return LinearToLinear( value );
}
#ifdef USE_ENVMAP
    uniform float envMapIntensity;
    uniform float flipEnvMap;
    #ifdef ENVMAP_TYPE_CUBE
        uniform samplerCube envMap;
    #else
        uniform sampler2D envMap;
    #endif
    
#endif
uniform float opacity;
varying vec3 vWorldDirection;
#ifdef ENVMAP_TYPE_CUBE_UV
    #define cubeUV_minMipLevel 4.0
    #define cubeUV_minTileSize 16.0
    float getFace( vec3 direction ) {
        vec3 absDirection = abs( direction );
        float face = - 1.0;
        if ( absDirection.x > absDirection.z ) {
            if ( absDirection.x > absDirection.y )
            face = direction.x > 0.0 ? 0.0 : 3.0;
            else
            face = direction.y > 0.0 ? 1.0 : 4.0;
        }
        else {
            if ( absDirection.z > absDirection.y )
            face = direction.z > 0.0 ? 2.0 : 5.0;
            else
            face = direction.y > 0.0 ? 1.0 : 4.0;
        }
        return face;
    }
    vec2 getUV( vec3 direction, float face ) {
        vec2 uv;
        if ( face == 0.0 ) {
            uv = vec2( direction.z, direction.y ) / abs( direction.x );
        }
        else if ( face == 1.0 ) {
            uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
        }
        else if ( face == 2.0 ) {
            uv = vec2( - direction.x, direction.y ) / abs( direction.z );
        }
        else if ( face == 3.0 ) {
            uv = vec2( - direction.z, direction.y ) / abs( direction.x );
        }
        else if ( face == 4.0 ) {
            uv = vec2( - direction.x, direction.z ) / abs( direction.y );
        }
        else {
            uv = vec2( direction.x, direction.y ) / abs( direction.z );
        }
        return 0.5 * ( uv + 1.0 );
    }
    vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
        float face = getFace( direction );
        float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
        mipInt = max( mipInt, cubeUV_minMipLevel );
        float faceSize = exp2( mipInt );
        vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
        if ( face > 2.0 ) {
            uv.y += faceSize;
            face -= 3.0;
        }
        uv.x += face * faceSize;
        uv.x += filterInt * 3.0 * cubeUV_minTileSize;
        uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
        uv.x *= CUBEUV_TEXEL_WIDTH;
        uv.y *= CUBEUV_TEXEL_HEIGHT;
        #ifdef texture2DGradEXT
            return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
        #else
            return texture2D( envMap, uv ).rgb;
        #endif
    }
    #define r0 1.0
    #define v0 0.339
    #define m0 - 2.0
    #define r1 0.8
    #define v1 0.276
    #define m1 - 1.0
    #define r4 0.4
    #define v4 0.046
    #define m4 2.0
    #define r5 0.305
    #define v5 0.016
    #define m5 3.0
    #define r6 0.21
    #define v6 0.0038
    #define m6 4.0
    float roughnessToMip( float roughness ) {
        float mip = 0.0;
        if ( roughness >= r1 ) {
            mip = ( r0 - roughness ) * ( m1 - m0 ) / ( r0 - r1 ) + m0;
        }
        else if ( roughness >= r4 ) {
            mip = ( r1 - roughness ) * ( m4 - m1 ) / ( r1 - r4 ) + m1;
        }
        else if ( roughness >= r5 ) {
            mip = ( r4 - roughness ) * ( m5 - m4 ) / ( r4 - r5 ) + m4;
        }
        else if ( roughness >= r6 ) {
            mip = ( r5 - roughness ) * ( m6 - m5 ) / ( r5 - r6 ) + m5;
        }
        else {
            mip = - 2.0 * log2( 1.16 * roughness );
        }
        return mip;
    }
    vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
        float mip = clamp( roughnessToMip( roughness ), m0, CUBEUV_MAX_MIP );
        float mipF = fract( mip );
        float mipInt = floor( mip );
        vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
        if ( mipF == 0.0 ) {
            return vec4( color0, 1.0 );
        }
        else {
            vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
            return vec4( mix( color0, color1, mipF ), 1.0 );
        }
    
    }
#endif

const float LinearEncodePowerApprox = 1.5;
const float GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;

float toGammaSpace(float color) {
    return pow(color, GammaEncodePowerApprox);
}
vec3 toGammaSpace(vec3 color) {
    return pow(color, vec3(GammaEncodePowerApprox));
}
vec4 toGammaSpace(vec4 color) {
    return vec4(pow(color.rgb, vec3(GammaEncodePowerApprox)), color.a);
}

vec4 applyImageProcessing(vec4 result) {
    result.rgb = toGammaSpace(result.rgb);
    result.rgb = saturate(result.rgb);
    return result;
}


void main() {
    vec3 vReflect = vWorldDirection;
    vec3 view = normalize( vWorldPosition - cameraPosition );
    float NdotV = absEps(dot(vNormal, view));
    vec3 analytic = getReflectanceFromAnalyticalBRDFLookup_Jones(NdotV, vec3(0.6), vec3(1.0), roughness);
    #ifdef USE_ENVMAP
        #ifdef ENV_WORLDPOS
            vec3 cameraToFrag;
            if ( isOrthographic ) {
                cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
            }
            else {
                cameraToFrag = normalize( vWorldPosition - cameraPosition );
            }
            vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
            #ifdef ENVMAP_MODE_REFLECTION
                vec3 reflectVec = reflect( cameraToFrag, worldNormal );
            #else
                vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
            #endif
        #else
            vec3 reflectVec = vReflect;
        #endif
        #ifdef ENVMAP_TYPE_CUBE
            vec4 envColor = textureCube( envMap, vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
            #elif defined( ENVMAP_TYPE_CUBE_UV )
            //vec4 envColor = 2.6 * textureCubeUV( envMap, reflectVec, roughness );
            // envColor += 2.0 * textureCubeUV( envMap, reflectVec, roughness + 0.2 );
            // envColor += 1.4 * textureCubeUV( envMap, reflectVec, roughness + 0.4 );
            // envColor += 0.8 * textureCubeUV( envMap, reflectVec, roughness + 0.6 );
            // envColor += 0.2 * textureCubeUV( envMap, reflectVec, roughness + 0.8 );
            // envColor = envColor / 7.0;
            vec4 envColor = textureCubeUV( envMap, reflectVec, roughness );
        #else
            vec4 envColor = vec4( 0.0 );
        #endif
        #ifdef ENVMAP_BLENDING_MULTIPLY
            outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
            #elif defined( ENVMAP_BLENDING_MIX )
            outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
            #elif defined( ENVMAP_BLENDING_ADD )
            outgoingLight += envColor.xyz * specularStrength * reflectivity;
        #endif
    #endif
    gl_FragColor = envColor * vec4(analytic, 1.0);
    gl_FragColor.a *= opacity;
    gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.00) + 0.5;

    // #if defined( TONE_MAPPING )
    //     gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
    // #endif
    //gl_FragColor = applyImageProcessing(gl_FragColor);
    //gl_FragColor.rgb = Uncharted2ToneMapping(toneMappingExposure * gl_FragColor.rgb);//toneMapping( gl_FragColor.rgb );
    //gl_FragColor = LinearTosRGB(gl_FragColor);
}
