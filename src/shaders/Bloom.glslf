precision highp float;

uniform sampler2D base;
uniform sampler2D level0;
uniform sampler2D level1;
uniform sampler2D level2;
uniform sampler2D level3;
uniform sampler2D level4;

uniform vec2 resolution;
uniform float boost;
uniform float reduction;
uniform float levels;
uniform float time;
uniform float amount;

varying vec2 vUv;

#define FXAA_SPAN_MAX 8.0
#define FXAA_REDUCE_MUL   (1.0/FXAA_SPAN_MAX)
#define FXAA_REDUCE_MIN   (1.0/128.0)
#define FXAA_SUBPIX_SHIFT (1.0/4.0)
vec3 FxaaPixelShader( vec4 uv, sampler2D tex, vec2 rcpFrame) {
    vec3 rgbNW = texture2D(tex, uv.zw ).xyz;
    vec3 rgbNE = texture2D(tex, uv.zw + vec2(1,0)*rcpFrame.xy ).xyz;
    vec3 rgbSW = texture2D(tex, uv.zw + vec2(0,1)*rcpFrame.xy ).xyz;
    vec3 rgbSE = texture2D(tex, uv.zw + vec2(1,1)*rcpFrame.xy ).xyz;
    vec3 rgbM  = texture2D(tex, uv.xy ).xyz;
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          dir * rcpDirMin)) * rcpFrame.xy;
    vec3 rgbA = (1.0/2.0) * (
        texture2D(tex, uv.xy + dir * (1.0/3.0 - 0.5) ).xyz +
        texture2D(tex, uv.xy + dir * (2.0/3.0 - 0.5) ).xyz);
    vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        texture2D(tex, uv.xy + dir * (0.0/3.0 - 0.5) ).xyz +
        texture2D(tex, uv.xy + dir * (3.0/3.0 - 0.5) ).xyz);
    float lumaB = dot(rgbB, luma);
    if((lumaB < lumaMin) || (lumaB > lumaMax)) return rgbA;
    return rgbB;
}

float random(vec2 n, float offset ){
	return .5 - fract(sin(dot(n.xy + vec2( offset, 0. ), vec2(12.9898, 78.233)))* 43758.5453);
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

void main() {
	vec2 res = 1. / resolution;
	vec2 uv = vUv;
	vec4 aauv = vec4( uv, uv - (res * (0.5 + FXAA_SUBPIX_SHIFT)));
	vec4 color = vec4(FxaaPixelShader( aauv, base, res ),1.);

	if( levels > 0. ) color += 1. * texture2D( level0, vUv );
	if( levels > 1. ) color += 1.2 * texture2D( level1, vUv );
	if( levels > 2. ) color += 1.4 * texture2D( level2, vUv );
	if( levels > 3. ) color += 1.6 * texture2D( level3, vUv );
	if( levels > 4. ) color += 1.8 * texture2D( level4, vUv );

	vec2 position = vUv - .5;
	float vignette = length( position );
    vignette = boost - vignette * reduction;

 	color += vec4( vec3( amount * random( vUv, time ) ), 1. );
    color.rgb *= vignette;

	gl_FragColor = color;
	//gl_FragColor = vec4(luma(color));
}