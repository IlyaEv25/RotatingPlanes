// This shader performs upsampling on a texture,
// as taken from Call Of Duty method, presented at ACM Siggraph 2014.

// Remember to add bilinear minification filter for this texture!
// Remember to use a floating-point texture format (for HDR)!
// Remember to use edge clamping for this texture!
uniform sampler2D u_previous;
uniform sampler2D u_background;

uniform float filterRadius;
uniform float bloomStrength;

varying vec2 vUv;

void main()
{
    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.
    float x = filterRadius;
    float y = filterRadius;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(u_previous, vec2(vUv.x - x, vUv.y + y)).rgb;
    vec3 b = texture(u_previous, vec2(vUv.x,     vUv.y + y)).rgb;
    vec3 c = texture(u_previous, vec2(vUv.x + x, vUv.y + y)).rgb;

    vec3 d = texture(u_previous, vec2(vUv.x - x, vUv.y)).rgb;
    vec3 e = texture(u_previous, vec2(vUv.x,     vUv.y)).rgb;
    vec3 f = texture(u_previous, vec2(vUv.x + x, vUv.y)).rgb;

    vec3 g = texture(u_previous, vec2(vUv.x - x, vUv.y - y)).rgb;
    vec3 h = texture(u_previous, vec2(vUv.x,     vUv.y - y)).rgb;
    vec3 i = texture(u_previous, vec2(vUv.x + x, vUv.y - y)).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    gl_FragColor.rgb = e*4.0;
    gl_FragColor.rgb += (b+d+f+h)*2.0;
    gl_FragColor.rgb += (a+c+g+i);
    gl_FragColor.rgb *= 1.0 / 16.0;
#ifndef FINAL
    gl_FragColor.rgb = gl_FragColor.rgb + texture(u_background, vUv).rgb;
#else
    gl_FragColor.rgb = mix(texture(u_background, vUv).rgb, gl_FragColor.rgb, bloomStrength);
#endif
    gl_FragColor.a = 1.0;
}
