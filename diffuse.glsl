varying vec4 coord;

uniform sampler2D texture;
uniform sampler2D blurTexture;
uniform mat4 compositeMatrix;

uniform float diffuse;
uniform float distortion_amount;
uniform vec2 imgSize;

vec2 distort(vec2 coord, float amount, vec2 size) {
  float f = 1.0;
  float zoom = 1.0;
  vec2 center = vec2(0.5);
  if(amount < 0.0){
      float correction = sqrt(size.x*size.x+size.y*size.y)/(amount*-4.0);
      float nx = (coord.x - center.x) * size.x;
      float ny = (coord.y - center.y) * size.y;
      float d = sqrt(nx*nx+ny*ny);
      float r = d/correction;
      if(r != 0.0){
          f = atan(r)/r;
      }
      r = max(-0.5 * size.x, -0.5 * size.y) / correction;
      zoom = atan(r)/r;

  }else{
      float size = 0.75;
      float r2 = (coord.x-center.x) * (coord.x-center.x) + (coord.y-center.y) * (coord.y-center.y);
      r2 = r2 * size * size;
      f = 1.0 + r2 * amount * 2.0;
      zoom = 1.0 + (0.5 * size * size) * amount * 2.0;
  }
  return f * (coord - center) / zoom + center;
}

float Lum(vec3 c){
	return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}

void main() {
  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;
  vec3 col = texture2D(texture, coord.xy).rgb;
  vec3 blur = texture2D(blurTexture, distort(compositeCoords.xy, distortion_amount, imgSize)).rgb;

  vec3 diffuseMap = blur / 2.0 + 0.5;
  float mask = 1.0 - pow(Lum(col), 2.72);
  vec3 blend = mix(vec3(0.5), diffuseMap, diffuse * 2.0 * mask);
  vec3 res = sqrt(col) * (2.0 * blend - 1.0) + 2.0 * col * (1.0 - blend);

  gl_FragColor = vec4(res, 1.0);
}