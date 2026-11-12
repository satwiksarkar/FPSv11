VARYING vec2 vScreenUV;
VARYING vec2 vCenterOffset;

void MAIN()
{
    vScreenUV = INPUT_UV;
    vec2 offset = INPUT_UV - vec2(0.5, 0.5);
    // Aspect ratio correction so vignette and flashlight cone are circular, not stretched
    offset.x *= (INPUT_SIZE.x / max(1.0, INPUT_SIZE.y));
    vCenterOffset = offset;
}
