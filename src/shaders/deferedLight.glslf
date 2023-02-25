//#define varying in


// #define LIGHTING 1
// #define POSTGREY 0
// #define ONECOLOR 0

// layout(location = 0) out highp vec4 pc_fragColor;
// #define gl_FragColor pc_fragColor
// #define gl_FragDepthEXT gl_FragDepth
// #define texture2D texture
// #define textureCube texture
// #define texture2DProj textureProj
// #define texture2DLodEXT textureLod
// #define texture2DProjLodEXT textureProjLod
// #define textureCubeLodEXT textureLod
// #define texture2DGradEXT textureGrad
// #define texture2DProjGradEXT textureProjGrad
// #define textureCubeGradEXT textureGrad

#define PI 3.141592653589793
#define PI2 6.283185307179586

#define ORIGINAL 0
#define PHYSICAL 1
#define BLACK 2

#define RECIPROCAL_PI 0.3183098861837907
#define TOTAL 65536

precision highp float;
precision highp sampler2D;

//uniform sampler2D map;
uniform sampler2D environmentMap;
uniform sampler2D u_depth;
uniform sampler2D u_normal;
uniform sampler2D u_color;
uniform sampler2D u_ssao_mask;
uniform sampler2D u_shadow_depth;

uniform mat4 projectionMatrixInverse;
uniform mat4 viewMatrixInverse;

uniform vec3 positionCamera;
uniform vec3 lightPosition;

uniform float lightIntensity;
uniform float lightRadius;
uniform float attenuationRadius;


uniform float roughness;
uniform float metallic;
uniform float u_spec;
uniform vec3 ambientColor;
uniform float ambientIntensity;
uniform float envMapIntensity;
uniform float toneMappingExposure;
uniform float shadowDarkness;
uniform float globalScale;

uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;
uniform mat4 shadowProjectionMatrixInverse;
uniform mat4 shadowViewMatrixInverse;

uniform float shadowRadius;
uniform float shadowBias;
uniform float numOfPoissonDisks;
uniform float useShadows;

varying vec2 vUv;



#ifndef saturate
    #define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define CUBEUV_TEXEL_WIDTH 0.0013020833333333333
#define CUBEUV_TEXEL_HEIGHT 0.0009765625
#define CUBEUV_MAX_MIP 8.0
#define cubeUV_minMipLevel 4.0
#define cubeUV_minTileSize 16.0
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

struct ReflectedLight {
    vec3 directDiffuse;
    vec3 directSpecular;
    vec3 indirectDiffuse;
    vec3 indirectSpecular;
};

float random(vec3 seed, int i){
	vec4 seed4 = vec4(seed,i);
	float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
	return fract(sin(dot_product) * 43758.5453);
}

highp float rand( const in vec2 uv ) {
    const highp float a = 12.9898, b = 78.233, c = 43758.5453;
    highp float dt = dot( uv.xy, vec2( a, b ) ), sn = mod( dt, PI );
    return fract( sin( sn ) * c );
}

float sampleVisibility( vec3 coord, float bias ) {
	vec2 sampleCo = (coord.xy + 1.0) / 2.0;
	

	float depth = texture2D( u_shadow_depth, sampleCo.xy ).r * 2.0 - 1.0;
	//depth = depth / f;

	float visibility  = ( coord.z - depth > bias ) ? 0. : 1.;
	return visibility;
}

vec3 hsv2rgb(vec3 c) {
#if POSTGREY == 1
    vec4 K = vec4(0.5, 3.0 / 3.0, 2.5 / 3.0, 3.0);
#else
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
#endif
    vec3 p = abs(fract(c.xxx - K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// vec3 hsv2rgb(vec3 c)
// {
//     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//     vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
//     return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
// }


vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


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

vec4 textureCubeUV( samplerCube envMap, vec3 sampleDir, float roughness ) {
	 return textureCube(envMap, sampleDir);

}

vec3 getIBLIrradiance( const in vec3 normal ) {
		//vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		vec4 envMapColor = textureCubeUV( environmentMap, normal, 1.0 );
		return PI * envMapColor.rgb * envMapIntensity;
}

vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
	vec3 reflectVec = reflect( - viewDir, normal );
	reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
	//reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
	vec4 envMapColor = textureCubeUV( environmentMap, reflectVec, roughness );
	return envMapColor.rgb * envMapIntensity;
}

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}
// ----------------------------------------------------------------------------
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
    float dotNV = clamp( dot( normal, viewDir ), 0.0, 1.0 );
    const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
    const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
    vec4 r = roughness * c0 + c1;
    float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
    vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
    return fab;
}

void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
    vec2 fab = DFGApprox( normal, viewDir, roughness );
    vec3 Fr = specularColor;
    vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
    float Ess = fab.x + fab.y;
    float Ems = 1.0 - Ess;
    vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;
    vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
    singleScatter += FssEss;
    multiScatter += Fms * Ems;
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
    return color; //clamp( color, 0.0, 1.0 );
}

vec3 Tonemap_ACES(vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 CustomToneMapping( vec3 color ) {
    return color;
}
vec3 toneMapping( vec3 color ) {
    return ACESFilmicToneMapping( color );
}

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


vec3 BRDF(vec3 v, vec3 l, vec3 n, vec3 albedo, float metallic, float roughness, float ao, vec3 ambientColor, float ambientIntensity, float visibility, float dist, float radius) {

	vec3 lightColor = vec3(1.0, 1.0, 1.0);

    vec3 N = n;
    vec3 V = v;
    
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, albedo, metallic);

    vec3 Lo = vec3(0.0);


	// calculate per-light radiance
	vec3 L = l;
	vec3 H = normalize(V + L);//length(V+L)> 0.01? normalize(V + L) : vec3(0.0);
	float distance = dist / attenuationRadius; // / 1000.0; //length(lightPosition - wPosition) - 3100.0;

	//float attenuation = pow(clamp(1.0 - pow(distance/(radius), 4.0), 0.0, 1.0), 2.0) / ((distance * distance) + 1.0);

	//float attenuation = 1.0 / (distance * distance);
	float attenuation = 2.0 / (distance * distance + radius * radius + distance * sqrt(distance * distance + radius * radius));
	vec3 radiance = lightIntensity * lightColor * attenuation; // + getIBLRadiance(v, n, roughness);



	// Cook-Torrance BRDF
	float NDF = DistributionGGX(N, H, roughness);   
	float G   = GeometrySmith(N, V, L, roughness);      
	vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);
		
	vec3 numerator    = NDF * G * F; 
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; // + 0.0001 to prevent divide by zero
	vec3 specular = numerator / denominator; //clamp(numerator / denominator, -1.0, 1.0); //might be good for microfacet model

	//vec3 specular = vec3(pow(max(dot(N, H), 0.0), 32.0));

	
	// kS is equal to Fresnel
	vec3 kS = F;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;	  

	float NdotL = max(dot(N, L), 0.0);// + 0.001;        

	vec3 indirectIrradiance = getIBLIrradiance( n );
	vec3 indirectRadiance = getIBLRadiance(v, n, roughness);

	//vec3 indirectSpecular = RE_IndirectSpecular_Physical( indirectRadiance, indirectIrradiance, vec3(0.0), const in GeometricContext geometry,)


	vec3 singleScattering = vec3( 0.0 );
    vec3 multiScattering = vec3( 0.0 );
    vec3 cosineWeightedIrradiance = indirectIrradiance * RECIPROCAL_PI;

    computeMultiscattering( n, v, F0, 1.0, roughness, singleScattering, multiScattering );

    vec3 totalScattering = singleScattering + multiScattering;
    vec3 diffuse = albedo * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
    vec3 indirectSpecular = indirectRadiance * singleScattering;
    indirectSpecular += multiScattering * cosineWeightedIrradiance;
    vec3 indirectDiffuse = diffuse * cosineWeightedIrradiance;

	// if (dot(l, N) <= 0.0)
	// 	radiance = vec3(0.0);

	Lo += (kD * albedo / PI + specular) * radiance * (NdotL) * ((1.0 - (1.0 - visibility) * shadowDarkness)) + indirectSpecular + indirectDiffuse;  // note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
    
    
    //vec3 ambient = vec3(0.03) * albedo * ao + ambientIntensity * ambientColor;
    vec3 ambient =  ambientIntensity * ambientColor;

    vec3 color = ambient + Lo;
	color *= ao;

    //color = color / (color + vec3(1.0));
	//color = ACESFilmicToneMapping(color);
    //color = pow(color, vec3(1.0/2.2)); 

	return color;
}

// vec4 LinearTosRGB( in vec4 value ) {
//     return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
// }

vec3 hueShift( vec3 color, float hueAdjust ){
    const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
    const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
    const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

    const vec3  kYIQToR     = vec3 (1.0, 0.956, 0.621);
    const vec3  kYIQToG     = vec3 (1.0, -0.272, -0.647);
    const vec3  kYIQToB     = vec3 (1.0, -1.107, 1.704);

    float   YPrime  = dot (color, kRGBToYPrime);
    float   I       = dot (color, kRGBToI);
    float   Q       = dot (color, kRGBToQ);
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    vec3    yIQ   = vec3 (YPrime, I, Q);

    return vec3( dot (yIQ, kYIQToR), dot (yIQ, kYIQToG), dot (yIQ, kYIQToB) );
}

vec3 greyscale(vec3 color, float str) {
    float g = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(color, vec3(g), str);
}

vec3 getWorldPositionFromDepth(mat4 projectionInverse, mat4 viewInverse, float depth) {
    float z = depth * 2.0 - 1.0;

    vec4 clipSpacePosition = vec4(vUv * 2.0 - 1.0, z, 1.0);
    vec4 viewSpacePosition = projectionInverse * clipSpacePosition;

    // Perspective division
    viewSpacePosition /= viewSpacePosition.w;

    vec4 worldSpacePosition = viewInverse * viewSpacePosition;

    return worldSpacePosition.xyz;
}

vec4 getShadowPosition(vec3 worldPosition)
{
	return shadowProjectionMatrix * shadowViewMatrix * vec4(worldPosition, 1.0);
}

void main() {

	int NUM_TAPS = int(numOfPoissonDisks);

	vec2 poissonDisk[12];
	poissonDisk[0 ] = vec2( -0.94201624, -0.39906216 );
	poissonDisk[1 ] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2 ] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3 ] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4 ] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5 ] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6 ] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7 ] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8 ] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9 ] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );

	float depth = texture(u_depth, vUv).r;
	float alpha = texture(u_color, vUv).a;

	gl_FragDepth = depth;

	vec3 wPosition = getWorldPositionFromDepth(projectionMatrixInverse, viewMatrixInverse, depth);

	vec3 l = normalize( lightPosition - wPosition.xyz );
	vec3 v = normalize( positionCamera - wPosition.xyz);
	vec3 n = normalize(texture(u_normal, vUv).rgb);

	float occlusion = 0.;
	//float shadowDepth = texture(u_shadow_depth, vUv).r;
	vec4 shadowPosition = getShadowPosition(wPosition);
	vec3 shadowCoord = shadowPosition.xyz / shadowPosition.w;

	float ANGLE_STEP = PI2 * float( 5 ) / float( NUM_TAPS );
    float INV_NUM_SAMPLES = 1.0 / float( NUM_TAPS );
        
	float angle = rand( shadowCoord.xy ) * PI2;
	float radius = INV_NUM_SAMPLES;
	float radiusStep = radius;

	if (useShadows > 0.5 && NUM_TAPS > 0)
	{
		for (int i=0; i < NUM_TAPS; i++) {
			vec2 poissonDisk = vec2( cos( angle ), sin( angle ) ) * pow( shadowRadius * 0.1 * (1.0 / 1024.0), 0.75 );
			occlusion += sampleVisibility( shadowCoord + vec3(poissonDisk, 0.), shadowBias);

			radius += radiusStep;
        	angle += ANGLE_STEP;
		}
		occlusion /= float( NUM_TAPS );
	}

	else if(useShadows > 0.5 && NUM_TAPS == 0)
		occlusion = sampleVisibility( shadowCoord, shadowBias);

	else
		occlusion = 1.0;

#if LIGHTING == ORIGINAL

	float NdotL = max(dot(n, l), 0.0) + 0.001;
	vec3 R = normalize(-reflect(l, n));
	vec3 specular = u_spec * vec3(4. * pow(max(dot(R, v), 0.0), 100.));

	float vLife = 50.0;
	float c = texture(u_color, vUv).r;
	gl_FragColor.rgb = hsv2rgb( vec3(c + .1 * vColor.x, clamp(d - .25 * vLife / 100.0, 0.0, 1.0), (0.5 + 0.5 * NdotL) * ( clamp(e - shadowDarkness * ( 1.0 - occlusion ), 0.0, 1.0) ) ) );
	gl_FragColor.a = alpha;
    gl_FragColor.rgb += vec3(specular) * occlusion;
    
#if POSTGREY == 1
	gl_FragColor.rgb += .1 * vec3(55.,85.,149.)/255.;
    gl_FragColor.rgb = greyscale(gl_FragColor.rgb, .4);
    gl_FragColor.rgb = hueShift(gl_FragColor.rgb, -.325);
#endif

#elif LIGHTING == PHYSICAL

	float ao = texture(u_ssao_mask, vUv).r;
	float sphereRadius = lightRadius;
	vec3 r = reflect(-v, n);
	vec3 L = lightPosition - wPosition.xyz;
	float distLight = length(L);
	L = normalize(L);
	vec3 albedo = texture(u_color, vUv).xyz;

	gl_FragColor = vec4(BRDF(v, L, n, albedo, metallic, roughness, ao, ambientColor, ambientIntensity, occlusion, distLight, sphereRadius), alpha);
#else
	gl_FragColor.rgb = vec3(0.0, 0.0, 0.0);
	gl_FragColor.a = 1.0;
#endif
}