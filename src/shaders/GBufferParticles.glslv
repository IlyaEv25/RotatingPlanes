//#version 300 es
#define attribute in
#define varying out
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

attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
attribute vec2 lookup;
attribute float inds;

uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 previousViewMatrix;

uniform usampler2D currentPositions;
uniform usampler2D previousPositions;
uniform usampler2D previousPreviousPositions;
uniform usampler2D noForcesPositions;
uniform vec3 scale;
uniform float squashiness;

uniform vec3 center;
uniform float globalScale;
uniform mat3 globalRotation;

uniform float u_counter;
uniform vec2 resolution;

varying vec3 vNormal;
varying float fDifference;
flat varying int vInd;

varying vec3 vColor;
varying vec4 vPreviousClipSpacePosition;
varying vec4 vClipSpacePosition;

mat3 calcLookAtMatrix(vec3 origin,vec3 target,float roll){
	vec3 rr=vec3(sin(roll),cos(roll),0.);
	vec3 ww=normalize(target-origin);
	vec3 uu=normalize(cross(ww,rr));
	vec3 vv=normalize(cross(uu,ww));
	
	return mat3(uu,vv,ww);
}

float Halton(int i, int b)
{
    float f = 1.0;
    float r = 0.0;
 
    while (i > 0)
    {
        f /= float(b);
        r = r + f * float(mod(float(i), float(b)));
        i = int(floor(float(i) / float(b)));
    }
 
    return r;
}


void main(){
	
	vec2 luv=lookup;
	vec4 i= uintBitsToFloat(texture(currentPositions,luv));
	//vLife=i.w;
	vec4 p= uintBitsToFloat(texture(previousPositions,luv));
	vec4 pp = uintBitsToFloat(texture(previousPreviousPositions,luv));

	i.xyz = globalRotation * i.xyz;
	p.xyz = globalRotation * p.xyz;
	vec3 orientation=i.xyz-p.xyz;
	mat3 rot=calcLookAtMatrix(p.xyz,i.xyz,0.); //this changes triangles orientation! BEWARE!
	float squash=length(orientation);
	squash=clamp(squash,1.,100.);
	// vec3 vPosition=rot*(position*scale*mix(vec3(1.),vec3(1./squash,1./squash,squash),squashiness));
	// vPosition+=mix(p.xyz,i.xyz,.5);
	// vNormal=rot*normal;

	vec3 vPosition=(position*scale*mix(vec3(1.),vec3(1./squash,1./squash,squash),squashiness));
	vPreviousClipSpacePosition = vec4(vPosition + mix(pp.xyz,p.xyz,.5), 1.0);
	vPosition+=mix(p.xyz,i.xyz,.5);
	vNormal=normal;
	
	if(i.w==100.||p.w==100.){
		vPosition.x+=100000.;
	}
	
	if(i.w>150.||p.w>150.){
		vPosition.x+=100000.;
	}

	if (length(i.xyz - center) < 18.5) //58.5
		vPosition.xyz = vec3(100000.0);
	
	fDifference=length(uintBitsToFloat(texture(currentPositions,luv).xyz)- globalScale * uintBitsToFloat(texture(noForcesPositions,luv).xyz));
	
	vInd=int(inds);
	vNormal=normalize(vNormal);

	float haltonX = 2.0 * Halton(int(u_counter) + 1, 2) - 1.0;
	float haltonY = 2.0 * Halton(int(u_counter) + 1, 3) - 1.0;
	float jitterX = (haltonX /  (1.0 * resolution.x));
	float jitterY = (haltonY / (1.0 * resolution.y));

	mat4 jitteredProjectionMatrix = projectionMatrix;
	jitteredProjectionMatrix[2][0] = jitterX;
	jitteredProjectionMatrix[2][1] = jitterY;

	float previousHaltonX = 2.0 * Halton(int(u_counter), 2) - 1.0;
	float previousHaltonY = 2.0 * Halton(int(u_counter), 3) - 1.0;
	float previousJitterX = (previousHaltonX / (2.0 * resolution.x));
	float previousJitterY = (previousHaltonY / (2.0 * resolution.y));

	mat4 jitteredPrevioisProjectionMatrix = projectionMatrix;
	jitteredPrevioisProjectionMatrix[0][2] = previousJitterX;
	jitteredPrevioisProjectionMatrix[1][2] = previousJitterY;

	//better use previous modelview matrix
	//vJitteredPreviousClipSpacePosition = jitteredPrevioisProjectionMatrix * vec4((previousViewMatrix * vPreviousClipSpacePosition).xyz, 1.0);
	//vJitteredClipSpacePosition = jitteredProjectionMatrix * vec4((modelViewMatrix * vec4(vPosition, 1.0)).xyz, 1.0);

	//vJitteredPreviousClipSpacePosition = jitteredPrevioisProjectionMatrix * vec4((previousViewMatrix * vPreviousClipSpacePosition).xyz, 1.0);
	vPreviousClipSpacePosition = projectionMatrix * vec4((previousViewMatrix * vPreviousClipSpacePosition).xyz, 1.0);
	vClipSpacePosition = projectionMatrix * vec4((modelViewMatrix * vec4(vPosition, 1.0)).xyz, 1.0);

	vec4 mvp=modelViewMatrix*vec4(vPosition,1.);
	gl_Position=jitteredProjectionMatrix*vec4(mvp.xyz,1.);
}