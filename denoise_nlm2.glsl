 varying vec4 coord;

uniform sampler2D texture;
uniform vec2 textureResolution;

const float sigma_color = 0.03;

float random(vec3 scale, float seed) {
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}
float Lum(vec3 c){
  return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}
void main() {
  vec2 sigma_spatial = 1.0 / (textureResolution / 2.0);
  float wsize = 9.0;
  float res_weight = 0.0;
  vec3 res_color = vec3(0.0);
  vec3 center_color = texture2D(texture, coord.xy).rgb;
  float sigma_i = 0.5 * wsize * wsize * sigma_spatial.x * sigma_spatial.y;
  vec2 step = vec2(0.9,-1.0);
  float offset1 = random(vec3(12.9898, 78.233, 151.7182), 0.0);
  float offset2 = random(vec3(112.9898, 178.233, 51.7182), 0.0);
  for (float i = -4.0; i <= 4.0; i++) {    
      vec2 uv_sample = coord.xy + vec2(offset1-0.5, i+offset2-0.5) * sigma_spatial;
      vec3 tmp_color = texture2D(texture, uv_sample).rgb;
      float pre_weight = texture2D(texture, uv_sample).a;
      /*vec3 diff_color = tmp_color - center_color;*/
      float diff_color = Lum(tmp_color)-Lum(center_color);
      float tmp_weight = exp(-(i*i)*sigma_i);
/*      tmp_weight *= exp(-(dot(diff_color,diff_color)/2.0/sigma_color/sigma_color));*/
      tmp_weight *= exp(-min(diff_color*diff_color/2.0/sigma_color/sigma_color,10.0));      
      res_color += tmp_color * tmp_weight * pre_weight * 10.0;
      res_weight += tmp_weight * pre_weight * 10.0;
  }
  gl_FragColor = vec4(res_color / res_weight, (1.0 / res_weight) * 2.0);
}