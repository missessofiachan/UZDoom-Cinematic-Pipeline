void main() {
    vec2 tc = TexCoord;
    vec2 lightPos = vec2(0.5, 0.5); // Emits from center screen
    vec2 deltaTextCoord = (tc - lightPos) * (1.0 / float(16)) * density;
    
    vec4 color = texture(InputTexture, tc);
    float illuminationDecay = 1.0;
    
    for(int i = 0; i < 16; i++) {
        tc -= deltaTextCoord;
        vec4 sampleColor = texture(InputTexture, tc);
        // Extract bright spots
        float luma = dot(sampleColor.rgb, vec3(0.2126, 0.7152, 0.0722));
        if(luma > 0.8) {
            sampleColor *= illuminationDecay * weight;
            color += sampleColor;
        }
        illuminationDecay *= decay;
    }
    FragColor = color;
}
