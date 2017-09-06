varying vec4 coord;

uniform sampler2D texture;

uniform float sharpen;
uniform vec2 imgSize;

void main() {
	vec2 offset[4];
	vec2 step = 1.0 / imgSize;
	float step_w = step.x;
	float step_h = step.y;

	offset[0] = vec2(0.0, -step_h);
	offset[1] = vec2(-step_w, 0.0);
	offset[2] = vec2(step_w, 0.0);
	offset[3] = vec2(0.0, step_h);

	vec4 midColor = texture2D(texture, coord.xy);

	vec4 sum = midColor * 5.0;

	for (int i = 0; i < 4; i++) {
		vec4 color = texture2D(texture, coord.xy + offset[i]);
		sum += color * -1.0;
	}

	gl_FragColor = mix(midColor, sum, sharpen);
}