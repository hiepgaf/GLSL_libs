varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D blurTexture;
uniform mat4 compositeMatrix;

uniform float clarity;
uniform float distortion_amount;
uniform vec2 imgSize;

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

// Luminance and Saturation functions
// Adapted from: http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/pdf/pdfs/PDF32000_2008.pdf

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

float Sat(vec3 c){
  float n = min(min(c.r, c.g), c.b);
  float x = max(max(c.r, c.g), c.b);

  return x - n;
}

vec3 SetSat(vec3 c, float s){
  float cmin = min(min(c.r, c.g), c.b);
  float cmax = max(max(c.r, c.g), c.b);

  vec3 res = vec3(0.0);

  if (cmax > cmin) {

    if (c.r == cmin && c.b == cmax) { // R min G mid B max
      res.r = 0.0;
      res.g = ((c.g-cmin)*s) / (cmax-cmin);
      res.b = s;
    }
    else if (c.r == cmin && c.g == cmax) { // R min B mid G max
      res.r = 0.0;
      res.b = ((c.b-cmin)*s) / (cmax-cmin);
      res.g = s;
    }
    else if (c.g == cmin && c.b == cmax) { // G min R mid B max
      res.g = 0.0;
      res.r = ((c.r-cmin)*s) / (cmax-cmin);
      res.b = s;
    }
    else if (c.g == cmin && c.r == cmax) { // G min B mid R max
      res.g = 0.0;
      res.b = ((c.b-cmin)*s) / (cmax-cmin);
      res.r = s;
    }
    else if (c.b == cmin && c.r == cmax) { // B min G mid R max
      res.b = 0.0;
      res.g = ((c.g-cmin)*s) / (cmax-cmin);
      res.r = s;
    }
    else { // B min R mid G max
      res.b = 0.0;
      res.r = ((c.r-cmin)*s) / (cmax-cmin);
      res.g = s;
    }

  }

  return res;
}

float BlendOverlayf(float base, float blend){
  return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
}

vec3 BlendOverlay(vec3 base, vec3 blend){
  return vec3(BlendOverlayf(base.r, blend.r), BlendOverlayf(base.g, blend.g), BlendOverlayf(base.b, blend.b));
}

float BlendVividLightf(float base, float blend){
  float BlendColorBurnf = (((2.0 * blend) == 0.0) ? (2.0 * blend) : max((1.0 - ((1.0 - base) / (2.0 * blend))), 0.0));
  float BlendColorDodgef =  (((2.0 * (blend - 0.5)) == 1.0) ? (2.0 * (blend - 0.5)) : min(base / (1.0 - (2.0 * (blend - 0.5))), 1.0));
  return ((blend < 0.5) ? BlendColorBurnf : BlendColorDodgef);
}

vec3 BlendVividLight(vec3 base, vec3 blend){
  return vec3(BlendVividLightf(base.r, blend.r), BlendVividLightf(base.g, blend.g), BlendVividLightf(base.b, blend.b));
}

void main() {
  vec4 col = texture2D(texture, coord.xy);

  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec3 color = col.rgb;
  vec3 overlay = texture2D(blurTexture, distort(compositeCoords.xy, distortion_amount, imgSize)).rgb;

  float intensity = (clarity < 0.0) ? clarity / 2.0 : clarity * 2.0;
  intensity *= col.a;
  float lum = Lum(color);

  vec3 base = vec3(lum);
  vec3 mask = vec3(1.0 - pow(lum, 1.8));
  // invert blurred texture
  vec3 layer = vec3(1.0 - Lum(overlay));
  vec3 detail = clamp(BlendVividLight(base, layer), 0.0, 1.0);
  // we get negative detail by inverting the detail layer
  vec3 inverse = mix(1.0 - detail, detail, (intensity+1.0)/2.0);
  vec3 blend = BlendOverlay(color, mix(vec3(0.5), inverse, mask));

  gl_FragColor = vec4(SetLum(SetSat(color, Sat(blend)), Lum(blend)), col.a);

}