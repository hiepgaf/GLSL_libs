varying vec4 coord;

uniform sampler2D texture;

void main() {
	gl_FragColor = texture2D(texture, coord.xy);
}", c.blur = "varying vec4 coord;

uniform sampler2D texture;
uniform vec2 delta;

float random(vec3 scale, float seed) {
  /* use the fragment position for a different seed per-pixel */
  return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

void main() {

  vec4 color = vec4(0.0);
  float total = 0.0;

  /* randomize the lookup values to hide the fixed number of samples */
  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);

  for (float t = -20.0; t <= 20.0; t++) {
    float percent = (t + offset - 0.5) / 20.0;
    float weight = 1.0 - abs(percent);
    color += texture2D(texture, coord.xy + delta * percent) * weight;
    total += weight;
  }

  gl_FragColor = color / total;
}