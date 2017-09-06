// fragment_dehazemap1.cpp
// usage: use before rendering to generate map, get transmission map prior from image
// input: uniform sampler2D texture (image loaded)
// output: rgb from image, alpha channel represent the transmission computed from darkchannel
// ref: http://research.microsoft.com/en-us/um/people/jiansun/papers/dehaze_cvpr2009.pdf

varying vec4 coord;
uniform sampler2D texture;

float random(vec3 scale, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

const float filter_window=0.01;
float minimumFilter(sampler2D tex, vec2 uv, vec3 ratio)
{
    mediump float wsize = filter_window/14.0;
    vec3 res = vec3(1000.0,1000.0,1000.0);
    float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);
    float offset2 = random(vec3(78.233, 151.7182, 12.9898), 0.0);
    for (float i = -7.0; i <= 7.0; i++) {
        for (float j= -7.0; j<= 7.0; j++) {
        	vec2 coord_sample=uv+vec2(float(i)+offset-0.5,float(j)+offset2-0.5)*wsize;
        	vec3 tmp=texture2D(tex,coord_sample).rgb;
            tmp*=ratio;
           	res = min(res,tmp);
        }
    }
    return min(min(res[0],res[1]),res[2]);
}

void main() {
	vec3 base = texture2D(texture, coord.xy).rgb;
	float res_t = 1.0-0.95*minimumFilter(texture,coord.xy,vec3(1.0,1.0,1.0));
	res_t = max(1e-3,min(1.0-1e-3,res_t));
    gl_FragColor = vec4(base,res_t);
}