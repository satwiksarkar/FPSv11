/**
 * @file dark_surface.frag
 * @brief CustomMaterial shader for dark subterranean corridor surfaces.
 *
 * Implements wrapped diffuse reflection (Half-Lambert) and a guaranteed
 * ambient floor so walls, crates, and floors look atmospheric and moody,
 * but NEVER pitch black or invisible.
 */

void MAIN()
{
    BASE_COLOR = texture(uBaseColorMap, TEXTURE_UV) * uColorTint;
    ROUGHNESS = uRoughness;
    METALNESS = uMetalness;
}

void AMBIENT_LIGHT()
{
    // Guaranteed ambient floor so wall textures and geometry remain distinctly visible
    vec3 minAmbient = vec3(0.35, 0.38, 0.44);
    vec3 ambient = max(TOTAL_AMBIENT_COLOR * uAmbientScale, minAmbient);
    DIFFUSE += BASE_COLOR.rgb * ambient;
}

void DIRECTIONAL_LIGHT()
{
    // Wrapped Half-Lambert diffuse so walls facing away from directional light are never pure black
    float NdotL = max(0.0, dot(normalize(NORMAL), TO_LIGHT_DIR));
    float wrapNdotL = NdotL * 0.65 + 0.35;
    DIFFUSE += BASE_COLOR.rgb * LIGHT_COLOR * (uDirLightScale * wrapNdotL);
}

void POINT_LIGHT()
{
    // Quadratic attenuation with wrapped response
    float NdotL = max(0.0, dot(normalize(NORMAL), TO_LIGHT_DIR));
    float wrapNdotL = NdotL * 0.70 + 0.30;
    DIFFUSE += BASE_COLOR.rgb * LIGHT_COLOR * LIGHT_ATTENUATION * (wrapNdotL * SHADOW_CONTRIB);
}

void SPOT_LIGHT()
{
    // Tactical flashlight illumination on surfaces
    float NdotL = max(0.0, dot(normalize(VAR_WORLD_NORMAL), TO_LIGHT_DIR));
    float wrapNdotL = NdotL * 0.70 + 0.30;
    DIFFUSE += BASE_COLOR.rgb * LIGHT_COLOR * LIGHT_ATTENUATION * SPOT_FACTOR * (wrapNdotL * SHADOW_CONTRIB);
}
