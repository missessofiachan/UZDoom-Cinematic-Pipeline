#extension GL_ARB_shading_language_420pack : enable
layout(binding = 1) uniform sampler2D DepthTexture;

void main() {
    float depth = texture(DepthTexture, TexCoord).r;
    vec2 texelSize = 1.0 / textureSize(InputTexture, 0);
    vec4 baseColor = texture(InputTexture, TexCoord);
    
    // Calculate how far out of focus this pixel is
    float blurFactor = abs(depth - focusDistance) * blurAmount;
    blurFactor = clamp(blurFactor, 0.0, 2.0); // Cap max blur
    
    if (blurFactor < 0.1) {
        FragColor = baseColor;
        return;
    }

    vec3 blurredColor = vec3(0.0);
    float weightSum = 0.0;
    
    // Simple 9-tap box blur scaled by depth difference
    for(float x = -1.0; x <= 1.0; x++) {
        for(float y = -1.0; y <= 1.0; y++) {
            vec2 offset = vec2(x, y) * texelSize * blurFactor * 4.0;
            blurredColor += texture(InputTexture, TexCoord + offset).rgb;
            weightSum += 1.0;
        }
    }
    
    FragColor = vec4(blurredColor / weightSum, baseColor.a);
}