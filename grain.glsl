varying vec4 coord;

uniform sampler2D texture;

uniform vec2 imgSize;
uniform float scale;
uniform float grain_amount;
uniform float grain_size;
uniform mat4 compositeMatrix;

const float timer = 1.0;
const float intensity = 0.5;

const float permTexUnit = 1.0/256.0;    // Perm texture texel-size
const float permTexUnitHalf = 0.5/256.0;  // Half perm texture texel-size

//a random texture generator, but you can also use a pre-computed perturbation texture
vec4 rnm(in vec2 tc)
{
  float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;
  float noiseR =  fract(noise)*2.0-1.0;
  float noiseG =  fract(noise*1.2154)*2.0-1.0;
  float noiseB =  fract(noise*1.3453)*2.0-1.0;
  float noiseA =  fract(noise*1.3647)*2.0-1.0;
  return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(in float t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(in vec3 p)
{
  vec3 pi = permTexUnit*floor(p)+permTexUnitHalf;
  // and offset 1/2 texel to sample texel centers
  vec3 pf = fract(p);     // Fractional part for interpolation
  // Noise contributions from (x=0, y=0), z=0 and z=1
  float perm00 = rnm(pi.xy).a;
  vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
  float n000 = dot(grad000, pf);
  vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));
  // Noise contributions from (x=0, y=1), z=0 and z=1
  float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a;
  vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
  float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
  vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));
  // Noise contributions from (x=1, y=0), z=0 and z=1
  float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a;
  vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
  float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
  vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));
  // Noise contributions from (x=1, y=1), z=0 and z=1
  float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a;
  vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
  float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
  vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
  float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));
  // Blend contributions along x
  vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));
  // Blend contributions along y
  vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));
  // Blend contributions along z
  float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));
  return n_xyz;
}
//2d coordinate orientation thing
vec2 coordRot(in vec2 tc, in float angle)
{
  float aspect = imgSize.x/imgSize.y;
  float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
  float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
  rotX = ((rotX/aspect)*0.5+0.5);
  rotY = rotY*0.5+0.5;
  return vec2(rotX,rotY);
}
void main()
{
  float size = (grain_size + 1.5) * scale; //grain particle size (1.5 - 2.5)
  float grain = grain_amount / 4.0;
  float width = imgSize.x;
  float height = imgSize.y;

  vec4 compositeCoords = (coord - 0.5 + compositeMatrix[3]) * compositeMatrix + 0.5;

  vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
  vec2 rotCoordsR = coordRot(compositeCoords.xy, timer + rotOffset.x);
  vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/size,height/size),0.0)));

  vec3 col = texture2D(texture, coord.xy).rgb;
  //noisiness response curve based on scene luminance
  vec3 lumcoeff = vec3(0.299,0.587,0.114);
  float luminance = mix(0.0,dot(col, lumcoeff),intensity);
  float lum = smoothstep(0.2,0.0,luminance);
  lum += luminance;
  noise = mix(noise,vec3(0.0),pow(lum,4.0));
  col = col+noise*grain;

  gl_FragColor = vec4(col, 1.0);
}