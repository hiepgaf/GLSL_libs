varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform vec2 samplerSteps;
uniform float stride;
uniform float intensity;

varying vec2 coords[8];

void main()
{
	vec3 colors[8];

	for(int i = 0; i < 8; ++i)
	{
		colors[i] = texture2D(inputImageTexture, coords[i]).rgb;
	}

	vec4 src = texture2D(inputImageTexture, textureCoordinate);

	vec3 h = -colors[0] - 2.0 * colors[1] - colors[2] + colors[5] + 2.0 * colors[6] + colors[7];
	vec3 v = -colors[0] + colors[2] - 2.0 * colors[3] + 2.0 * colors[4] - colors[5] + colors[7];

	gl_FragColor = vec4(mix(src.rgb, sqrt(h * h + v * v), intensity), 1.0);
}