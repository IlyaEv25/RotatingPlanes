#define maxBlurRadius 20
uniform sampler2D u_velocity;
uniform vec2 resolution;

uniform vec2      readScaleBias;
uniform vec2      writeScaleBias;
//uniform sampler2D   SS_POSITION_CHANGE_buffer;

// Expects macro maxBlurRadius;

void main() {

    vec2 m = vec2(0.0);
    float largestMagnitude2 = 0.0;

    // Round down to the tile corner.  Note that we're only filtering in the x direction of the source,
    // so the y dimension is unchanged.  Also note the transpose relative to the input
    int tileCornerX = int(gl_FragCoord.y) * maxBlurRadius;
    int tileRowY    = int(gl_FragCoord.x);

    int maxCoordX = textureSize(u_velocity, 0).x - 1;

    for (int offset = 0; offset < maxBlurRadius; ++offset) { 

        ivec2 G = ivec2(clamp(tileCornerX + offset, 0, maxCoordX), tileRowY);
        vec2 v_G = texelFetch(u_velocity, G, 0).rg * readScaleBias.x + readScaleBias.y;

        // Magnitude squared
        float thisMagnitude2 = dot(v_G, v_G);

        if (thisMagnitude2 > largestMagnitude2) {
            // This is the new largest PSF
            m = v_G;
            largestMagnitude2 = thisMagnitude2;
        }
    }
    
    vec2 tileMax = m * writeScaleBias.x + writeScaleBias.y;
    gl_FragColor = vec4(tileMax, 0.0, 1.0);
}
