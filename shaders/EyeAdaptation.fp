// ACES filmic tone mapping operator approximation by Krzysztof Narkowicz
vec3 aces(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

// Hable (Uncharted 2) filmic tone mapping operator
vec3 HableOperator(vec3 x) {
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 filmicHable(vec3 x) {
    vec3 curr = HableOperator(x);
    vec3 whiteScale = 1.0 / HableOperator(vec3(11.2)); // W = 11.2
    return clamp(curr * whiteScale, 0.0, 1.0);
}

// Exposure Fusion Inspired HDR Workspace constants & helper functions
#define WHITEPOINT 12.0

vec3 SDRtoHDR(vec3 sdr) {
    float limit = 1.0 + exp2(-WHITEPOINT);
    return sdr / max(vec3(limit) - sdr, vec3(0.0001));
}

vec3 HDRtoSDR(vec3 hdr) {
    float limit = 1.0 + exp2(-WHITEPOINT);
    return (hdr * limit) / (vec3(1.0) + hdr);
}

void main() {
    vec4 texel = texture(InputTexture, TexCoord);
    
    vec3 color;
    
    // Decide if we are rendering split-screen comparison
    if (splitScreen == 1 && TexCoord.x > 0.5) {
        // Right side is direct raw LDR rendering
        color = texel.rgb;
        
        // Draw a separator line
        if (TexCoord.x < 0.502) {
            color = vec3(0.5);
        }
    } else {
        // Left side or full screen: transform raw color to HDR workspace
        vec3 hdrColor = SDRtoHDR(texel.rgb);
        
        // Apply exposure and tonemap exposure bias in log space for natural perception scaling
        float luma = dot(hdrColor, vec3(0.2126, 0.7152, 0.0722));
        float logLum = log2(max(luma, 0.0001));
        
        logLum += log2(max(exposure * tonemapExposure, 0.0001));
        hdrColor *= exp2(logLum - log2(max(luma, 0.0001)));
        
        // Tone-mapping Curve
        if (tonemapMode == 1) {
            // Reinhard with white-point/burn parameter
            vec3 num = hdrColor * (vec3(1.0) + (hdrColor / (reinhardBurn * reinhardBurn)));
            vec3 den = vec3(1.0) + hdrColor;
            hdrColor = clamp(num / den, 0.0, 1.0);
        } else if (tonemapMode == 2) {
            // ACES
            hdrColor = aces(hdrColor);
        } else if (tonemapMode == 3) {
            // Hable Filmic
            hdrColor = filmicHable(hdrColor);
        }
        
        // Convert HDR workspace back to SDR representation
        color = HDRtoSDR(hdrColor);
        
        // 3. Post-Tonemap Contrast
        color = (color - 0.5) * filmContrast + 0.5;
        
        // 4. Post-Tonemap Saturation
        float sdrLuma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        color = mix(vec3(sdrLuma), color, filmSaturation);
        
        color = clamp(color, 0.0, 1.0);
        
        // Draw separator line if split screen is enabled
        if (splitScreen == 1 && TexCoord.x > 0.498) {
            color = vec3(0.5);
        }
    }
    
    FragColor = vec4(color, texel.a);
}
