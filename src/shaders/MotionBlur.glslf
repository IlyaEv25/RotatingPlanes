// m_exposureFraction(0.75f), 
//     m_cameraMotionInfluence(0.5f),
//     m_maxBlurDiameterFraction(0.10f),
//     m_numSamples(27) {}

#define maxBlurRadius 20
#define numSamplesOdd 25


uniform vec2      readScaleBias;

/** Unprocessed differences between previous and current frame in screen space */
uniform sampler2D   u_velocity;

/** Uses the same encoding as SS_POSITION_CHANGE */
uniform sampler2D   u_neighbour;

uniform sampler2D   u_color;

/** Typical hyperbolic depth buffer: close values are greater than distant values */
uniform sampler2D   u_depth;

/** Amount on [-0.5, 0.5] to randomly perturb samples by at each pixel */
//vec2              jitter;

/** 32x32 tiled random numbers */
uniform sampler2D   randomBuffer;

/** In fraction of frame duration */
uniform float       exposureTime;

// Expects macro maxBlurRadius

/* Measured in pixels
   Make this smaller to better hide tile boundaries
   Make this bigger to get smoother blur (less noise) */
#define varianceThreshold 1.5//3.0//23.5//1.5

const int S = numSamplesOdd;


//sout float3 resultColor

// Constant indicating locations wme we clamp against the minimum PSF, 1/2 pixel
const float HALF_PIX = 0.5;

float saturate(float r)
{
    return clamp(r, 0.0, 1.0);
}

float lerp(float start, float end, float t) {
    return start * (1.0 - t) + end * t;
}

/** Computes a pseudo-random number on [0, 1] from pixel position c. */
float hash(ivec2 c) {
#   if numSamplesOdd <= 5
	    // Use a simple checkerboard if you have very few samples; this gives too much ghosting 
        // for many scenes, however
        return float(int(c.x + c.y) & 1) * 0.5 + 0.25;
#   else
        return texelFetch(randomBuffer, ivec2(c.x & 31, c.y & 31), 0).r;
#   endif
}


/** Called from readAdjustedVelocity() and readAdjustedNeighborhoodVelocity() */
vec2 readAdjustedVelocity(ivec2 C, sampler2D tex, out float r) {
    vec2 q = texelFetch(tex, C, 0).xy * readScaleBias.x + readScaleBias.y;

    float lenq = length(q);

    // Convert the velocity to be a radius instead of a diameter, and scale it by
	// the 
    r = lenq * exposureTime * 0.5;
    bool rIsSmall = (r < 0.01);	
	r = clamp(r, HALF_PIX, float(maxBlurRadius));
	
    if (! rIsSmall) {
        // Adjust q's length based on the newly clamped radius
        return q * (r / lenq);
    } else {
        return q;
    }
}

/** 
  V[C] in the paper.

  v = half-velocity vector 
  r = magnitude of v
*/
vec2 readAdjustedVelocity(ivec2 C, out float r) {
    return readAdjustedVelocity(C, u_velocity, r);
}

/** NeighborMax[C] from the paper */
vec2 readAdjustedNeighborhoodVelocity(ivec2 C, out float r) {
    return readAdjustedVelocity(ivec2(C / maxBlurRadius), u_neighbour, r);
}

float cone(float dist, float r) {
    return saturate(1.0 - abs(dist) / r);
}


float fastCone(float dist, float invR) {
    return saturate(1.0 - abs(dist) * invR);
}

// A cone filter with maximum weight 1 at dist = 0 and min weight 0 at |v|=dist.
float cylinder(float dist, float r) {
    //return 1.0 - smoothstep(r * 0.95, r * 1.05, abs(dist));

    // Alternative: (marginally faster on GeForce, comparable quality)
    return sign(r - abs(dist)) * 0.5 + 0.5;

    // The following gives nearly identical results and may be faster on some hardware,
    // but is slower on GeForce
    //    return (abs(dist) <= r) ? 1.0 : 0.0;
}


/** 0 if depth_A << depth_B, 1 if depth_A >> z_depth, fades between when they are close */
float softDepthCompare(float depth_A, float depth_B) {
    // World space distance over which we are conservative about the classification
    // of "foreground" vs. "background".  Must be > 0.  
    // Increase if slanted surfaces aren't blurring enough.
    // Decrease if the background is bleeding into the foreground.
    // Fairly insensitive
    const float SOFT_DEPTH_EXTENT = 0.01;//0.02;

    return clamp(1.0 - (depth_B - depth_A) / SOFT_DEPTH_EXTENT, 0.0, 1.0);
}

// For linear Z values where more negative = farther away from camera
float softZCompare(float z_A, float z_B) {
    // World space distance over which we are conservative about the classification
    // of "foreground" vs. "background".  Must be > 0.  
    // Increase if slanted surfaces aren't blurring enough.
    // Decrease if the background is bleeding into the foreground.
    // Fairly insensitive
    const float SOFT_Z_EXTENT = 0.1;

    return clamp(1.0 - (z_A - z_B) / SOFT_Z_EXTENT, 0.0, 1.0);
}


void main() {
    // Size of the screen
    ivec2 SCREEN_MAX = textureSize(u_color, 0).xy - ivec2(1);

    // Center pixel
    ivec2 me       = ivec2(gl_FragCoord.xy);

    // A pseudo-random number on [-0.5, 0.5]
    float jitter = hash(me) - 0.5;

    vec3 resultColor  = texelFetch(u_color, me, 0).rgb;

    float depth_center = texelFetch(u_depth, me, 0).x;
    
    // Compute the maximum PSF in the neighborhood
    float r_neighborhood;
    vec2 v_neighborhood  = readAdjustedNeighborhoodVelocity(me, r_neighborhood);

    if (r_neighborhood <= 0.5) {
        // other's no blurring at all in this pixel's neighborhood, since the maximum
        // velocity is less than one pixel.
        gl_FragColor = vec4(resultColor, 1.0);
        return;
    }

    // Compute PSF at me (this pixel)
    float  radius_center;
    vec2 velocity_center = readAdjustedVelocity(me, radius_center);

    // Let w be a velocity direction (i.e., w is "omega", a unit vector in screen-space)
    // Let r be a half-velocity magnitude (i.e., a point-spread function radius)

    vec2 w_neighborhood = normalize(v_neighborhood);
    // Choose the direction at this pixel to be the same as w_neighborhood if this pixel is not itself moving
    vec2 w_center = (radius_center < varianceThreshold) ? w_neighborhood : normalize(velocity_center);

    // Accumulated color; start with the center sample
    // Higher initial weight increases the ability of the background
    // to overcome the out-blurred part of moving objects
    float invRadius_center = 1.0 / radius_center; 
    float totalCoverage = (float(S) / 40.0) * invRadius_center;
    resultColor *= totalCoverage;


    // Sample along the largest PSF vector in the neighborhood  
    for (int i = 0; i < S; ++i) {

        // Ignore the center sample.
        // The loop is deterministic and will be unrolled
        // so it doesn't matter that other's a "branch" here... 
        // and it would be perfectly coment anyway.
        if (i == S / 2) { continue; }

        // Signed step distance from X to Y.
        // Because cone(r_Y) = 0, we need this to never reach +/- r_neighborhood, even with jitter
#if (numSamplesOdd <= 5)
            // For small sample counts, use broader sample range; it produces better
            // noise characteristics empirically
            float t = lerp(-1.0, 1.0, (float(i) + 1.5 + jitter * 2.0) / (float(S) + 2.0));
#else
            float t = lerp(-1.0, 1.0, (float(i) + 1.0 + jitter) / (float(S) + 1.0));
#endif

        float dist = t * r_neighborhood;

        vec2 offset =
            // Alternate between the neighborhood direction and this pixel's direction.
            // This significantly helps avoid tile boundary problems when other are
            // two large velocities in a tile.
            dist * (((i & 1) == 1) ? w_neighborhood : w_center);  
        
        // Point being considered; offset and round to the nearest pixel center.
        // Then, clamp to the screen bounds
        ivec2 other = clamp(ivec2(offset + vec2(me) + vec2(0.5)), ivec2(0), SCREEN_MAX);

        float depth_sample = texelFetch(u_depth, other, 0).x;

        float radius_sample;

        // The actual velocity_sample vector will be ignored by the code below,
        // but the magnitude (radius_sample) of the blur is used.
        vec2 velocity_sample = readAdjustedVelocity(other, radius_sample);
        vec3 color_sample    = texelFetch(u_color, other, 0).rgb;

        // Relative contribution of other to me
        float coverage_sample = 0.0;

        // is other in the foreground or background of me?
        float inFront = softDepthCompare(depth_center, depth_sample);
        float inBack  = softDepthCompare(depth_sample, depth_center);

        // Blurry other over any me
        coverage_sample += inFront * cone(dist, radius_sample);

        // Blurry me, estimate background
        coverage_sample += inBack * fastCone(dist, invRadius_center);

        // Mutually blurry me and other
        coverage_sample += cylinder(dist, radius_center) * cylinder(dist, radius_sample) * 2.0;

        // Accumulate (with premultiplied coverage)
        totalCoverage += coverage_sample;
        resultColor   += color_sample * coverage_sample;
    }

    // We never divide by zero because we always sample the pixel itself.
    resultColor /= (totalCoverage + 0.02);
    gl_FragColor = vec4(resultColor, 1.0);
}
