 varying vec4 coord;

uniform sampler2D texture;
uniform float contrast;

float BlendOverlayf(float base, float blend){
  return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
}

vec3 BlendOverlay(vec3 base, vec3 blend){
  return vec3(BlendOverlayf(base.r, blend.r), BlendOverlayf(base.g, blend.g), BlendOverlayf(base.b, blend.b));
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

void main() {
  vec4 col = texture2D(texture, coord.xy);

	float amount = (contrast < 0.0) ? contrast/2.0 : contrast;

	vec3 base = col.rgb * sRGB2XYZ * XYZ2ROMM;

  vec3 overlay = mix(vec3(0.5), base, amount * col.a);

  vec3 res = BlendOverlay(base, overlay) * ROMM2XYZ * XYZ2sRGB;

	gl_FragColor = vec4(res, col.a);

}