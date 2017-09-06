varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D blurTexture;
uniform mat4 compositeMatrix;

uniform float shadows;
uniform float highlights;
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

void main() {
  vec4 col = texture2D(texture, coord.xy);

	vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec3 base = col.rgb;
  vec3 color = texture2D(blurTexture, distort(compositeCoords.xy, distortion_amount, imgSize)).rgb;

	float amt = mix(highlights, shadows, 1.0 - Lum(color)) * col.a;

	if (amt < 0.0) amt *= 2.0;

	// exposure
	vec3 res = mix(base, vec3(1.0), amt);
  vec3 blend = mix(vec3(1.0), pow(base, vec3(1.0/0.7)), amt);
  res = max(1.0 - ((1.0 - res) / blend), 0.0);
	res = SetLum(SetSat(base, Sat(res)), Lum(res));

	gl_FragColor = vec4(res, col.a);
}