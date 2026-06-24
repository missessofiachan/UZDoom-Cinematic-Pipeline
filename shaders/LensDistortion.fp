void main() {
    // Transform coordinates to center-relative cartesian space [-0.5, 0.5]
    vec2 coordinateSpace = TexCoord - 0.5;
    float radialDistanceSquared = dot(coordinateSpace, coordinateSpace);
    
    // Cubic distortion factor calculations
    float distortionScale = 1.0 + (radialDistanceSquared * lensWarp * 0.6) + (radialDistanceSquared * radialDistanceSquared * lensWarp * 0.4);
    vec2 warpedCoordinates = coordinateSpace * distortionScale + 0.5;
    
    // Bound constraints output management
    if (warpedCoordinates.x < 0.0 || warpedCoordinates.x > 1.0 || warpedCoordinates.y < 0.0 || warpedCoordinates.y > 1.0) {
        FragColor = vec4(vec3(0.0), 1.0);
    } else {
        FragColor = texture(InputTexture, warpedCoordinates);
    }
}