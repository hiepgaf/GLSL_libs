varying vec4 coord;

uniform sampler2D texture;
uniform vec3 background;
uniform vec4 compositeCoords;
uniform vec2 screenResolution;

void main() {
  vec2 size = (compositeCoords.zw - compositeCoords.xy) / screenResolution;
  vec2 offset = compositeCoords.xy / screenResolution;
  vec2 texCoords = (coord.xy - offset) / size;

  if ((texCoords.x < 0.0 || texCoords.x > 1.0) || (texCoords.y < 0.0 || texCoords.y > 1.0)) {
    gl_FragColor = vec4(background, 1.0);
  } else {
    vec4 col = texture2D(texture, texCoords);
    gl_FragColor = vec4(mix(background, col.rgb, col.a), 1.0);
  }
}