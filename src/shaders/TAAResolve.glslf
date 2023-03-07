uniform sampler2D u_color;
uniform sampler2D u_depth;
uniform sampler2D u_velocity;
uniform sampler2D u_accumulated_color;
uniform sampler2D u_accumulated_depth;

uniform float u_counter;
uniform vec2 resolution;
varying vec2 vUv;

vec4 supersample(sampler2D sam, vec2 uv) {


    vec4 color = vec4(0.0);
    for(int x = -2; x <= 2; ++x)
    {
        for(int y = -2; y <= 2; ++y)
        {
            color += texture(sam, uv + 0.2 * vec2(float(x), float(y)) / resolution)  ;//CurrentTexture.Sample(uv + float2(x, y) / textureSize); // Sample neighbor
        }
    }

    return color / 25.0;
    // vec4 color = texture(sam, uv + 0.5 * vec2(1.0, 1.0) / resolution);
    // color += texture(sam, uv - 0.5 * vec2(1.0, 1.0) / resolution);
    // color += texture(sam, uv + 0.5 * vec2(-1.0, 1.0) / resolution);
    // color += texture(sam, uv + 0.5 * vec2(1.0, -1.0) / resolution);
    
    // return color / 4.0;
}

void main()
{


    //vec4 current = supersample(u_color, vUv); //texture(u_color, vUv);
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
            //vec3 color = supersample(u_color, vUv + vec2(float(x), float(y)) / resolution).rgb;
            minColor = min(minColor, color); // Take min and max
            maxColor = max(maxColor, color);
        }
    }
    // Clamp previous color to min/max bounding box

    if (u_counter >= 0.0)
    {
        vec4 previous = texture(u_accumulated_color, reprojectedUV);
        //vec4 previous = supersample(u_accumulated_color, reprojectedUV);
        previous.rgb = clamp(previous.rgb, minColor, maxColor);
        float previousDepth = texture(u_accumulated_depth, reprojectedUV).r;
        gl_FragColor = current * 0.1 + previous * 0.9;
        gl_FragDepth = currentDepth * 0.1 + previousDepth * 0.9;
        //gl_FragColor = current;
    }
    else
    {
        gl_FragColor = current;
        gl_FragDepth = currentDepth;
    }
}