float generateNoise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = TexCoord;
    vec2 texelSize = 1.0 / textureSize(InputTexture, 0);
    
    float internalChromatic = chromaticAberration * 0.0015;
    float internalGrain = grainIntensity * 0.015;
    
    // AMD Contrast Adaptive Sharpening (CAS) Execution Loop
    vec3 c = texture(InputTexture, uv).rgb;
    vec3 l = texture(InputTexture, uv + vec2(-texelSize.x, 0.0)).rgb;
    vec3 r = texture(InputTexture, uv + vec2(texelSize.x, 0.0)).rgb;
    vec3 t = texture(InputTexture, uv + vec2(0.0, -texelSize.y)).rgb;
    vec3 b = texture(InputTexture, uv + vec2(0.0, texelSize.y)).rgb;
    
    float l_c = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float l_l = dot(l, vec3(0.2126, 0.7152, 0.0722));
    float l_r = dot(r, vec3(0.2126, 0.7152, 0.0722));
    float l_t = dot(t, vec3(0.2126, 0.7152, 0.0722));
    float l_b = dot(b, vec3(0.2126, 0.7152, 0.0722));
    
    float min_l = min(l_c, min(min(l_l, l_r), min(l_t, l_b)));
    float max_l = max(l_c, max(max(l_l, l_r), max(l_t, l_b)));
    
    float amp = clamp(min(min_l, 1.0 - max_l) / max_l, 0.0, 1.0);
    float w = amp * (-1.0 / mix(8.0, 5.0, casSharpness * 0.20));
    
    vec3 sharpened = (w * (l + r + t + b) + c) / (4.0 * w + 1.0);
    vec3 workingColor = mix(c, sharpened, clamp(casSharpness, 0.0, 1.0));
    
    // Spectral Lens Chromatic Aberration Dispersion
    vec2 dispersionDir = (uv - 0.5);
    vec3 chromaticColor;
    chromaticColor.r = texture(InputTexture, uv - dispersionDir * internalChromatic).r;
    chromaticColor.g = workingColor.g; 
    chromaticColor.b = texture(InputTexture, uv + dispersionDir * internalChromatic).b;
    
    // Hollywood Lift, Gamma, Gain (LGG) Color Grading Levels
    vec3 lggColor = chromaticColor * (1.0 - liftVal) + liftVal;
    lggColor = pow(max(lggColor, vec3(0.0)), vec3(gammaVal));
    lggColor = lggColor * gainVal;
    
    // Filmic Camera Lens Corner Vignetting
    vec2 windowBounds = uv * (1.0 - uv.yx);
    float vignettePower = windowBounds.x * windowBounds.y * 15.0;
    vignettePower = pow(vignettePower, vignetteIntensity);
    lggColor *= clamp(vignettePower, 0.0, 1.0);
    
    // High-Frequency Noise Grain Channel Mixed Vector
    float dynamicSeed = generateNoise(uv + vec2(fract(timer * 0.097), fract(timer * 0.123)));
    vec3 noiseGrain = vec3(dynamicSeed - 0.5) * internalGrain;
    lggColor += noiseGrain;

    FragColor = vec4(clamp(lggColor, 0.0, 1.0), texture(InputTexture, uv).a);
}