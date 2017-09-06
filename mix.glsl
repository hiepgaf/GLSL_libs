varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D original;
uniform float blend;
uniform mat4 compositeMatrix;

void main() {
  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec4 orig = texture2D(original, compositeCoords.xy);
  vec4 col = mix(texture2D(texture, coord.xy), orig, blend);

	gl_FragColor = vec4(col.rgb, orig.a);

}