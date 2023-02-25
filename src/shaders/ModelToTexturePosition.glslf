precision highp float;
uniform mat4 modelViewMatrix;
uniform mat4 modelMatrix;

varying vec3 vPos;
void main() {
    gl_FragColor = vec4((modelViewMatrix * vec4(vPos , 1.0)).xyz, 1.0);
}