#define PI 3.141592653589793
#define PI2 6.283185307179586

#define RECIPROCAL_PI 0.3183098861837907
#define TOTAL 65536

precision highp float;
precision highp sampler2D;

//uniform sampler2D map;
uniform sampler2D environmentMap;
uniform sampler2D u_depth;
uniform sampler2D u_normal_metalness;
uniform sampler2D u_albedo_roughness;
uniform sampler2D u_emission;

uniform sampler2D u_ssao_mask;

#if NUM_LIGHTS > 0
uniform sampler2D u_shadow_depth[NUM_LIGHTS];
#endif

uniform mat4 projectionMatrixInverse;
uniform mat4 viewMatrixInverse;

uniform vec3 positionCamera;

uniform float envMapIntensity;
uniform float shadowDarkness;

#if NUM_LIGHTS > 0
uniform mat4 shadowProjectionMatrix[NUM_LIGHTS];
uniform mat4 shadowViewMatrix[NUM_LIGHTS];
uniform mat4 shadowProjectionMatrixInverse[NUM_LIGHTS];
uniform mat4 shadowViewMatrixInverse[NUM_LIGHTS];
#endif

uniform float shadowRadius;
uniform float shadowBias;
uniform float numOfPoissonDisks;

varying vec2 vUv;

struct Light {
	vec3 position;
	vec3 color;
	float intensity;
	float type;
	float attenuationRadius;
	float radius;
	float useShadow;
};

#if NUM_LIGHTS > 0
uniform Light lights[NUM_LIGHTS];
#endif

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

vec3 BRDF(vec3 v, vec3 l, vec3 n, vec3 albedo, float metallic, float roughness, float visibility, float dist, float radius, float attenuationRadius, float lightIntensity, vec3 lightColor) {


    vec3 N = n;
    vec3 V = v;
    
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, albedo, metallic);

    vec3 Lo = vec3(0.0);


	// calculate per-light radiance
	vec3 L = l;
	vec3 H = normalize(V + L);
	float distance = dist / attenuationRadius; 
	float attenuation = 2.0 / (distance * distance + radius * radius + distance * sqrt(distance * distance + radius * radius));
	vec3 radiance = lightIntensity * lightColor * attenuation; 
	// Cook-Torrance BRDF
	float NDF = DistributionGGX(N, H, roughness);   
	float G   = GeometrySmith(N, V, L, roughness);      
	vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);
	vec3 numerator    = NDF * G * F; 
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; // + 0.0001 to prevent divide by zero
	vec3 specular = numerator / denominator; 
	// kS is equal to Fresnel
	vec3 kS = F;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;	  
	float NdotL = max(dot(N, L), 0.0);// + 0.001;        
	Lo += (kD * albedo / PI + specular) * radiance * (NdotL) * ((1.0 - (1.0 - visibility) * shadowDarkness));  // note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
	return Lo;
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

vec4 getShadowPosition(vec3 worldPosition, int index)
{
	return shadowProjectionMatrix[index] * shadowViewMatrix[index] * vec4(worldPosition, 1.0);
}

vec2 poissonDisk[12];

#if NUM_LIGHTS > 0

float sampleVisibility( int index, vec3 coord, float bias ) {
	vec2 sampleCo = (coord.xy + 1.0) / 2.0;
	
	float depth;

	if (index == 0) depth = texture2D( u_shadow_depth[0], sampleCo.xy ).r * 2.0 - 1.0;
	if (index == 1) depth = texture2D( u_shadow_depth[1], sampleCo.xy ).r * 2.0 - 1.0;
	if (index == 2) depth = texture2D( u_shadow_depth[2], sampleCo.xy ).r * 2.0 - 1.0;
	if (index == 3) depth = texture2D( u_shadow_depth[3], sampleCo.xy ).r * 2.0 - 1.0;
	//if (index == 4) depth = texture2D( u_shadow_depth[4], sampleCo.xy ).r * 2.0 - 1.0;
	//if (index == 5) depth = texture2D( u_shadow_depth[5], sampleCo.xy ).r * 2.0 - 1.0;
			
	//depth = depth / f;

	float visibility  = ( coord.z - depth > bias ) ? 0. : 1.;
	return visibility;
}

float calculateOcclusion(vec3 wPosition, int index)
{
	int NUM_TAPS = int(numOfPoissonDisks);
	float occlusion = 0.;

	vec4 shadowPosition = getShadowPosition(wPosition, index);
	vec3 shadowCoord = shadowPosition.xyz / shadowPosition.w;

	float ANGLE_STEP = PI2 * float( 5 ) / float( NUM_TAPS );
    float INV_NUM_SAMPLES = 1.0 / float( NUM_TAPS );
        
	float angle = rand( shadowCoord.xy ) * PI2;
	float radius = INV_NUM_SAMPLES;
	float radiusStep = radius;

	if (lights[index].useShadow > 0.5 && NUM_TAPS > 0)
	{
		for (int i=0; i < NUM_TAPS; i++) {
			vec2 poissonDisk = vec2( cos( angle ), sin( angle ) ) * pow( shadowRadius * 0.1 * (1.0 / 1024.0), 0.75 );
			occlusion += sampleVisibility( index, shadowCoord + vec3(poissonDisk, 0.), shadowBias);

			radius += radiusStep;
        	angle += ANGLE_STEP;
		}
		occlusion /= float( NUM_TAPS );
	}

	else if(lights[index].useShadow > 0.5 && NUM_TAPS == 0)
		occlusion = sampleVisibility( index, shadowCoord, shadowBias);

	else
		occlusion = 1.0;

	return occlusion;
}

#endif

void main() {

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
	float ao = texture(u_ssao_mask, vUv).r;
	vec3 albedo = texture(u_albedo_roughness, vUv).xyz;
	float metallic = texture(u_normal_metalness, vUv).a;
	float preRoughness = texture(u_albedo_roughness, vUv).a;

	float alpha = preRoughness > 1.0 ? 1.0 : 0.0;
	float roughness = preRoughness - 1.0;

	vec3 emissionColor = texture(u_emission, vUv).xyz;
	float emissionStrength = texture(u_emission, vUv).a;

	vec3 wPosition = getWorldPositionFromDepth(projectionMatrixInverse, viewMatrixInverse, depth);
	vec3 v = normalize( positionCamera - wPosition.xyz);
	vec3 n = normalize(texture(u_normal_metalness, vUv).rgb);
	vec3 r = reflect(-v, n);


	vec3 color = vec3(0.0);


#if NUM_LIGHTS > 0
	for (int i = 0; i < NUM_LIGHTS; i++)
	{
		vec3 L = lights[i].position - wPosition.xyz;
		float distLight = length(L);
		L = normalize(L);
		float occlusion = calculateOcclusion(wPosition, i);

		float radius = lights[i].radius;
		float attenuationRadius = lights[i].attenuationRadius;
		float lightIntensity = lights[i].intensity;
		vec3 lightColor = lights[i].color;

		color += BRDF(v, L, n, albedo, metallic, roughness, occlusion, distLight, radius, attenuationRadius, lightIntensity, lightColor);
	}
#endif

	vec3 indirectIrradiance = getIBLIrradiance( n );
	vec3 indirectRadiance = getIBLRadiance(v, n, roughness);
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = indirectIrradiance * RECIPROCAL_PI;

	vec3 F0 = vec3(0.04);
	F0 = mix(F0, albedo, metallic);
	computeMultiscattering( n, v, F0, 1.0, roughness, singleScattering, multiScattering );

	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = albedo * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
	vec3 indirectSpecular = indirectRadiance * singleScattering;
	indirectSpecular += multiScattering * cosineWeightedIrradiance;
	vec3 indirectDiffuse = diffuse * cosineWeightedIrradiance;

	color += indirectSpecular + indirectDiffuse;
	color += emissionStrength * emissionColor;
	color *= ao;

	gl_FragColor = vec4(color, alpha);
	gl_FragDepth = depth;
}