varying vec4 coord;

uniform sampler2D texture;
uniform float exposure;
uniform float gamma;

// Luminance and Saturation functions
// Adapted from: http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/pdf/pdfs/PDF32000_2008.pdf

float Lum(vec3 c){
	return 0.298839*c.r + 0.586811*c.g + 0.11435*c.b;
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

mat3 sRGB2XYZ = mat3(
	0.4360747,  0.3850649,  0.1430804,
	0.2225045,  0.7168786,  0.0606169,
	0.0139322,  0.0971045,  0.7141733
);

mat3 XYZ2sRGB = mat3(
	3.1338561, -1.6168667, -0.4906146,
	-0.9787684,  1.9161415,  0.0334540,
	0.0719453, -0.2289914,  1.4052427
);

mat3 ROMM2XYZ = mat3(
	0.7976749,  0.1351917,  0.0313534,
	0.2880402,  0.7118741,  0.0000857,
	0.0000000,  0.0000000,  0.8252100
);

mat3 XYZ2ROMM = mat3(
	1.3459433, -0.2556075, -0.0511118,
	-0.5445989,  1.5081673,  0.0205351,
	0.0000000,  0.0000000,  1.2118128
);

float ramp(float t){
    t *= 2.0;
    if (t >= 1.0) {
      t -= 1.0;
      t = log(0.5) / log(0.5*(1.0-t) + 0.9332*t);
    }
    return clamp(t, 0.001, 10.0);
}

void main() {
  vec4 col = texture2D(texture, coord.xy);
	vec3 base = col.rgb;
  vec3 res, blend;

  // base = base * sRGB2XYZ * XYZ2ROMM;

  float amt = mix(0.009, 0.98, exposure);

  if (amt < 0.0) {
    res = mix(vec3(0.0), base, amt + 1.0);
    blend = mix(base, vec3(0.0), amt + 1.0);
    res = min(res / (1.0 - blend*0.9), 1.0);
  } else {
    res = mix(base, vec3(1.0), amt);
    blend = mix(vec3(1.0), pow(base, vec3(1.0/0.7)), amt);
    res = max(1.0 - ((1.0 - res) / blend), 0.0);
  }

  res = pow(SetLum(SetSat(base, Sat(res)), Lum(res)), vec3(ramp(1.0 - (gamma + 1.0) / 2.0)));

  // res = res * ROMM2XYZ * XYZ2sRGB;

	gl_FragColor = vec4(mix(base, res, col.a), col.a);

}