uniform vec3 colorTop;
uniform vec3 colorBottom;

varying vec2 vUv;

void main()
{
    gl_FragColor = vec4((1.0 - vUv.y) * colorBottom + vUv.y * colorTop, 1.0);
}