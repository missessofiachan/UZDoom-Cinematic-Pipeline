void main() {
    vec4 baseTexel = texture(InputTexture, TexCoord);
    vec3 baseColor = baseTexel.rgb;
    
    vec2 texelSize = 1.0 / textureSize(InputTexture, 0);
    vec3 bloomAccumulation = vec3(0.0);
    float totalWeight = 0.0;

    vec2 samples[16] = vec2[](
        vec2( 0.0,  1.0), vec2( 0.0, -1.0), vec2( 1.0,  0.0), vec2(-1.0,  0.0),
        vec2( 0.7,  0.7), vec2(-0.7, -0.7), vec2( 0.7, -0.7), vec2(-0.7,  0.7),
        vec2( 0.0,  2.0), vec2( 0.0, -2.0), vec2( 2.0,  0.0), vec2(-2.0,  0.0),
        vec2( 1.4,  1.4), vec2(-1.4, -1.4), vec2( 1.4, -1.4), vec2(-1.4,  1.4)
    );

    for (int i = 0; i < 16; i++) {
        vec2 offsetUV = TexCoord + samples[i] * texelSize * 4.2;
        vec3 sampleColor = texture(InputTexture, offsetUV).rgb;
        
        float sampleLuma = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
        float thresholdFactor = clamp((sampleLuma - bloomThreshold) / (1.0 - bloomThreshold + 0.0001), 0.0, 1.0);
        vec3 brightColor = sampleColor * thresholdFactor;
        
        float currentWeight = exp(-dot(samples[i], samples[i]) * 0.40);
        bloomAccumulation += brightColor * currentWeight;
        totalWeight += currentWeight;
    }

    vec3 finalGlow = bloomAccumulation / max(totalWeight, 0.0001);
    vec3 screenBlendedColor = baseColor + (finalGlow * bloomIntensity);
    
    FragColor = vec4(clamp(screenBlendedColor, 0.0, 1.0), baseTexel.a);
}