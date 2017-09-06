varying vec4 coord;

uniform sampler2D texture;
uniform vec3 shadows;
uniform vec3 highlights;
uniform float balance;

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

vec3 refWhite, refWhiteRGB = vec3(1.0);

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


void main() {

	vec3 base = texture2D(texture, coord.xy).rgb;
	float lum = Lum(base);
	float mask = (1.0 - pow(lum, 2.72));

	vec3 illum = vec3(0.95047, 1.0, 1.08883); // D65

	refWhite = mix(illum * shadows * 2.0, illum * highlights * 2.0, clamp(lum + balance, 0.0, 1.0));
	refWhite = mix(illum, refWhite, mask);
	refWhiteRGB = vec3(illum.x, 1.0, illum.z);

	d = matAdapt * refWhite;
	s = matAdapt * refWhiteRGB;


  vec3 xyz = RGBtoXYZ(base);
	vec3 rgb = XYZtoRGB(xyz);
	vec3 res = rgb;//SetLum(rgb, lum);

	gl_FragColor = vec4(res, 1.0);

}