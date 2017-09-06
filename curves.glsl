varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D map;

void main() {

  vec4 color = texture2D(texture, coord.xy);
  color.r = texture2D(map, vec2(texture2D(map, vec2(color.r)).r)).a;
  color.g = texture2D(map, vec2(texture2D(map, vec2(color.g)).g)).a;
  color.b = texture2D(map, vec2(texture2D(map, vec2(color.b)).b)).a;

  gl_FragColor = color;
  
}