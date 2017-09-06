varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D denoiseTexture;
uniform vec2 textureResolution;
uniform float color_denoise;
uniform float luminance_denoise;
uniform float distortion_amount;
uniform mat4 compositeMatrix;

vec2 distort(vec2 coord, float amount, vec2 size) {
  float f = 1.0;
  float zoom = 1.0;
  vec2 center = vec2(0.5);
  if(amount < 0.0){
      float correction = sqrt(size.x*size.x+size.y*size.y)/(amount*-4.0);
      float nx = (coord.x - center.x) * size.x;
      float ny = (coord.y - center.y) * size.y;
      float d = sqrt(nx*nx+ny*ny);
      float r = d/correction;
      if(r != 0.0){
          f = atan(r)/r;
      }
      r = max(-0.5 * size.x, -0.5 * size.y) / correction;
      zoom = atan(r)/r;

  }else{
      float size = 0.75;
      float r2 = (coord.x-center.x) * (coord.x-center.x) + (coord.y-center.y) * (coord.y-center.y);
      r2 = r2 * size * size;
      f = 1.0 + r2 * amount * 2.0;
      zoom = 1.0 + (0.5 * size * size) * amount * 2.0;
  }
  return f * (coord - center) / zoom + center;
}

float Lum(vec3 c){
  return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}

vec3 ClipColor(vec3 c){
  float l = Lum(c);
  float n = min(min(c.r, c.g), c.b);
  float x = max(max(c.r, c.g), c.b);

  if (n < 0.0) c = (c-l)*l / (l-n) + l;
  if (x > 1.0) c = (c-l) * (1.0-l) / (x-l) + l;

  return c;
}

vec3 SetLum(vec3 c, float l){
  float d = l - Lum(c);

  c.r = c.r + d;
  c.g = c.g + d;
  c.b = c.b + d;

  return ClipColor(c);
}

void main() {

	vec3 base = texture2D(texture, coord.xy).rgb;
	vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec4 map = texture2D(denoiseTexture, distort(compositeCoords.xy, distortion_amount, textureResolution));

  float luminance_blend = max(luminance_denoise - map.a/2.0, 0.0);

  vec3 res = mix(base, SetLum(map.rgb, Lum(base)), color_denoise);
  res = mix(res, SetLum(res, Lum(map.rgb)), luminance_blend);
  
  gl_FragColor = vec4(res, 1.0);
}