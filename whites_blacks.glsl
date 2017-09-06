varying vec4 coord;

uniform sampler2D texture;
uniform float whites;
uniform float blacks;

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

const float wb = 5.336778471840789E-03;
const float wc = 6.664243592410049E-01;
const float wd = 3.023761372137289E+00;
const float we = -6.994413182098681E+00;
const float wf = 3.293987131616894E+00;
const float wb2 = -1.881032803339283E-01;
const float wc2 = 2.812945435181010E+00;
const float wd2 = -1.495096839176419E+01;
const float we2 = 3.349416467551858E+01;
const float wf2 = -3.433024909629221E+01;
const float wg2 = 1.314308200442166E+01;

const float bb = 8.376727344831676E-01;
const float bc = -3.418495999327269E+00;
const float bd = 8.078054837335609E+00;
const float be = -1.209938703324099E+01;
const float bf = 9.520315785756406E+00;
const float bg = -2.919340722745241E+00;
const float ba2 = 5.088652898054800E-01;
const float bb2 = -9.767371127415029E+00;
const float bc2 = 4.910705739925203E+01;
const float bd2 = -1.212150899746360E+02;
const float be2 = 1.606205314047741E+02;
const float bf2 = -1.085660871669277E+02;
const float bg2 = 2.931582214601388E+01;

void main() {
	vec3 base = texture2D(texture, coord.xy).rgb;

	float maxx = max(base.r, max(base.g, base.b));
	float minx = min(base.r, min(base.g, base.b));
	float lum = (maxx+minx)/2.0;
	float x = lum;
	float x2 = x*x;
	float x3 = x2*x;
	float lum_pos, lum_neg;
	vec3 res;

	// whites
	lum_pos = wb*x + wc*x2+ wd*x3 + we*x2*x2 + wf*x2*x3;
	lum_pos = min(lum_pos,1.0-lum);
	lum_neg = wb2*x + wc2*x2+ wd2*x3 + we2*x2*x2 + wf2*x2*x3 + wg2*x3*x3;
	lum_neg = max(lum_neg,-lum);
	res = whites>=0.0 ? base*(lum_pos*whites+lum)/lum : base * (lum-lum_neg*whites)/lum;
	res = clamp(res, 0.0, 1.0);

	// blacks
	lum_pos = bb*x + bc*x2+ bd*x3 + be*x2*x2 + bf*x2*x3 + bg*x3*x3;
	lum_pos = min(lum_pos,1.0-lum);
	lum_neg = lum<=0.23 ? -lum : ba2 + bb2*x + bc2*x2+ bd2*x3 + be2*x2*x2 + bf2*x2*x3 + bg2*x3*x3;
	lum_neg = max(lum_neg,-lum);
	res = blacks>=0.0 ? res*(lum_pos*blacks+lum)/lum : res * (lum-lum_neg*blacks)/lum;
	res = clamp(res, 0.0, 1.0);

	gl_FragColor = vec4(SetLum(base, Lum(res)), 1.0);
}