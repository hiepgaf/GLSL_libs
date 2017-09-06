varying vec4 coord;

uniform sampler2D texture;
uniform float offset;
uniform vec2 resolution;

float cubic( float x ) {
	const float B = 0.0;
	const float C = 0.75;
	if ( x < 0.0 ) x = -x;
	float x2 = x * x;
	float x3 = x2 * x;
	if ( x < 1.0 )
		return ( ( 12.0 - 9.0 * B - 6.0 * C ) * x3 + ( -18.0 + 12.0 * B + 6.0 * C ) * x2 + ( 6.0 - 2.0 * B ) ) / 6.0;
	else if ( x >= 1.0 && x < 2.0 )
		return ( ( -B - 6.0 * C ) * x3 + ( 6.0 * B + 30.0 * C ) * x2 + ( - ( 12.0 * B ) - 48.0 * C  ) * x +	8.0 * B + 24.0 * C) / 6.0;
	else return 0.0;
}

void main() {
	float texelSizeX = offset / resolution.x; //size of one texel 
  float texelSizeY = offset / resolution.y; //size of one texel 
  float a = fract( coord.x * resolution.x );
  float b = fract( coord.y * resolution.y );

  vec4 sum = vec4(0.0);
	float w, wx, wy, weight = 0.0;

  for( int m = -2; m <=3; m++ )
  {
    for( int n =-2; n<= 3; n++)
    {
			wx = cubic ( float( m ) - a );
			wy = cubic ( -( float( n ) - b ) );
			w += wx + wy;
      sum += texture2D(texture, coord.xy + vec2(texelSizeX * float( m ), texelSizeY * float( n ))) * w;
      weight += w;
    }
  }

  gl_FragColor = sum / weight;
  // gl_FragColor = texture2D(texture, coord.xy);
}