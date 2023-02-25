uniform vec2      readScaleBias;
uniform vec2      writeScaleBias;

// This is actually the tileMax buffer, but the way that the GBuffer
// infrastructure works renames it to the u_tile
// from which it was computed.
uniform sampler2D   u_tile;

#define tileMax u_tile


// Only gather neighborhood velocity into tiles that could be affected by it.
// In the general case, only six of the eight neighbors contribute:
//
//  This tile can't possibly be affected by the center one
//     |
//     v
//    ____ ____ ____
//   |    | ///|/// |
//   |____|////|//__|    
//   |    |////|/   |
//   |___/|////|____|    
//   |  //|////|    | <--- This tile can't possibly be affected by the center one
//   |_///|///_|____|    
//
void main() {
    // Vector with the largest magnitude
    vec2 m = vec2(0.0);
    
    // Squared magnitude of m
    float largestMagnitude2 = 0.0;

    ivec2 maxCoord = textureSize(tileMax, 0) - ivec2(1);

    ivec2 currentTile = ivec2(gl_FragCoord.xy);
    ivec2 offset;
    for (offset.y = -1; offset.y <= +1; ++offset.y) {
        for (offset.x = -1; offset.x <= +1; ++offset.x) {

            ivec2 neighborTile = currentTile + offset;
            vec2 vmax_neighbor = texelFetch(tileMax, clamp(neighborTile, ivec2(0), maxCoord), 0).rg * readScaleBias.x + readScaleBias.y;


            // Magnitude squared
            float magnitude2_neighbor = dot(vmax_neighbor, vmax_neighbor);

            if (magnitude2_neighbor > largestMagnitude2) {

                // Non-unit
                vec2 directionToNeighbor = vec2(offset);

                // Non-unit
                vec2 directionOfVelocity = vmax_neighbor;

                // Cosine of the angle between the neighbor's velocity and the direction to the tile.
                // Note that both vectors are arbitrarily oriented along lines, so we take the absolute 
                // value.
                //
                // Note that the denominator is nonzero or we wouldn't be in this branch, so
                // the division is safe. 
                float cosAngle = abs(dot(directionOfVelocity, directionToNeighbor) /  
                                    sqrt(magnitude2_neighbor * dot(directionToNeighbor, directionToNeighbor)));

                const float cos45 = sqrt(2.0) / 2.0;

                // Can the neighbor affect this tile?
                if (cosAngle >= cos45) {
                    // This is the new largest PSF in the neighborhood
                    m = vmax_neighbor;
                    largestMagnitude2 = magnitude2_neighbor;
                }
            }
        }
    }


    vec2 neighborMax = m * writeScaleBias.x + writeScaleBias.y;
    gl_FragColor = vec4(neighborMax, 0.0, 1.0);
}
