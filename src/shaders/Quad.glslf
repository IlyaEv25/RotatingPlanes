uniform sampler2D u_color;
varying vec2 vUv;

void main()
{
    gl_FragColor = texture(u_color, vUv);
}