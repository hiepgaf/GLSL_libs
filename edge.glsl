varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform vec2 samplerSteps;
uniform float stride;
uniform float intensity;
uniform vec2 norm;

void main()
{
	vec4 src = texture2D(inputImageTexture, textureCoordinate);
	vec3 tmpColor = texture2D(inputImageTexture, textureCoordinate + samplerSteps * stride * norm).rgb;
	tmpColor = abs(src.rgb - tmpColor) * 2.0;
	gl_FragColor = vec4(mix(src.rgb, tmpColor, intensity), src.a);
}
);

CGEConstString s_vshEdgeSobel = CGE_SHADER_STRING
(
attribute vec2 vPosition;
varying vec2 textureCoordinate;
varying vec2 coords[8];

uniform vec2 samplerSteps;
uniform float stride;

void main()
{
	gl_Position = vec4(vPosition, 0.0, 1.0);
	textureCoordinate = (vPosition.xy + 1.0) / 2.0;

	coords[0] = textureCoordinate - samplerSteps * stride;
	coords[1] = textureCoordinate + vec2(0.0, -samplerSteps.y) * stride;
	coords[2] = textureCoordinate + vec2(samplerSteps.x, -samplerSteps.y) * stride;

	coords[3] = textureCoordinate - vec2(samplerSteps.x, 0.0) * stride;
	coords[4] = textureCoordinate + vec2(samplerSteps.x, 0.0) * stride;

	coords[5] = textureCoordinate + vec2(-samplerSteps.x, samplerSteps.y) * stride;
	coords[6] = textureCoordinate + vec2(0.0, samplerSteps.y) * stride;
	coords[7] = textureCoordinate + vec2(samplerSteps.x, samplerSteps.y) * stride;

}