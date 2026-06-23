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
        // Left side or full screen is adapted and optionally tone-mapped
        color = texel.rgb * exposure;
        
        // 1. Pre-Tonemap Exposure Bias
        color *= tonemapExposure;
        
        // 2. Tone-mapping Curve
        if (tonemapMode == 1) {
            // Reinhard with white-point/burn parameter
            vec3 num = color * (vec3(1.0) + (color / (reinhardBurn * reinhardBurn)));
            vec3 den = vec3(1.0) + color;
            color = clamp(num / den, 0.0, 1.0);
        } else if (tonemapMode == 2) {
            // ACES
            color = aces(color);
        } else if (tonemapMode == 3) {
            // Hable Filmic
            color = filmicHable(color);
        }
        
        // 3. Post-Tonemap Contrast
        color = (color - 0.5) * filmContrast + 0.5;
        
        // 4. Post-Tonemap Saturation
        float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        color = mix(vec3(luma), color, filmSaturation);
        
        color = clamp(color, 0.0, 1.0);
        
        // Draw separator line if split screen is enabled
        if (splitScreen == 1 && TexCoord.x > 0.498) {
            color = vec3(0.5);
        }
    }
    
    FragColor = vec4(color, texel.a);
}
