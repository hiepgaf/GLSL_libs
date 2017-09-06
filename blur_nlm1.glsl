varying vec4 coord;

uniform sampler2D texture;
uniform vec2 delta;

float sigma2_color = 25.0;
float random(vec3 scale, float seed) {
  /* use the fragment position for a different seed per-pixel */
  return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}
float Lum(vec3 c){
  return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}

void main() {

  vec3 center_color = texture2D(texture, coord.xy).rgb;
  vec3 color = center_color;
  float total = 1.0;
  float center_lum = Lum(center_color);

  /* randomize the lookup values to hide the fixed number of samples */
  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);

  for (float t = -20.0; t <= 20.0; t++) {
    float percent = (t + offset - 0.5) / 20.0;
    float weight = 1.0 - abs(percent);
    vec3 tmp_color = texture2D(texture, coord.xy + delta * percent).rgb;
    float diff_color=Lum(tmp_color)-center_lum;
    weight *= exp(-min(diff_color*diff_color*sigma2_color,10.0));
    color += tmp_color * weight;
    total += weight;
  }

  vec4 res = vec4(color/total, total/20.0);
  gl_FragColor = clamp(res,0.0,1.0);
}