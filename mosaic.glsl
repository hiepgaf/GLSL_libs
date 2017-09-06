precision highp float;

varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform vec2 inputTileSize;
uniform vec2 displayTileSize;
uniform float numTiles;
uniform int colorOn;

void main()
{
    vec2 xy = textureCoordinate;
    xy = xy - mod(xy, displayTileSize);
    
    vec4 lumcoeff = vec4(0.299,0.587,0.114,0.0);
    
    vec4 inputColor = texture2D(inputImageTexture2, xy);
    float lum = dot(inputColor,lumcoeff);
    lum = 1.0 - lum;
    
    float stepsize = 1.0 / numTiles;
    float lumStep = (lum - mod(lum, stepsize)) / stepsize; 

    float rowStep = 1.0 / inputTileSize.x;
    float x = mod(lumStep, rowStep);
    float y = floor(lumStep / rowStep);
    
    vec2 startCoord = vec2(float(x) *  inputTileSize.x, float(y) * inputTileSize.y);
    vec2 finalCoord = startCoord + ((textureCoordinate - xy) * (inputTileSize / displayTileSize));
    
    vec4 color = texture2D(inputImageTexture, finalCoord);   
    if (colorOn == 1) {
        color = color * inputColor;
    }
    gl_FragColor = color; 
    
} 