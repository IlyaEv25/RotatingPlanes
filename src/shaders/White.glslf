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

layout(location = 0) out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor

precision highp float;
precision highp sampler2D;
precision highp usampler2D;

void main()
{
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}