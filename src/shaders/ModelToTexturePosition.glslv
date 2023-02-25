precision highp float;

attribute vec3 position;
attribute vec2 uv;

uniform mat4 modelMatrix;
varying vec3 vPos;

void main() {
    vPos = position.xyz;
    vec2 drawUV = uv * 2.0 - 1.0;
    gl_Position = vec4(drawUV.x, drawUV.y, 0.0, 1.0);
}