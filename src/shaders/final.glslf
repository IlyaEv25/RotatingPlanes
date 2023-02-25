uniform sampler2D u_color;
uniform float toneMappingExposure;

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	//color = pow(color, vec3(1. / gamma));
	return color;
}

varying vec2 vUv;

void main()
{
    vec4 color = texture(u_color, vUv);
    color.rgb = Uncharted2ToneMapping(toneMappingExposure * color.rgb);
    gl_FragColor = LinearTosRGB(color);
}