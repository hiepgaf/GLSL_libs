
//Polarr 필터 모음. -> GLSL 파일로 정리해야함.

//uniform sampler2D u_image;\nvarying vec2 v_texCoord;\nvarying vec4 v_color;\n\nvoid main() {\n  gl_FragColor = texture2D(u_image, v_texCoord) * v_color;\n}

//ttribute vec2 a_position;\nattribute vec2 a_texCoord;\nattribute vec4 a_color;\nvarying vec2 v_texCoord;\nvarying vec4 v_color;\nuniform mat3 u_projMatrix;\n\nvoid main() {\n  gl_Position = vec4((u_projMatrix * vec3(a_position, 1)).xy, 0, 1);\n  v_texCoord = a_texCoord;\n  v_color = vec4(a_color.rgb * a_color.a, a_color.a);\n}

///*!\n * Based on evanw's glfx.js tilt shift shader:\n * https://github.com/evanw/glfx.js/blob/master/src/filters/blur/tiltshift.js\n */\n\nuniform sampler2D u_image;\nuniform float u_blurRadius;\nuniform float u_gradientSize;\nuniform float u_size;\nuniform vec2 u_start;\nuniform vec2 u_end;\nuniform vec2 u_delta;\nuniform vec2 u_texSize;\nvarying vec2 v_texCoord;\n\nfloat random(vec2 co)\n{\n    highp float a = 12.9898;\n    highp float b = 78.233;\n    highp float c = 43758.5453;\n    highp float dt = dot(co.xy,vec2(a,b));\n    highp float sn = mod(dt, 3.14);\n    return fract(sin(sn) * c);\n}\n\nvoid main() {\n    vec4 color = vec4(0.0);\n    float total = 0.0;\n\n    float offset = random(gl_FragCoord.xy / u_texSize.xy);\n\n    vec2 normal = normalize(vec2(u_start.y - u_end.y, u_end.x - u_start.x));\n    float radius = smoothstep(0.0, 1.0,\n      (abs(\n        dot(v_texCoord * u_texSize - u_start, normal)\n      ) - u_size) / u_gradientSize\n    ) * u_blurRadius;\n\n    for (float t = -30.0; t <= 30.0; t++) {\n        float percent = (t + offset - 0.5) / 30.0;\n        float weight = 1.0 - abs(percent);\n        vec4 sample = texture2D(u_image, v_texCoord + u_delta * percent * radius / u_texSize);\n\n        sample.rgb *= sample.a;\n\n        color += sample * weight;\n        total += weight;\n    }\n\n    gl_FragColor = color / total;\n    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;\n}

///*!\n * Based on evanw's glfx.js tilt shift shader:\n * https://github.com/evanw/glfx.js/blob/master/src/filters/blur/tiltshift.js\n */\n\nuniform sampler2D u_image;\nuniform float u_radius;\nuniform float u_blurRadius;\nuniform float u_gradientRadius;\nuniform vec2 u_position;\nuniform vec2 u_delta;\nuniform vec2 u_texSize;\nvarying vec2 v_texCoord;\n\nfloat random(vec2 co)\n{\n    highp float a = 12.9898;\n    highp float b = 78.233;\n    highp float c = 43758.5453;\n    highp float dt = dot(co.xy,vec2(a,b));\n    highp float sn = mod(dt, 3.14);\n    return fract(sin(sn) * c);\n}\n\nvoid main() {\n    vec4 color = vec4(0.0);\n    float total = 0.0;\n\n    float offset = random(gl_FragCoord.xy / u_texSize.xy);\n    float radius = smoothstep(\n      0.0, 1.0,\n      (abs(\n        distance(v_texCoord * u_texSize, u_position)\n      ) - u_radius) / (u_gradientRadius * 2.0)\n    ) * u_blurRadius;\n    for (float t = -30.0; t <= 30.0; t++) {\n        float percent = (t + offset - 0.5) / 30.0;\n        float weight = 1.0 - abs(percent);\n        vec4 sample = texture2D(u_image, v_texCoord + u_delta * percent * radius / u_texSize);\n\n        sample.rgb *= sample.a;\n\n        color += sample * weight;\n        total += weight;\n    }\n\n    gl_FragColor = color / total;\n    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_brightness;\nuniform float u_saturation;\nuniform float u_contrast;\nuniform float u_gamma;\nuniform float u_exposure;\nuniform float u_shadows;\nuniform float u_highlights;\n\nconst vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n\n  vec4 color = texColor;\n  float luminance = dot(color.rgb, luminanceWeighting);\n\n  // apply shadows and highlights\n  float shadow = clamp((pow(luminance, 1.0/(u_shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(u_shadows+1.0))) - luminance, 0.0, 1.0);\n  float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-u_highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-u_highlights)))) - luminance, -1.0, 0.0);\n  color.rgb = (luminance + shadow + highlight) * (color.rgb / luminance );\n\n  // Apply exposure\n  color.rgb = color.rgb * pow(2.0, u_exposure);\n\n  // Apply brightness\n  color.rgb = (color.rgb + u_brightness);\n\n  // Apply saturation\n  vec3 greyScaleColor = vec3(luminance);\n  color.rgb = mix(greyScaleColor, color.rgb, u_saturation);\n\n  // Apply contrast\n  color.rgb = (color.rgb - 0.5) * u_contrast + 0.5;\n\n  // Apply gamma\n  color.rgb = pow(color.rgb, vec3(u_gamma));\n\n  // Apply alpha\n  color = vec4(color.rgb * texColor.a, texColor.a);\n\n  gl_FragColor = color;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform sampler2D u_filteredImage;\nuniform float u_intensity;\n\nvoid main() {\n  vec4 color0 = texture2D(u_image, v_texCoord);\n  vec4 color1 = texture2D(u_filteredImage, v_texCoord);\n  gl_FragColor = mix(color0, color1, u_intensity);\n}

///*!\n * Based on evanw's glfx.js tilt shift shader:\n * https://github.com/evanw/glfx.js/blob/master/src/filters/blur/tiltshift.js\n */\n\nuniform sampler2D u_image;\nuniform float u_blurRadius;\nuniform vec2 u_delta;\nuniform vec2 u_texSize;\nvarying vec2 v_texCoord;\n\nfloat random(vec2 co)\n{\n    highp float a = 12.9898;\n    highp float b = 78.233;\n    highp float c = 43758.5453;\n    highp float dt = dot(co.xy,vec2(a,b));\n    highp float sn = mod(dt, 3.14);\n    return fract(sin(sn) * c);\n}\n\nvoid main() {\n    vec4 color = vec4(0.0);\n    float total = 0.0;\n\n    float offset = random(gl_FragCoord.xy / u_texSize.xy);\n\n    float radius = u_blurRadius;\n\n    for (float t = -30.0; t <= 30.0; t++) {\n        float percent = (t + offset - 0.5) / 30.0;\n        float weight = 1.0 - abs(percent);\n        vec4 sample = texture2D(u_image, v_texCoord + u_delta * percent * radius / u_texSize);\n\n        sample.rgb *= sample.a;\n\n        color += sample * weight;\n        total += weight;\n    }\n\n    gl_FragColor = color / total;\n    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_clarity;\nuniform vec2 u_texSize;\n\nfloat random(vec3 scale, float seed) {\n  return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);\n}\n\nvoid main() {\n  vec4 original = texture2D(u_image, v_texCoord);\n\n  vec4 color = texture2D(u_image, v_texCoord);\n  color +=  texture2D(u_image, v_texCoord + vec2(-1.0, 0.0) * u_texSize);\n  color +=  texture2D(u_image, v_texCoord + vec2(1.0, 0.0) * u_texSize);\n\n  color +=  texture2D(u_image, v_texCoord + vec2(0.0, 1.0) * u_texSize);\n  color +=  texture2D(u_image, v_texCoord + vec2(-1.0, 1.0) * u_texSize);\n  color +=  texture2D(u_image, v_texCoord + vec2(1.0, 1.0) * u_texSize);\n\n  color +=  texture2D(u_image, v_texCoord + vec2(0.0, -1.0) * u_texSize);\n  color +=  texture2D(u_image, v_texCoord + vec2(-1.0, -1.0) * u_texSize);\n  color +=  texture2D(u_image, v_texCoord + vec2(1.0, -1.0) * u_texSize);\n\n  // apply unsharp mask\n  vec4 blurred = color / 9.0;\n  color = mix(blurred, original, 1.0 + u_clarity);\n\n  // desaturation, to emphesize the effect\n  vec3 grayXfer = vec3(0.3, 0.59, 0.11);\n  vec3 gray = vec3(dot(grayXfer, color.xyz));\n  float desaturation = clamp(u_clarity * 0.13, 0.0, 1.0);\n  gl_FragColor = vec4(mix(color.xyz, gray, desaturation) * color.a, color.a);\n};

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform sampler2D u_filterImage;\nuniform sampler2D u_maskImage;\n\nvoid main() {\n  vec4 color0 = texture2D(u_image, v_texCoord);\n  vec4 color1 = texture2D(u_filterImage, v_texCoord);\n  vec4 mask = texture2D(u_maskImage, v_texCoord);\n  gl_FragColor = mix(color0, color1, mask);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform sampler2D u_frameImage;\nuniform vec4 u_color;\nuniform float u_thickness;\nuniform vec2 u_textureSize;\n\nvoid main() {\n  vec4 fragColor = texture2D(u_image, v_texCoord);\n  float scaledThicknessX = u_thickness / u_textureSize.x;\n  float scaledThicknessY = u_thickness / u_textureSize.y;\n  if (v_texCoord.x < scaledThicknessX ||\n    v_texCoord.x > 1.0 - scaledThicknessX ||\n    v_texCoord.y < scaledThicknessY || v_texCoord.y > 1.0 - scaledThicknessY) {\n      fragColor = mix(fragColor, u_color, u_color.a);\n    }\n\n  gl_FragColor = fragColor;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_brightness;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  gl_FragColor = vec4((texColor.rgb + vec3(u_brightness) * texColor.a), texColor.a);;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform mat4 u_colormatrix;\nuniform vec4 u_colormatrix_vec;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  gl_FragColor = texColor * u_colormatrix + u_colormatrix_vec;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_contrast;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  gl_FragColor = vec4(((texColor.rgb - vec3(0.5)) * u_contrast + vec3(0.5) * texColor.a), texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_desaturation;\n\nconst vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  vec3 grayXfer = vec3(0.3, 0.59, 0.11);\n  vec3 gray = vec3(dot(grayXfer, texColor.xyz));\n  gl_FragColor = vec4(mix(texColor.xyz, gray, u_desaturation) * texColor.a, texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform vec3 u_gamma;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  vec3 rgb = vec3(texColor.r, texColor.g, texColor.b);\n  rgb = pow(rgb, u_gamma);\n  gl_FragColor = vec4(rgb * texColor.a, texColor.a);;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\n\nuniform vec3 u_color;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n\n  vec2 textureCoord = v_texCoord - vec2(0.5, 0.5);\n  textureCoord /= 0.75;\n\n  float d = 1.0 - dot(textureCoord, textureCoord);\n  d = clamp(d, 0.2, 1.0);\n  vec3 newColor = texColor.rgb * d * u_color.rgb;\n  gl_FragColor = vec4(vec3(newColor) * texColor.a, texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  texColor.b = texColor.g * 0.33;\n  texColor.r = texColor.r * 0.6;\n  texColor.b += texColor.r * 0.33;\n  texColor.g = texColor.g * 0.7;\n  gl_FragColor = texColor;\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nvec3 W = vec3(0.2125, 0.7154, 0.0721);\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  float luminance = dot(texColor.rgb, W);\n  gl_FragColor = vec4(vec3(luminance) * texColor.a, texColor.a);\n}

///**\n * Based off of GPUImage's LookupFilter:\n * https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageLookupFilter.m\n */\n\nvarying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform sampler2D u_lookupTable;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  float blueColor = texColor.b * 63.0;\n\n  vec2 quad1;\n  quad1.y = floor(floor(blueColor) / 8.0);\n  quad1.x = floor(blueColor) - (quad1.y * 8.0);\n\n  vec2 quad2;\n  quad2.y = floor(ceil(blueColor) / 8.0);\n  quad2.x = ceil(blueColor) - (quad2.y * 8.0);\n\n  vec2 texCoord1;\n  texCoord1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * texColor.r);\n  texCoord1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * texColor.g);\n\n  vec2 texCoord2;\n  texCoord2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * texColor.r);\n  texCoord2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * texColor.g);\n\n  vec4 newColor1 = texture2D(u_lookupTable, texCoord1);\n  vec4 newColor2 = texture2D(u_lookupTable, texCoord2);\n\n  vec4 newColor = mix(newColor1, newColor2, fract(blueColor));\n  gl_FragColor = mix(texColor, vec4(newColor.rgb, texColor.w), texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform sampler2D u_lookupTable;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  float r = texture2D(u_lookupTable, vec2(texColor.r, 0.0)).r;\n  float g = texture2D(u_lookupTable, vec2(texColor.g, 0.0)).g;\n  float b = texture2D(u_lookupTable, vec2(texColor.b, 0.0)).b;\n\n  gl_FragColor = vec4(vec3(r, g, b) * texColor.a, texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform float u_saturation;\n\nconst vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  float luminance = dot(texColor.rgb, luminanceWeighting);\n\n  vec3 greyScaleColor = vec3(luminance);\n\n  gl_FragColor = vec4(mix(greyScaleColor, texColor.rgb, u_saturation) * texColor.a, texColor.a);\n}

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\nuniform vec3 u_color;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  vec4 overlayVec4 = vec4(u_color, texColor.a);\n  gl_FragColor = max(overlayVec4 * texColor.a, texColor);\n}\

//varying vec2 v_texCoord;\nuniform sampler2D u_image;\n\nvoid main() {\n  vec4 texColor = texture2D(u_image, v_texCoord);\n  float gray = texColor.r * 0.3 + texColor.g * 0.3 + texColor.b * 0.3;\n  gray -= 0.2;\n  gray = clamp(gray, 0.0, 1.0);\n  gray += 0.15;\n  gray *= 1.4;\n  gl_FragColor = vec4(vec3(gray) * texColor.a, texColor.a);\n}