#extension GL_ARB_shading_language_420pack : enable
layout(binding = 1) uniform sampler2D DepthTexture;

void main() {
    vec2 texelSize = 1.0 / textureSize(InputTexture, 0);
    float depth = texture(DepthTexture, TexCoord).r;
    float occlusion = 0.0;
    
    // Quick 4-tap offset for performance
    vec2 offsets[4] = vec2[](
        vec2(-1.0, -1.0), vec2(1.0, -1.0),
        vec2(-1.0, 1.0), vec2(1.0, 1.0)
    );
    
    for (int i = 0; i < 4; ++i) {
        vec2 sampleTex = TexCoord + (offsets[i] * texelSize * radius * 10.0);
        float sampleDepth = texture(DepthTexture, sampleTex).r;
        // Calculate depth difference
        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(depth - sampleDepth));
        occlusion += (sampleDepth < depth - 0.001 ? 1.0 : 0.0) * rangeCheck;
    }
    
    occlusion = 1.0 - (occlusion / 4.0) * intensity;
    FragColor = vec4(texture(InputTexture, TexCoord).rgb * occlusion, 1.0);
}