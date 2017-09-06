varying vec4 coord;

uniform sampler2D texture;
uniform float opacity;

void main() {
  vec4 col = texture2D(texture, coord.xy);
  col.a *= opacity;

	gl_FragColor = col;

}