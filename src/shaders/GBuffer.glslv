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

attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;

uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 previousViewMatrix;
uniform mat4 previousModelMatrix;

uniform float u_counter;
uniform vec2 resolution;

varying vec3 vNormal;
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
	
	vec3 vPosition = position;
	vNormal=normalize(normal);

	float haltonX = 2.0 * Halton(int(u_counter) + 1, 2) - 1.0;
	float haltonY = 2.0 * Halton(int(u_counter) + 1, 3) - 1.0;
	float jitterX = (haltonX /  (1.0 * resolution.x));
	float jitterY = (haltonY / (1.0 * resolution.y));

	mat4 jitteredProjectionMatrix = projectionMatrix;
	jitteredProjectionMatrix[2][0] = jitterX;
	jitteredProjectionMatrix[2][1] = jitterY;

	vPreviousClipSpacePosition = projectionMatrix * vec4((previousViewMatrix * previousModelMatrix * vec4(vPosition, 1.0)).xyz, 1.0);
	vClipSpacePosition = projectionMatrix * vec4((modelViewMatrix * vec4(vPosition, 1.0)).xyz, 1.0);

	vec4 mvp=modelViewMatrix*vec4(vPosition,1.);
	gl_Position=jitteredProjectionMatrix*vec4(mvp.xyz,1.);
}