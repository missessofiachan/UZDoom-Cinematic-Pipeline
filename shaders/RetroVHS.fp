void main() {
    vec2 uv = TexCoord;
    
    // Wavy horizontal distortion based on timer
    float wave = sin(uv.y * 20.0 + timer * 5.0) * 0.002 * intensity;
    uv.x += wave;
    
    // RGB Channel Separation (Chromatic Aberration)
    float r = texture(InputTexture, uv + vec2(0.002 * intensity, 0.0)).r;
    float g = texture(InputTexture, uv).g;
    float b = texture(InputTexture, uv - vec2(0.002 * intensity, 0.0)).b;
    vec3 color = vec3(r, g, b);
    
    // Scanlines
    float scanline = sin(uv.y * 800.0) * 0.04 * intensity;
    color -= scanline;
    
    // Tape tracking noise band
    float noiseBand = sin(uv.y * 5.0 - timer * 2.0);
    if(noiseBand > 0.9) {
        color += (fract(sin(dot(uv + timer, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.2 * intensity;
    }
    
    FragColor = vec4(color, 1.0);
}