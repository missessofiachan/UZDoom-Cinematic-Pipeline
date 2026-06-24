vec3 aces_original(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

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
    vec3 whiteScale = 1.0 / HableOperator(vec3(11.2));
    return clamp(curr * whiteScale, 0.0, 1.0);
}

vec3 aces_fitted(vec3 color) {
    const mat3 inputMatrix = mat3(
        0.59719, 0.35458, 0.04823,
        0.07608, 0.90834, 0.01558,
        0.02840, 0.13383, 0.83777
    );
    const mat3 outputMatrix = mat3(
        1.60475, -0.53108, -0.07367,
        -0.10208,  1.10813, -0.00605,
        -0.00327, -0.07276,  1.07602
    );
    vec3 v = inputMatrix * color;
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.432951) + 0.238081;
    return clamp(outputMatrix * (a / b), 0.0, 1.0);
}

vec3 agx_filmic(vec3 val) {
    const mat3 agx_mat = mat3(
        0.842479, 0.042328, 0.115192,
        0.087676, 0.871981, 0.040342,
        0.013054, 0.085521, 0.901424
    );
    vec3 col = agx_mat * val;
    col = clamp((log2(max(col, vec3(0.0001))) + 10.0) / 16.0, 0.0, 1.0);
    vec3 curve = col * col * (3.0 - 2.0 * col);
    const mat3 agx_inv_mat = mat3(
        1.196822, -0.052897, -0.143925,
        -0.121171,  1.151978, -0.030807,
        -0.024103, -0.076326,  1.100430
    );
    return clamp(agx_inv_mat * curve, 0.0, 1.0);
}

vec3 khronos_neutral(vec3 color) {
    float startCompression = 0.76;
    float x = max(color.r, max(color.g, color.b));
    if (x < startCompression) return color;
    float d = x - startCompression;
    float newX = startCompression + d / (1.0 + d);
    return color * (newX / x);
}

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
    
    if (splitScreen == 1 && TexCoord.x > 0.5) {
        color = texel.rgb;
        if (TexCoord.x < 0.502) {
            color = vec3(0.5);
        }
    } else {
        vec3 hdrColor = SDRtoHDR(texel.rgb);
        float luma = dot(hdrColor, vec3(0.2126, 0.7152, 0.0722));
        float logLum = log2(max(luma, 0.0001));
        
        logLum += log2(max(exposure * tonemapExposure, 0.0001));
        hdrColor *= exp2(logLum - log2(max(luma, 0.0001)));
        
        vec3 preTonemapColor = hdrColor;
        
        if (tonemapMode == 1) {
            vec3 num = hdrColor * (vec3(1.0) + (hdrColor / (reinhardBurn * reinhardBurn)));
            vec3 den = vec3(1.0) + hdrColor;
            hdrColor = clamp(num / den, 0.0, 1.0);
        } else if (tonemapMode == 2) {
            hdrColor = aces_original(hdrColor); 
        } else if (tonemapMode == 3) {
            hdrColor = filmicHable(hdrColor);
        } else if (tonemapMode == 4) {
            hdrColor = aces_fitted(hdrColor);
        } else if (tonemapMode == 5) {
            hdrColor = agx_filmic(hdrColor);
        } else if (tonemapMode == 6) {
            hdrColor = khronos_neutral(hdrColor);
        }
        
        hdrColor = mix(preTonemapColor, hdrColor, tonemapStrength);
        color = HDRtoSDR(hdrColor);
        
        color = (color - 0.5) * filmContrast + 0.5;
        float sdrLuma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        color = mix(vec3(sdrLuma), color, filmSaturation);
        
        color = clamp(color, 0.0, 1.0);
        if (splitScreen == 1 && TexCoord.x > 0.498) {
            color = vec3(0.5);
        }
    }
    
    FragColor = vec4(color, texel.a);
}