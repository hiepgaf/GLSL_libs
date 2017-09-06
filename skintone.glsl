varying highp vec2 textureCoordinate;
 
uniform sampler2D inputImageTexture;

// [-1;1] <=> [pink;orange]
uniform highp float skinToneAdjust; // will make reds more pink

// Other parameters
uniform mediump float skinHue;
uniform mediump float skinHueThreshold;
uniform mediump float maxHueShift;
uniform mediump float maxSaturationShift;
uniform int upperSkinToneColor;

// RGB <-> HSV conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
highp vec3 rgb2hsv(highp vec3 c)
{
    highp vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    highp vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    highp vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    highp float d = q.x - min(q.w, q.y);
    highp float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 
// HSV <-> RGB conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
highp vec3 hsv2rgb(highp vec3 c)
{
    highp vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    highp vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
 
// Main
void main ()
{
    
    // Sample the input pixel
    highp vec4 colorRGB = texture2D(inputImageTexture, textureCoordinate);
    
    // Convert color to HSV, extract hue
    highp vec3 colorHSV = rgb2hsv(colorRGB.rgb);
    highp float hue = colorHSV.x;
    
    // check how far from skin hue
    highp float dist = hue - skinHue;
    if (dist > 0.5)
        dist -= 1.0;
    if (dist < -0.5)
        dist += 1.0;
    dist = abs(dist)/0.5; // normalized to [0,1]
    
    // Apply Gaussian like filter
    highp float weight = exp(-dist*dist*skinHueThreshold);
    weight = clamp(weight, 0.0, 1.0);
    
    // Using pink/green, so only adjust hue
    if (upperSkinToneColor == 0) {
        colorHSV.x += skinToneAdjust * weight * maxHueShift;
    // Using pink/orange, so adjust hue < 0 and saturation > 0
    } else if (upperSkinToneColor == 1) {
        // We want more orange, so increase saturation
        if (skinToneAdjust > 0.0)
            colorHSV.y += skinToneAdjust * weight * maxSaturationShift;
        // we want more pinks, so decrease hue
        else
            colorHSV.x += skinToneAdjust * weight * maxHueShift;
    }

    // final color
    highp vec3 finalColorRGB = hsv2rgb(colorHSV.rgb);
    
    // display
    gl_FragColor = vec4(finalColorRGB, 1.0);
}