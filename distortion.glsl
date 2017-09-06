varying vec4 coord;

uniform sampler2D texture;
uniform float distortion_amount;
uniform float fringing;
uniform vec2 imgSize;

void main(){
  vec4 coords = coord;

  vec2 center = vec2(0.5);
  float fringe = fringing / 9.0;
  float f = 1.0;
  float zoom = 1.0;

  // index of refraction of each color channel, causing chromatic fringing
  vec3 eta = vec3(1.0+fringe*0.7, 1.0+fringe*0.4, 1.0);

  if(distortion_amount < 0.0){
      float correction = sqrt(imgSize.x*imgSize.x+imgSize.y*imgSize.y)/(distortion_amount*-4.0);
      float nx = (coords.x - center.x) * imgSize.x;
      float ny = (coords.y - center.y) * imgSize.y;
      float d = sqrt(nx*nx+ny*ny);
      float r = d/correction;
      if(r != 0.0){
          f = atan(r)/r;
      }
      r = max(-0.5 * imgSize.x, -0.5 * imgSize.y) / correction;
      zoom = atan(r)/r;

  }else{
      float size = 0.75;
      // canvas coordsinates to get the center of rendered viewport
      float r2 = (coords.x-center.x) * (coords.x-center.x) + (coords.y-center.y) * (coords.y-center.y);
      r2 = r2 * size * size;

      // only compute the cubic distortion if necessary
      f = 1.0 + r2 * distortion_amount * 2.0;

      zoom = 1.0 + (0.5 * size * size) * distortion_amount * 2.0;
  }
  // get the right pixel for the current position
  vec2 rCoords = (f*eta.r)*(coords.xy-center)/zoom+center;
  vec2 gCoords = (f*eta.g)*(coords.xy-center)/zoom+center;
  vec2 bCoords = (f*eta.b)*(coords.xy-center)/zoom+center;
  vec3 inputDistort = vec3(0.0);
  inputDistort.r = texture2D(texture,rCoords).r;
  inputDistort.g = texture2D(texture,gCoords).g;
  inputDistort.b = texture2D(texture,bCoords).b;
  gl_FragColor = vec4(inputDistort.r,inputDistort.g,inputDistort.b,1.0);
}