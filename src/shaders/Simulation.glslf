#version 300 es

precision highp float;
precision highp sampler2D;
precision highp usampler2D;

uniform usampler2D forcesT;
uniform usampler2D source;

uniform sampler2D seed;
uniform sampler2D seed2;
uniform sampler2D initT;
uniform sampler2D envMap;

uniform float t;
uniform float f;
uniform float drag;
uniform float dragT;
uniform vec3 attractor;
uniform vec3 pAttractor;
// uniform sampler2D model;
uniform float time;
uniform float persistence;
uniform float speed;
uniform float decay;
uniform float spread;
uniform float init;
uniform float animationType;
uniform vec3 translationM1;
uniform vec3 translationM2;
uniform mat3 rotationM1;
uniform mat3 rotationM2;
uniform float scaleM1;
uniform float scaleM2;

uniform vec3 zeroP;
uniform vec3 oneP;

in vec2 vUv;

layout(location = 0) out highp uvec4 fragColor;


vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float random(vec3 seed, int i){
	vec4 seed4 = vec4(seed,i);
	float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
	return fract(sin(dot_product) * 43758.5453);
}

float mod289(float x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float permute(float x) {
    return mod289(((x*34.0)+1.0)*x);
}


vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 grad4(float j, vec4 ip) {
    const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
    vec4 p,s;

    p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
    p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
    s = vec4(lessThan(p, vec4(0.0)));
    p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

    return p;
}


#define F4 0.309016994374947451

vec4 simplexNoiseDerivatives (vec4 v) {
    const vec4  C = vec4( 0.138196601125011,0.276393202250021,0.414589803375032,-0.447213595499958);

    vec4 i  = floor(v + dot(v, vec4(F4)) );
    vec4 x0 = v -   i + dot(i, C.xxxx);

    vec4 i0;
    vec3 isX = step( x0.yzw, x0.xxx );
    vec3 isYZ = step( x0.zww, x0.yyz );
    i0.x = isX.x + isX.y + isX.z;
    i0.yzw = 1.0 - isX;
    i0.y += isYZ.x + isYZ.y;
    i0.zw += 1.0 - isYZ.xy;
    i0.z += isYZ.z;
    i0.w += 1.0 - isYZ.z;

    vec4 i3 = clamp( i0, 0.0, 1.0 );
    vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
    vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

    vec4 x1 = x0 - i1 + C.xxxx;
    vec4 x2 = x0 - i2 + C.yyyy;
    vec4 x3 = x0 - i3 + C.zzzz;
    vec4 x4 = x0 + C.wwww;

    i = mod289(i);
    float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
    vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));


    vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

    vec4 p0 = grad4(j0,   ip);
    vec4 p1 = grad4(j1.x, ip);
    vec4 p2 = grad4(j1.y, ip);
    vec4 p3 = grad4(j1.z, ip);
    vec4 p4 = grad4(j1.w, ip);

    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    p4 *= taylorInvSqrt(dot(p4,p4));

    vec3 values0 = vec3(dot(p0, x0), dot(p1, x1), dot(p2, x2)); //value of contributions from each corner at point
    vec2 values1 = vec2(dot(p3, x3), dot(p4, x4));

    vec3 m0 = max(0.5 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0); //(0.5 - x^2) where x is the distance
    vec2 m1 = max(0.5 - vec2(dot(x3,x3), dot(x4,x4)), 0.0);

    vec3 temp0 = -6.0 * m0 * m0 * values0;
    vec2 temp1 = -6.0 * m1 * m1 * values1;

    vec3 mmm0 = m0 * m0 * m0;
    vec2 mmm1 = m1 * m1 * m1;

    float dx = temp0[0] * x0.x + temp0[1] * x1.x + temp0[2] * x2.x + temp1[0] * x3.x + temp1[1] * x4.x + mmm0[0] * p0.x + mmm0[1] * p1.x + mmm0[2] * p2.x + mmm1[0] * p3.x + mmm1[1] * p4.x;
    float dy = temp0[0] * x0.y + temp0[1] * x1.y + temp0[2] * x2.y + temp1[0] * x3.y + temp1[1] * x4.y + mmm0[0] * p0.y + mmm0[1] * p1.y + mmm0[2] * p2.y + mmm1[0] * p3.y + mmm1[1] * p4.y;
    float dz = temp0[0] * x0.z + temp0[1] * x1.z + temp0[2] * x2.z + temp1[0] * x3.z + temp1[1] * x4.z + mmm0[0] * p0.z + mmm0[1] * p1.z + mmm0[2] * p2.z + mmm1[0] * p3.z + mmm1[1] * p4.z;
    float dw = temp0[0] * x0.w + temp0[1] * x1.w + temp0[2] * x2.w + temp1[0] * x3.w + temp1[1] * x4.w + mmm0[0] * p0.w + mmm0[1] * p1.w + mmm0[2] * p2.w + mmm1[0] * p3.w + mmm1[1] * p4.w;

    return vec4(dx, dy, dz, dw) * 49.0;
}

vec3 curlNoise(vec3 p, float per) {

	float t = .01 * time / 16.6667;

	vec4 xNoisePotentialDerivatives = vec4(0.0);
	vec4 yNoisePotentialDerivatives = vec4(0.0);
	vec4 zNoisePotentialDerivatives = vec4(0.0);

	for (int i = 0; i < 3; ++i) {
	    float scale = (1.0 / 2.0) * pow(2.0, float(i));

	    float noiseScale = pow(per, float(i));
	    if (per == 0.0 && i == 0) { //fix undefined behaviour
	        noiseScale = 1.0;
	    }

	    xNoisePotentialDerivatives += simplexNoiseDerivatives(vec4(p * pow(2.0, float(i)), t)) * noiseScale * scale;
	    yNoisePotentialDerivatives += simplexNoiseDerivatives(vec4((p + vec3(123.4, 129845.6, -1239.1)) * pow(2.0, float(i)), t)) * noiseScale * scale;
	    zNoisePotentialDerivatives += simplexNoiseDerivatives(vec4((p + vec3(-9519.0, 9051.0, -123.0)) * pow(2.0, float(i)), t)) * noiseScale * scale;
	}

	vec3 noiseVelocity = vec3(
		zNoisePotentialDerivatives[1] - yNoisePotentialDerivatives[2],
		xNoisePotentialDerivatives[2] - zNoisePotentialDerivatives[0],
		yNoisePotentialDerivatives[0] - xNoisePotentialDerivatives[1] );

	return noiseVelocity;

}

void main() {
    vec4 floatFragColor;
	vec4 s = uintBitsToFloat(texture(source,vUv));
	//float f = (sin((1.0 - t) * 3.14/2.0 + t * 3.0 * 3.14 / 2.0 ) + 1.0) / 2.0;
    float badParticle = 0.0;

    vec3 finalPosition = uintBitsToFloat(texture(forcesT, vUv).xyz);
    float vLife = uintBitsToFloat(texture(forcesT, vUv).a);
    
    float r1 = random(finalPosition, int(floor(f * 1000.0)));
    float r2 = random(vec3(50.0) - finalPosition, int(floor(f * 78.0)));
    float pix = (1.0 - f) * texture(seed,vUv).w + f * texture(seed2, vUv).w;

    if (animationType == 1.0)
        if ( pix + (texture(initT, vUv).w/100.0 - 0.5) * 0.5 < 0.7)
            badParticle = 1.0; //1.0

    if (animationType == 2.0)
        if (texture(seed,vUv).w < 0.05 || texture(seed2, vUv).w < 0.05)
            badParticle = 1.0;

    vec3 pos = (1.0 - f) * zeroP + f * oneP;

	if( vLife <= 0. || (drag > 0.3 &&  drag < 0.8) || (vLife > 150.0 && vLife < 151.0 ) ) {

        vec4 first = texture(seed,vUv).a > 0.0? texture(seed,vUv) : vec4(0.0, 0.0, 0.0, 0.0);
        vec4 second = texture(seed2, vUv).a > 0.0? texture(seed2, vUv) : vec4(0.0, 0.0, 0.0, 0.0);

        first.xyz = (rotationM1 * scaleM1 * first.xyz) + translationM1;
        second.xyz = (rotationM2 * scaleM2 * second.xyz) + translationM2;

		s = (1.0 - f) * first + f * second + vec4(pos, 0.0); 
		if (drag > 0.3 &&  drag < 0.8 || (vLife > 150.0 && vLife < 151.0 ))
			s.w = texture(initT, vUv).w;
		else
			if( init == 0. ) s.w = 100.;

	}else{

		s.xyz += 3.0 * speed * 2.0 * abs(abs(0.5 - f) - 0.505) * curlNoise( .001 * s.xyz, persistence).xyz;
		s.w = vLife - decay;
	}

    if (badParticle < 0.5)
	    floatFragColor = s;
    else
        floatFragColor = vec4(s.xyz, 152.0);

    fragColor = floatBitsToUint(floatFragColor);
}