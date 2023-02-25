#version 300 es
precision highp float;
precision highp usampler2D;
uniform mat4 modelMatrix;

uniform usampler2D posWF;
uniform usampler2D posWFPrev;
uniform usampler2D posPrev;
uniform usampler2D posPrevPrev;
uniform mat4 viewMat;

uniform vec3 attractor0;
uniform vec3 pAttractor0;

uniform vec3 attractor1;
uniform vec3 pAttractor1;

uniform vec3 attractor2;
uniform vec3 pAttractor2;

uniform float globalScale;

uniform vec2 res;
uniform float decay;
uniform float drag;

uniform float time;

in vec3 vPos;

layout(location = 0) out highp uvec4 fragColor;


void main() {
    vec4 floatFragColor;
    vec2 uv = gl_FragCoord.xy / res;
    float vLife = uintBitsToFloat(texture(posWF, uv).a);
    vec3 positionWF = globalScale * uintBitsToFloat(texture(posWF, uv).xyz);
    vec3 positionWFPrev = globalScale * uintBitsToFloat(texture(posWFPrev, uv).xyz);
    vec3 positionPrev = uintBitsToFloat(texture(posPrev, uv).xyz);
    vec3 positionPrevPrev = uintBitsToFloat(texture(posPrevPrev, uv).xyz);

    if (vLife > 98.0)
    {
        floatFragColor = vec4(positionWF, vLife);
    }
    else
    {
        float k = 13.0;

        vec3 attractor, pAttractor;
        vec4 vA, vpA, vPP;

        float l0 = length(attractor0 - pAttractor0) > 0.001? length(attractor0 - positionPrev) : 0.0;
        float l1 = length(attractor1 - pAttractor1) > 0.001? length(attractor1 - positionPrev) : 0.0;
        float l2 = length(attractor2 - pAttractor2) > 0.001? length(attractor2 - positionPrev) : 0.0;

        float minL = min(min(l0, l1), l2);

        if (minL == l0)
        {
            attractor = attractor0;
            pAttractor = pAttractor0;
        }
        else if (minL == l1)
        {
            attractor = attractor1;
            pAttractor = pAttractor1;
        }
        else if(minL == l2)
        {
            attractor = attractor2;
            pAttractor = pAttractor2;
        }

        if (minL == 0.0)
        {
            attractor = positionPrev.xyz;
            pAttractor = positionPrev.xyz;
        }

        vA = viewMat * vec4(attractor, 1.0);
        vpA = viewMat * vec4(pAttractor, 1.0);
        vPP = viewMat * vec4(positionPrev, 1.0);

    
        //insted of .xy shoud be projection on plane
        float att = length(vA.xy - vPP.xy) * step(0.1, length(vA.xy - vPP.xy));//clamp(length(attractor.xy - positionPrev.xy), 10.0, 2000.0);

        att = max(10.0, att);
        vec3 acc;
        if (length(vA.xy - vPP.xy) > 0.1)
            acc = - k * (positionPrev - positionWFPrev) + 25500.0 * (1.0 - step(globalScale * 55.0, att)) * normalize(attractor - pAttractor) * clamp(length(attractor - pAttractor), 0.0, 2.9 ) / (att ) ;
        else
            acc = - k * (positionPrev - positionWFPrev);


        //acc = clamp()

        float fr = 0.12;

        vec3 allowedDelta = globalScale * vec3(60.0, 60.0, 60.0);

        acc = clamp(acc, -vec3(2760.0, 2760.0, 2760.0), vec3(2760.0, 2760.0, 2760.0));
        vec3 finalPosition = clamp((2.0 - fr) * positionPrev - (1.0 - fr) * positionPrevPrev + acc * (1.0/60.0) * (1.0 / 60.0), positionWF - allowedDelta, positionWF + allowedDelta);
        if (length(acc) < 0.5)
            finalPosition = positionWF;

        if (drag > 0.9)
            vLife += decay;



        floatFragColor = vec4(finalPosition, vLife);
    }
    fragColor = floatBitsToUint(floatFragColor);
}