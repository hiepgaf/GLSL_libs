varying vec4 coord;

uniform sampler2D texture;
uniform vec2 size;
uniform vec2 position;
uniform float spread;
uniform float amount;
uniform float highlights;
/* new uniform */
uniform float vignette_exposure;
uniform float vignette_roundness;
uniform float vignette_size;
uniform vec2 imgSize;
uniform vec4 crop;
uniform mat4 compositeMatrix;
uniform mat4 rotationMatrix;

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


float BlendSoftLightf(float base, float blend){
	return ((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)));
}

vec3 BlendSoftLight(vec3 base, vec3 blend){
	return vec3(BlendSoftLightf(base.r, blend.r), BlendSoftLightf(base.g, blend.g), BlendSoftLightf(base.b, blend.b));
}

float random(vec3 scale, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

void main() {
	float blur = min(1.0 - spread, 0.990);
	float opacity = -amount;
	float opacity_center = - vignette_exposure * 0.5;

	/* base and crop */
	vec3 base = texture2D(texture, coord.xy).rgb;
	vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix * rotationMatrix + 0.5;
  	vec2 cropCoords = (compositeCoords.xy - vec2(crop.x, 1.0-crop.w-crop.y)) / crop.zw;
  	/* scale size and limit normalized radius (midpoint in lightroom) */
	float scale_size = mix(10.0,2.0,vignette_size);
	float radius_normalized=1.0/scale_size;
	/* order for length computation when vignette_roundness<0, (-1->maximum norm for square, 0->2nd order) */
  	float order_norm = 1.0/mix(0.5,0.05,max(0.0,-vignette_roundness));
  	/* scale of x and y when vignette_roundness>0, 0-> elipse 1->perfect circle */
  	vec2 iSize = imgSize * crop.zw;
  	float scalex=mix(1.0,max(1.0,iSize.x/iSize.y),vignette_roundness);
  	float scaley=mix(1.0,max(1.0,iSize.y/iSize.x),vignette_roundness);
  	vec2 size_weight = vec2(scalex,scaley);
  	/* highlight mask */
  	vec3 mask = vec3(1.0 - pow(Lum(base), 2.72) * highlights);
	/* normalized distance to center */
	vec2 coords = (cropCoords - 0.5)/size*(1.0 - spread/2.0);
	vec2 dist = coords - position;
	/* scale x or y (longer one) when roundness>=0 */
	dist += dist*(size_weight-1.0)*float(vignette_roundness>=0.0);
	/* compute p norm for normalized distance */
	float dist_norm = pow(pow(abs(dist.x),order_norm)+pow(abs(dist.y),order_norm),1.0/order_norm);
	/* offset, can add some randomess */
	float offset = 1.0 + random(vec3(12.9898, 78.233, 151.7182), 0.0) / 100.0 * spread;
	/* center offset, smaller center */
	float offset_center = offset*1.0;
	/* res for outer */
	float weight = smoothstep(1.0, blur, dist_norm*scale_size*offset);
	vec3 res = vec3(weight);
	vec3 overlay = BlendSoftLight(base, mix(vec3(0.5), res/2.0, opacity));
	res = overlay * mix(vec3(1.0), res, opacity*mask);
	/* res for center */
	float weight_center = 1.0-weight;
	vec3 res_center = vec3(weight_center);
	vec3 overlay_center = BlendSoftLight(base, mix(vec3(0.5), res_center/2.0, opacity_center));	
	res_center = overlay_center * mix(vec3(1.0), res_center, opacity_center*mask);
	/*final mix result */
	float weight_mix = float(weight/(weight+weight_center));
	gl_FragColor = vec4(mix(res,res_center,weight_mix),1.0);
}