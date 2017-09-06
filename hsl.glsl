varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D map;

vec3 RGBToHSL(vec3 color)
{
  vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
  
  float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
  float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
  float delta = fmax - fmin;             //Delta RGB value

  hsl.z = (fmax + fmin) / 2.0; // Luminance

  if (delta == 0.0)   //This is a gray, no chroma...
  {
    hsl.x = 0.0;  // Hue
    hsl.y = 0.0;  // Saturation
  }
  else                                    //Chromatic data...
  {
    if (hsl.z < 0.5)
      hsl.y = delta / (fmax + fmin); // Saturation
    else
      hsl.y = delta / (2.0 - fmax - fmin); // Saturation
    
    float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
    float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
    float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

    if (color.r == fmax )
      hsl.x = deltaB - deltaG; // Hue
    else if (color.g == fmax)
      hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
    else if (color.b == fmax)
      hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

    if (hsl.x < 0.0)
      hsl.x += 1.0; // Hue
    else if (hsl.x > 1.0)
      hsl.x -= 1.0; // Hue
  }

  return clamp(hsl,0.0,1.0);
}

float HueToRGB(float f1, float f2, float hue)
{
  if (hue < 0.0)
    hue += 1.0;
  else if (hue > 1.0)
    hue -= 1.0;
  float res;
  if ((6.0 * hue) < 1.0)
    res = f1 + (f2 - f1) * 6.0 * hue;
  else if ((2.0 * hue) < 1.0)
    res = f2;
  else if ((3.0 * hue) < 2.0)
    res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
  else
    res = f1;
  return res;
}

vec3 HSLToRGB(vec3 hsl)
{
  vec3 rgb;
  
  if (hsl.y == 0.0)
    rgb = vec3(hsl.z); // Luminance
  else
  {
    float f2;
    
    if (hsl.z < 0.5)
      f2 = hsl.z * (1.0 + hsl.y);
    else
      f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
      
    float f1 = 2.0 * hsl.z - f2;
    
    rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
    rgb.g = HueToRGB(f1, f2, hsl.x);
    rgb.b = HueToRGB(f1, f2, hsl.x - (1.0/3.0));
  }
  
  return rgb;
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

  vec3 color = texture2D(texture, coord.xy).rgb;
  vec3 hsl = RGBToHSL(color);
  vec3 hslMap = texture2D(map, vec2(hsl.x)).xyz;

    vec3 rgb = HSLToRGB(vec3(
      hsl.x - ((1.0 - hslMap.x*2.0)*60.0)/360.0,
      hsl.y * (hslMap.y*2.0),
      hsl.z// + (hslMap.z - 0.5)*hsl.y*0.5
    ));

    float lum = Lum(color);
    rgb = SetLum(rgb, lum + (hslMap.z - 0.5) * (hsl.y*(1.0-lum)*4.0) * lum*lum);

  gl_FragColor = vec4(rgb, 1.0);
  
}