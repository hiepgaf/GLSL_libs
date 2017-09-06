// fragment_dehazemap2.cpp
// usage: use before rendering to generate map, smooth the transmission map based on prior 
// input: uniform sampler2D texture (generated from shader dehazemap1.cpp)
// output: gray image of transmission map(r=g=b=a), later I may want to use the redundant channels to save more information.
// ref: http://research.microsoft.com/en-us/um/people/jiansun/papers/dehaze_cvpr2009.pdf

varying vec4 coord;
uniform sampler2D texture;

float random(vec3 scale, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

const float sigma_s=0.02;
const float sigma_c=0.2;
const float filter_window=0.1;
/* guid filter alpha channel with rgb information*/
float guidedFilter(vec2 uv)
{
    float wsize = filter_window/14.0;
    float res_v = 0.0;
    float res_w = 0.0;
    vec3 center_g=texture2D(texture,uv).rgb;
    float sigma_i=0.5*wsize*wsize/sigma_s/sigma_s;
    float offset2 = random(vec3(12.9898, 78.233, 151.7182), 0.0);
    float offset = random(vec3(151.7182, 12.9898, 78.233), 0.0);
    for (float i = -7.0; i <= 7.0; i++) {
        for (float j= -7.0; j<= 7.0; j++) {
            vec2 coord_sample=uv+vec2(float(i)+offset-0.5,float(j)+offset2-0.5)*wsize;           
            float tmp_v=texture2D(texture,coord_sample).a;   
            vec3 tmp_g=texture2D(texture,coord_sample).rgb;   
            vec3 diff_g=(tmp_g-center_g);
            float tmp_w=exp(-(i*i+j*j)*sigma_i);
            tmp_w*=exp(-(dot(diff_g,diff_g)/2.0/sigma_c/sigma_c));
            res_v+=tmp_v*tmp_w;
            res_w+=tmp_w;   
        }
    }
    float res = res_v/res_w;
    return res;
}

void main() {
    float res_t = guidedFilter(coord.xy);
	  res_t = max(1e-3, min(1.0-1e-3, res_t));
    gl_FragColor = vec4(res_t,res_t,res_t,res_t);
}