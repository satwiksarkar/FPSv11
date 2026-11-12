/**
 * @file dark_hallway.frag
 * @brief Balanced Atmospheric Hallway Darkness Post-Processing Fragment Shader.
 *
 * Provides a "kinda dark" atmospheric corridor look while keeping all walls,
 * doors, floors, and crates clearly visible and readable.
 */

VARYING vec2 vScreenUV;
VARYING vec2 vCenterOffset;

void MAIN()
{
    vec4 sceneColor = texture(INPUT, INPUT_UV);
    vec3 color = sceneColor.rgb;

    float distFromCenter = length(vCenterOffset);

    // 1. Gentle, subtle corridor vignette (soft edge falloff, never obscures walls)
    float vig = smoothstep(uVignetteRadius, uVignetteRadius - uVignetteSmoothness, distFromCenter);
    float vignetteFactor = mix(1.0 - uVignetteStrength, 1.0, vig);

    // 2. Tactical Flashlight / Headlamp Center Beam
    float flashlightBeam = 0.0;
    if (uFlashlightOn > 0.5) {
        float fDist = distFromCenter / max(0.01, uFlashlightRadius);
        if (fDist < 1.0) {
            float falloff = 1.0 - fDist;
            flashlightBeam = falloff * uFlashlightIntensity;
        }
    }

    // 3. Atmospheric Corridor Darkness with high minimum floor
    // Light modulation: dims the room slightly, boosted by flashlight
    float hallwayLight = (1.0 - uDarkness) + flashlightBeam;
    // CRITICAL: Floor clamped to 0.65 so geometry is NEVER pitch black or invisible!
    hallwayLight = clamp(hallwayLight * vignetteFactor, 0.65, 1.45);

    color *= hallwayLight;

    // 4. Subtle, gentle contrast curve (preserves all shadow texture details)
    color = pow(max(color, vec3(0.0)), vec3(uContrast));

    // 5. Subtle cool industrial tint in deep recesses
    vec3 shadowTint = vec3(0.94, 0.96, 1.02);
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color * shadowTint, color, clamp(lum * 1.8, 0.0, 1.0));

    // 6. Very subtle tactical visor scanlines (low opacity)
    if (uScanlines > 0.0) {
        float scanline = sin(INPUT_UV.y * INPUT_SIZE.y * 1.5) * 0.5 + 0.5;
        color *= (1.0 - uScanlines * 0.03 * (1.0 - scanline));
    }

    FRAGCOLOR = vec4(clamp(color, 0.0, 1.0), sceneColor.a);
}
