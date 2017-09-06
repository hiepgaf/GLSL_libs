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

const float filter_window = 0.01;
const float sample_radius = 5.0;

float minimumFilter(sampler2D tex, vec2 uv, vec3 ratio, vec2 step)
{
    float wsize = filter_window/sample_radius/2.0;
    float channeldark = 1000.0;
    float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);
    float offset2 = random(vec3(151.7182, 12.9898, 78.233), 0.0);
    for (int i = -5; i <= 5; i++) {
        vec2 coord_sample=uv+vec2(float(i)*step[0]+offset-0.5,float(i)*step[1]+offset2-0.5)*wsize;
        vec4 sample_neighbor=texture2D(tex,coord_sample).rgba;
        channeldark = min(min(min(channeldark, sample_neighbor[0]*ratio[0]), sample_neighbor[1]*ratio[1]), sample_neighbor[2]*ratio[2]);
        channeldark = min(channeldark, sample_neighbor.a);
    }
    return channeldark;
}

void main() {
    vec3 base = texture2D(texture, coord.xy).rgb;
    vec3 ratio_A = vec3(1.0,1.0,1.0);
    float res_t = 1.0 - 0.95 * minimumFilter(texture, coord.xy, 1.0/ratio_A ,vec2(0.1,0.9));
    res_t = clamp(res_t, 1e-3, 1.0 - 1e-3);
    gl_FragColor = vec4(base,res_t);
}