varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D blurTexture;
uniform sampler2D halfTexture;

uniform mat4 compositeMatrix;
uniform vec2 textureResolution;
uniform vec4 crop;

uniform float distortionAmount;
uniform float scale;
uniform float balance;
uniform vec4 color;
uniform vec4 light;
uniform vec4 light2;
uniform vec4 detail;
uniform vec3 vignette;
uniform vec3 shadowsColor;
uniform vec3 highlightsColor;

/*=== Globals ===============================*/

vec3 refWhite, refWhiteRGB;

vec3 adaptTo, adaptFrom;

// illuminants
//vec3 A = vec3(1.09850, 1.0, 0.35585);
//vec3 D50 = vec3(0.96422, 1.0, 0.82521);
//vec3 D65 = vec3(0.95047, 1.0, 1.08883);
//vec3 D75 = vec3(0.94972, 1.0, 1.22638);


vec3 D50 = vec3(0.981443, 1.0, 0.863177);
vec3 D65 = vec3(0.968774, 1.0, 1.121774);

vec3 CCT2K = vec3(1.274335, 1.0, 0.145233);
vec3 CCT4K = vec3(1.009802, 1.0, 0.644496);
vec3 CCT20K = vec3(0.995451, 1.0, 1.886109);

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

const float permTexUnit = 1.0/256.0;    // Perm texture texel-size
const float permTexUnitHalf = 0.5/256.0;  // Half perm texture texel-size

/*=== Distortion ===============================*/

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

/*=== Color Conversions ===============================*/

mat3 matRGBtoXYZ = mat3(
	0.4124564390896922, 0.21267285140562253, 0.0193338955823293,
	0.357576077643909, 0.715152155287818, 0.11919202588130297,
	0.18043748326639894, 0.07217499330655958, 0.9503040785363679
);


mat3 matXYZtoRGB = mat3(
	3.2404541621141045, -0.9692660305051868, 0.055643430959114726,
	-1.5371385127977166, 1.8760108454466942, -0.2040259135167538,
	-0.498531409556016, 0.041556017530349834, 1.0572251882231791
);

mat3 matAdapt = mat3(
	0.8951, -0.7502, 0.0389,
	0.2664, 1.7135, -0.0685,
	-0.1614, 0.0367, 1.0296
);

mat3 matAdaptInv = mat3(
	0.9869929054667123, 0.43230526972339456, -0.008528664575177328,
	-0.14705425642099013, 0.5183602715367776, 0.04004282165408487,
	0.15996265166373125, 0.0492912282128556, 0.9684866957875502
);

vec3 RGBtoXYZ(vec3 rgb){
	vec3 xyz, XYZ;

	xyz = matRGBtoXYZ * rgb;

	// adaption
	XYZ = matAdapt * xyz;
	XYZ *= adaptTo/adaptFrom;
	xyz = matAdaptInv * XYZ;

	return xyz;
}

vec3 XYZtoRGB(vec3 xyz){
	vec3 rgb, RGB;

	// adaption
	RGB = matAdapt * xyz;
	rgb *= adaptFrom/adaptTo;
	xyz = matAdaptInv * RGB;

	rgb = matXYZtoRGB * xyz;

	return rgb;
}

/*=== Luminance and Saturation Functions ===============================*/

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

/*=== Blending Functions ===============================*/

float BlendOverlayf(float base, float blend){
  return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
}

vec3 BlendOverlay(vec3 base, vec3 blend){
  return vec3(BlendOverlayf(base.r, blend.r), BlendOverlayf(base.g, blend.g), BlendOverlayf(base.b, blend.b));
}

float BlendVividLightf(float base, float blend){
  if (blend < 0.5) {
    return (((2.0 * blend) == 0.0) ? (2.0 * blend) : max((1.0 - ((1.0 - base) / (2.0 * blend))), 0.0));
  } else {
    return (((2.0 * (blend - 0.5)) == 1.0) ? (2.0 * (blend - 0.5)) : min(base / (1.0 - (2.0 * (blend - 0.5))), 1.0));
  }
}

vec3 BlendVividLight(vec3 base, vec3 blend){
  return vec3(BlendVividLightf(base.r, blend.r), BlendVividLightf(base.g, blend.g), BlendVividLightf(base.b, blend.b));
}

float BlendSoftLightf(float base, float blend){
	return ((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)));
}

vec3 BlendSoftLight(vec3 base, vec3 blend){
	return vec3(BlendSoftLightf(base.r, blend.r), BlendSoftLightf(base.g, blend.g), BlendSoftLightf(base.b, blend.b));
}

/*=== Helper Functions ===============================*/

float random(vec3 scale, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

float ramp(float t){
    t *= 2.0;
    if (t >= 1.0) {
      t -= 1.0;
      t = log(0.5) / log(0.5*(1.0-t) + 0.9332*t);
    }
    return clamp(t, 0.001, 10.0);
}

//a random texture generator, but you can also use a pre-computed perturbation texture
vec4 rnm(in vec2 tc)
{
  float timer = 1.0;
  float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;
  float noiseR =  fract(noise)*2.0-1.0;
  float noiseG =  fract(noise*1.2154)*2.0-1.0;
  float noiseB =  fract(noise*1.3453)*2.0-1.0;
  float noiseA =  fract(noise*1.3647)*2.0-1.0;
  return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(in float t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(in vec3 p)
{
  vec3 pi = permTexUnit*floor(p)+permTexUnitHalf;
  // and offset 1/2 texel to sample texel centers
  vec3 pf = fract(p);     // Fractional part for interpolation
  // Noise contributions from (x=0, y=0), z=0 and z=1
  float perm00 = rnm(pi.xy).a;
  vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
  float n000 = dot(grad000, pf);
  vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));
  // Noise contributions from (x=0, y=1), z=0 and z=1
  float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a;
  vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
  float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
  vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));
  // Noise contributions from (x=1, y=0), z=0 and z=1
  float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a;
  vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
  float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
  vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));
  // Noise contributions from (x=1, y=1), z=0 and z=1
  float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a;
  vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
  float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
  vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));
  // Blend contributions along x
  vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));
  // Blend contributions along y
  vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));
  // Blend contributions along z
  float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));
  return n_xyz;
}
//2d coordinate orientation thing
vec2 coordRot(in vec2 tc, in float angle)
{
  float aspect = textureResolution.x/textureResolution.y;
  float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
  float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
  rotX = ((rotX/aspect)*0.5+0.5);
  rotY = rotY*0.5+0.5;
  return vec2(rotX,rotY);
}

/*=== Color Temperature ===============================*/

vec3 Temperature(vec3 base, float temperature, float tint) {
  vec3 to, from;

  float luminance = Lum(base);

  if (temperature < 0.0) {
    to = CCT20K;
    from = D65;
  } else {
    to = CCT4K;
    from = D65;
  }

  // mask by luminance
  float temp = abs(temperature) * (1.0 - pow(luminance, 2.72));

  // from
  refWhiteRGB = from;
  // to
  refWhite = vec3(mix(from.x, to.x, temp), mix(1.0, 0.9, tint), mix(from.z, to.z, temp));

  adaptTo = matAdapt * refWhite;
  adaptFrom = matAdapt * refWhiteRGB;
  vec3 xyz = RGBtoXYZ(base);
  vec3 rgb = XYZtoRGB(xyz);
  // brightness compensation
  return rgb * (1.0 + (temp + tint) / 10.0);
}

vec3 Diffuse(vec3 base, vec3 blur, float diffuse) {
  float luminance = Lum(base);
  float mask = 1.0 - pow(luminance, 2.72);
  vec3 diffuseMap = blur / 2.0 + 0.5;
  vec3 blend = mix(vec3(0.5), diffuseMap, diffuse * 2.0 * mask);

  return sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
}

vec3 Saturation(vec3 base, float saturation, float vibrance) {
  float luminance = Lum(base);
  float mn = min(min(base.r, base.g), base.b);
	float mx = max(max(base.r, base.g), base.b);
	float sat = (1.0-(mx - mn)) * (1.0-mx) * luminance * 5.0;
	vec3 lightness = vec3((mn + mx)/2.0);

	// vibrance
	base = mix(base, mix(base, lightness, -vibrance), sat);

	// negative vibrance
	base = mix(base, lightness, (1.0-lightness)*(1.0-vibrance)/2.0*abs(vibrance));

	// saturation
	return mix(base, vec3(luminance), -saturation);
}

vec3 Exposure(vec3 base, float exposure, float gamma) {
  float amt = mix(0.009, 0.98, exposure);
  vec3 res, blend;

  if (amt < 0.0) {
    res = mix(vec3(0.0), base, amt + 1.0);
    blend = mix(base, vec3(0.0), amt + 1.0);
    res = min(res / (1.0 - blend*0.9), 1.0);
  } else {
    res = mix(base, vec3(1.0), amt);
    blend = mix(vec3(1.0), pow(base, vec3(1.0/0.7)), amt);
    res = max(1.0 - ((1.0 - res) / blend), 0.0);
  }

  return pow(SetLum(SetSat(base, Sat(res)), Lum(res)), vec3(ramp(1.0 - (gamma + 1.0) / 2.0)));
}

vec3 Contrast(vec3 base, float contrast) {
  float amount = (contrast < 0.0) ? contrast/2.0 : contrast;

  vec3 overlay = mix(vec3(0.5), base, amount);

  return BlendOverlay(base, overlay);
}

vec3 WhitesBlacks(vec3 base, float whites, float blacks) {
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

  // blacks
	lum_pos = bb*x + bc*x2+ bd*x3 + be*x2*x2 + bf*x2*x3 + bg*x3*x3;
	lum_pos = min(lum_pos,1.0-lum);
	lum_neg = lum<=0.23 ? -lum : ba2 + bb2*x + bc2*x2+ bd2*x3 + be2*x2*x2 + bf2*x2*x3 + bg2*x3*x3;
	lum_neg = max(lum_neg,-lum);
	res = blacks>=0.0 ? res*(lum_pos*blacks+lum)/lum : res * (lum-lum_neg*blacks)/lum;

	return SetLum(base, Lum(res));
}

vec3 ShadowsHighlights(vec3 base, vec3 blurMap, float shadows, float highlights) {
	float amt = mix(highlights, shadows, 1.0 - Lum(blurMap));

	if (amt < 0.0) amt *= 2.0;

	// exposure
	vec3 res = mix(base, vec3(1.0), amt);
  vec3 blend = mix(vec3(1.0), pow(base, vec3(1.0/0.7)), amt);
  res = max(1.0 - ((1.0 - res) / blend), 0.0);

	return SetLum(SetSat(base, Sat(res)), Lum(res));
}

vec3 Sharpen(vec3 color, vec3 sharpenMap, float sharpen) {
	float intensity = (sharpen < 0.0) ? (sharpen / 2.0) : sharpen;
  float lum = Lum(color);

  vec3 base = vec3(lum);
  vec3 mask = vec3(1.0 - pow(lum, 1.8));
  // invert blurred texture
  vec3 layer = vec3(1.0 - Lum(sharpenMap));
  vec3 detail = BlendVividLight(base, layer);
  // we get negative detail by inverting the detail layer
  vec3 inverse = mix(1.0 - detail, detail, (intensity+1.0)/2.0);
  // vec3 blend = BlendOverlay(color, mix(vec3(0.5), inverse, mask));
  return BlendOverlay(color, mix(vec3(0.5), detail, intensity*2.0));
}

vec3 Clarity(vec3 base, vec3 blurMap, float clarity) {
  float intensity = (clarity < 0.0) ? (clarity / 2.0) : clarity;
  float lum = Lum(base);

  vec3 col = vec3(lum);
  vec3 mask = vec3(1.0 - pow(lum, 1.8));
  // invert blurred texture
  vec3 layer = vec3(1.0 - Lum(blurMap));
  vec3 detail = clamp(BlendVividLight(col, layer), 0.0, 1.0);
  // we get negative detail by inverting the detail layer
  vec3 inverse = mix(1.0 - detail, detail, (intensity+1.0)/2.0);

  return BlendOverlay(base, mix(vec3(0.5), inverse, mask));
}

vec3 Grain(vec3 base, float size, float amount, vec2 coords) {
  size = (size + 1.5) * scale; //grain particle size (1.5 - 2.5)
  float intensity = 0.5;
  float grain = amount / 4.0;
  float width = textureResolution.x;
  float height = textureResolution.y;

  vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
  vec2 rotCoordsR = coordRot(coords, 1.0 + rotOffset.x);
  vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/size,height/size),0.0)));

  //noisiness response curve based on scene luminance
  vec3 lumcoeff = vec3(0.299,0.587,0.114);
  float luminance = mix(0.0,dot(base, lumcoeff),intensity);
  float lum = smoothstep(0.2,0.0,luminance);
  lum += luminance;
  noise = mix(noise,vec3(0.0),pow(lum,4.0));
  return base+noise*grain;
}

vec3 Vignette(vec3 base, float amount, float spread, float highlights, vec2 coords) {
  vec2 size = vec2(1.0, 1.0);
  vec2 position = vec2(0.0, 0.0);
  float blur = min(1.0 - spread, 0.990);
  float opacity = -amount;

  coords = (coords - 0.5)/size*(1.0 - spread/2.0);

	float offset = 1.0 + random(vec3(12.9898, 78.233, 151.7182), 0.0)/100.0 * spread / opacity;
	float dist = distance(coords+0.5, position+0.5);

	vec3 res = vec3(smoothstep(1.0, blur, dist*2.0*offset));
	vec3 mask = vec3(1.0 - pow(Lum(base), 2.72) * highlights);

	vec3 overlay = BlendSoftLight(base, mix(vec3(0.5), res/2.0, opacity));
	return overlay * mix(vec3(1.0), res, opacity*mask);
}

vec3 SplitTone(vec3 base, vec3 shadows, vec3 highlights, float balance) {
	float lum = Lum(base);
	float mask = (1.0 - pow(lum, 2.72));

	refWhite = mix(D65 * shadows * 2.0, D65 * highlights * 2.0, clamp(lum + balance, 0.0, 1.0));
	refWhite = mix(D65, refWhite, mask);
	refWhiteRGB = vec3(D65.x, 1.0, D65.z);

	adaptTo = matAdapt * refWhite;
	adaptFrom = matAdapt * refWhiteRGB;


  vec3 xyz = RGBtoXYZ(base);
	return XYZtoRGB(xyz);
}

void main() {
  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec2 distortedCoords = distort(compositeCoords.xy, distortionAmount, textureResolution);
  vec2 cropCoords = (compositeCoords.xy - vec2(crop.x, 1.0-crop.w-crop.y)) / crop.zw;

  vec4 colorMap = texture2D(texture, coord.xy);
  vec3 blurMap = texture2D(blurTexture, distortedCoords).rgb;
  vec3 sharpenMap = texture2D(halfTexture, distortedCoords).rgb;

  vec3 result = colorMap.rgb;

  result = Diffuse(result, blurMap, light[3]);
  result = Sharpen(result, sharpenMap, detail[0]);
  result = Clarity(result, blurMap, detail[1]);
  result = WhitesBlacks(result, light2[0], light2[1]);
  result = ShadowsHighlights(result, blurMap, light2[2], light2[3]);
  result = Exposure(result, light[0], light[1]);
  result = Temperature(result, color[0], color[1]);
  result = Contrast(result, light[2]);
  result = Saturation(result, color[2], color[3]);
  result = SplitTone(result, shadowsColor, highlightsColor, balance);
  result = Vignette(result, vignette[0], vignette[1], vignette[2], cropCoords);
  result = Grain(result, detail[2], detail[3], distortedCoords);

  result = mix(colorMap.rgb, result, colorMap.a);

  gl_FragColor = vec4(result, colorMap.a);
}