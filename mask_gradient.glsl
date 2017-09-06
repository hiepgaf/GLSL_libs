varying vec4 coord;

uniform vec2 startPoint;
uniform vec2 endPoint;
uniform vec2 imgSize;

uniform mat4 compositeMatrix;
uniform sampler2D texture;

void main() {
  vec3 col = texture2D(texture, coord.xy).rgb;

  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix;
	vec2 coords = vec2(compositeCoords.x, 1.0 - compositeCoords.y) * imgSize;

  vec2 start = vec2(startPoint.x, startPoint.y + 1.0) * imgSize;
  vec2 end = vec2(endPoint.x, endPoint.y + 1.0) * imgSize;

  vec2 direction = end - start;
  direction /= sqrt(direction.x * direction.x + direction.y * direction.y);
  float scale = dot(direction,end-start);
  float value = dot(direction,coords-start)/scale;

	gl_FragColor = vec4(col, clamp(1.0-value, 0.0, 1.0));
}