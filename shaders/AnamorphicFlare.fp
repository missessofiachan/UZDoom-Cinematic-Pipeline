void main() {
    vec4 baseTexel = texture(InputTexture, TexCoord);
    vec3 baseColor = baseTexel.rgb;
    
    vec2 texelSize = 1.0 / textureSize(InputTexture, 0);
    vec3 flareColor = vec3(0.0);
    float accumulatedWeight = 0.0;
    
    // 9-Tap Horizontal Blur Sweep for anamorphic streak distribution
    float sampleOffsets[9] = float[](-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0);
    
    for(int i = 0; i < 9; i++) {
        vec2 sampleUV = TexCoord + vec2(sampleOffsets[i] * texelSize.x * flareStretch * 2.5, 0.0);
        vec3 sampledColor = texture(InputTexture, sampleUV).rgb;
        
        float luma = dot(sampledColor, vec3(0.2126, 0.7152, 0.0722));
        float thresholdFactor = clamp((luma - bloomThreshold) / (1.0 - bloomThreshold + 0.0001), 0.0, 1.0);
        vec3 extractedBright = sampledColor * thresholdFactor;
        
        float gaussianWeight = exp(-0.5 * (sampleOffsets[i] * sampleOffsets[i]) / 2.0);
        flareColor += extractedBright * gaussianWeight;
        accumulatedWeight += gaussianWeight;
    }
    
    vec3 balancedFlare = flareColor / max(accumulatedWeight, 0.0001);
    
    // Apply cinema-style sci-fi anamorphic blue color tinting matrix
    vec3 tintedFlare = balancedFlare * vec3(0.4, 0.65, 1.4) * flareIntensity;
    
    FragColor = vec4(clamp(baseColor + tintedFlare, 0.0, 1.0), baseTexel.a);
}