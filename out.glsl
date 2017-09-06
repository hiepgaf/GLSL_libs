varying vec4 coord;

uniform sampler2D texture;

void main() {
  vec4 col = texture2D(texture, coord.xy);

	gl_FragColor = col;
}