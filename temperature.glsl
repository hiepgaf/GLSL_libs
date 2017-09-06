varying vec4 coord;

uniform sampler2D texture;
uniform float temperature;
uniform float tint;

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

vec3 refWhite, refWhiteRGB;

vec3 d, s;

vec3 RGBtoXYZ(vec3 rgb){
	vec3 xyz, XYZ;

	xyz = matRGBtoXYZ * rgb;

	// adaption
	XYZ = matAdapt * xyz;
	XYZ *= d/s;
	xyz = matAdaptInv * XYZ;

	return xyz;
}

vec3 XYZtoRGB(vec3 xyz){
	vec3 rgb, RGB;

	// adaption
	RGB = matAdapt * xyz;
	rgb *= s/d;
	xyz = matAdaptInv * RGB;

	rgb = matXYZtoRGB * xyz;

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

// illuminants
//vec3 A = vec3(1.09850, 1.0, 0.35585);
vec3 D50 = vec3(0.96422, 1.0, 0.82521);
vec3 D65 = vec3(0.95047, 1.0, 1.08883);
//vec3 D75 = vec3(0.94972, 1.0, 1.22638);


//vec3 D50 = vec3(0.981443, 1.0, 0.863177);
//vec3 D65 = vec3(0.968774, 1.0, 1.121774);

vec3 CCT2K = vec3(1.274335, 1.0, 0.145233);
vec3 CCT4K = vec3(1.009802, 1.0, 0.644496);
vec3 CCT20K = vec3(0.995451, 1.0, 1.886109);

void main() {
  vec4 col = texture2D(texture, coord.xy);

  vec3 to, from;

  if (temperature < 0.0) {
    to = CCT20K;
    from = D65;
  } else {
    to = CCT4K;
    from = D65;
  }

	vec3 base = col.rgb;
	float lum = Lum(base);
	// mask by luminance
	float temp = abs(temperature) * (1.0 - pow(lum, 2.72));

  // from
	refWhiteRGB = from;
	// to
	refWhite = vec3(mix(from.x, to.x, temp), mix(1.0, 0.9, tint), mix(from.z, to.z, temp));

  // mix based on alpha for local adjustments
	refWhite = mix(refWhiteRGB, refWhite, col.a);

	d = matAdapt * refWhite;
	s = matAdapt * refWhiteRGB;
  vec3 xyz = RGBtoXYZ(base);
	vec3 rgb = XYZtoRGB(xyz);
	// brightness compensation
	vec3 res = rgb * (1.0 + (temp + tint) / 10.0);
	// preserve luminance
	//vec3 res = SetLum(rgb, lum);

	gl_FragColor = vec4(mix(base, res, col.a), col.a);

}