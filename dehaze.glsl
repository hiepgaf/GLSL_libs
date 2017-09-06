// fragment_dehaze.cpp
// usage: use during rendering, correct dehazing using transition map
// input: uniform sampler2D texture (loaded image)
// input: uniform sampler2D map_t (generated from shader dehazemap2.cpp)
// input: uniform float dehaze_scale from -1.0 to 1.0
// output: dehazed image
// ref: http://research.microsoft.com/en-us/um/people/jiansun/papers/dehaze_cvpr2009.pdf
// https://www.shadertoy.com/view/4tXXz4


varying vec4 coord;
uniform sampler2D texture;
uniform sampler2D map_t;

uniform float dehaze; /*-1.0~1.0 */
uniform vec3 average;

uniform mat4 compositeMatrix;
uniform float distortion_amount;
uniform vec2 imgSize;

float Lum(vec3 c){
  return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}

vec3 ClipColor(vec3 c){
  float l = Lum(c);
  float n = min(min(c.r, c.g), c.b);
  float x = max(max(c.r, c.g), c.b);

  if (n < 0.0) c = max((c-l)*l / (l-n) + l, 0.0);
  if (x > 1.0) c = min((c-l) * (1.0-l) / (x-l) + l, 1.0);

  return c;
}

vec3 SetLum(vec3 c, float l){
  c += l - Lum(c);

  return ClipColor(c);
}

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


const float mix_scale = 0.5;

void main() {
    vec3 color_A = vec3(1.0);
    vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
	  /*rgb*/
    vec3 base = texture2D(texture,coord.xy).rgb;
    /*transmission*/
    float res_t = texture2D(map_t, distort(compositeCoords.xy, distortion_amount, imgSize)).a;
    /*correction*/
    color_A = mix(color_A, average, mix_scale);
    float dehaze_adjust = clamp(1.0/res_t,1.0,5.0)-1.0;
    dehaze_adjust = float(dehaze_adjust<1.0)*dehaze_adjust+float(dehaze_adjust>=1.0)*pow(dehaze_adjust,0.2);
    dehaze_adjust = dehaze_adjust+1.0;
    vec3 J = clamp(((base-color_A)*dehaze_adjust+color_A),0.0,1.0);


    //dehaze (-1,1)->d(0,1)
    float d = 1.0 - dehaze;
    float mixv = pow(res_t,d);
    vec3 result = mix(color_A,J,mixv);
    
    // vec3 res_lum = SetLum(base, Lum(result));
    // result = mix(result, res_lum, 0.5);

    /*mix*/
    //vec3 res_out=mix(base,result,0.5);
	  gl_FragColor = vec4(result,1.0);
}