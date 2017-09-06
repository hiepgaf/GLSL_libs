uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;
uniform vec2 samplerSteps;
uniform float stride;
uniform float intensity;
uniform vec2 norm;

void main() {
  vec4 src = texture2D(inputImageTexture, textureCoordinate);
  vec3 tmp = texture2D(inputImageTexture, textureCoordinate + samplerSteps * stride * norm).rgb - src.rgb + 0.5;
  float f = (tmp.r + tmp.g + tmp.b) / 3.0;
  gl_FragColor = vec4(mix(src.rgb, vec3(f, f, f), intensity), src.a);
}