uniform sampler2D u_color;
uniform sampler2D u_depth;
varying vec2 vUv;

void main()
{
    gl_FragColor = texture(u_color, vUv);
    gl_FragDepth = texture(u_depth, vUv).r;
}