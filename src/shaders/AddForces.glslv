#version 300 es
precision highp float;

in vec3 position;
in vec2 uv;

void main() {

    vec2 drawUV = uv * 2.0 - 1.0;

    gl_Position = vec4(drawUV.x, drawUV.y, 0.0, 1.0);

}