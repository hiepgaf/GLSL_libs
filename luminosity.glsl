precision highp float;

uniform sampler2D inputImageTexture;

varying highp vec2 outputTextureCoordinate;

varying highp vec2 upperLeftInputTextureCoordinate;
varying highp vec2 upperRightInputTextureCoordinate;
varying highp vec2 lowerLeftInputTextureCoordinate;
varying highp vec2 lowerRightInputTextureCoordinate;

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    highp float upperLeftLuminance = dot(texture2D(inputImageTexture, upperLeftInputTextureCoordinate).rgb, W);
    highp float upperRightLuminance = dot(texture2D(inputImageTexture, upperRightInputTextureCoordinate).rgb, W);
    highp float lowerLeftLuminance = dot(texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).rgb, W);
    highp float lowerRightLuminance = dot(texture2D(inputImageTexture, lowerRightInputTextureCoordinate).rgb, W);

    highp float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
    gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
}