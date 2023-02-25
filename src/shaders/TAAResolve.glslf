uniform sampler2D u_color;
uniform sampler2D u_depth;
uniform sampler2D u_velocity;
uniform sampler2D u_accumulated_color;
uniform sampler2D u_accumulated_depth;

uniform float u_counter;
uniform vec2 resolution;
varying vec2 vUv;

void main()
{


    vec4 current = texture(u_color, vUv);
    float currentDepth = texture(u_depth, vUv).r;
    vec2 velocityUV = texture(u_velocity, vUv).ba; // / ( resolution * 1.5 ); 
    vec2 reprojectedUV = vUv - velocityUV;

    // Arbitrary out of range numbers
    vec3 minColor = vec3(9999.0);
    vec3 maxColor = vec3(-9999.0);
    // Sample a 3x3 neighborhood to create a box in color space
    for(int x = -1; x <= 1; ++x)
    {
        for(int y = -1; y <= 1; ++y)
        {
            vec3 color = texture(u_color, vUv + vec2(float(x), float(y)) / resolution).rgb  ;//CurrentTexture.Sample(uv + float2(x, y) / textureSize); // Sample neighbor
            minColor = min(minColor, color); // Take min and max
            maxColor = max(maxColor, color);
        }
    }
    // Clamp previous color to min/max bounding box

    if (u_counter >= 0.0)
    {
        vec4 previous = texture(u_accumulated_color, reprojectedUV);
        previous.rgb = clamp(previous.rgb, minColor, maxColor);
        float previousDepth = texture(u_accumulated_depth, reprojectedUV).r;
        gl_FragColor = current * 0.1 + previous * 0.9;
        gl_FragDepth = currentDepth * 0.1 + previousDepth * 0.9;
    }
    else
    {
        gl_FragColor = current;
        gl_FragDepth = currentDepth;
    }
}