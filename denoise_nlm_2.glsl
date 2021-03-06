varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D blurTexture;
uniform vec2 textureResolution;

const float sigma_color = 0.1;

float random(vec3 scale, float seed) {
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

void main() {
  vec2 sigma_spatial = 1.0 / textureResolution * 4.0;
  float wsize = 7.0;
  float res_weight = 0.0;
  vec3 res_color = vec3(0.0);
  vec3 center_color = texture2D(texture, coord.xy).rgb;
  float sigma_i = 0.5 * wsize * wsize * sigma_spatial.x * sigma_spatial.y;
  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);
  float offset2 = random(vec3(112.9898, 178.233, 51.7182), 0.0);
  for (float i = -7.0; i <= 7.0; i++) {
    for (float j = -7.0; j <= 7.0; j++) {
      vec2 uv_sample = coord.xy + vec2(i+offset-0.5, j+offset2-0.5) * sigma_spatial;
      vec3 tmp_color = texture2D(texture, uv_sample).rgb;
      vec3 weight_color = texture2D(blurTexture, uv_sample).rgb;
      vec3 diff_color = weight_color - center_color;
      float tmp_weight = exp(-(i*i+j*j)*sigma_i);
      tmp_weight *= exp(-(dot(diff_color,diff_color)/2.0/sigma_color/sigma_color));
      res_color += tmp_color * tmp_weight;
      res_weight += tmp_weight;
    }
  }
  gl_FragColor = vec4(res_color / res_weight, (1.0 / res_weight));
}