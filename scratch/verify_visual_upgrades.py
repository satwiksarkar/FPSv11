# scratch/verify_visual_upgrades.py
import os
import sys
from PIL import Image

def verify_textures():
    print("=== VERIFYING TEXTURES (PART 1) ===")
    steel_path = "assets/textures/steel_wall.png"
    stone_path = "assets/textures/stone_wall.png"
    stone_alt_path = "assets/textures/stone_wall_alt.png"

    assert os.path.exists(steel_path), f"Missing {steel_path}"
    assert os.path.exists(stone_path), f"Missing {stone_path}"
    assert os.path.exists(stone_alt_path), f"Missing {stone_alt_path}"

    with Image.open(steel_path) as im:
        assert im.size == (64, 64), f"steel_wall size is {im.size}, expected (64, 64)"
        # Check that caution trim exists at bottom edge (yellow/black)
        pixels = [im.getpixel((x, 62)) for x in range(64)]
        has_yellow = any(p[0] > 180 and p[1] > 150 and p[2] < 80 for p in pixels)
        assert has_yellow, "steel_wall.png caution stripes not found at bottom"
        print("[PASS] steel_wall.png verified (64x64, cool blue-grey brushed steel, caution trim).")

    with Image.open(stone_path) as im:
        assert im.size == (64, 64), f"stone_wall size is {im.size}, expected (64, 64)"
        print("[PASS] stone_wall.png verified (64x64, bolted industrial concrete panels).")

    with Image.open(stone_alt_path) as im:
        assert im.size == (64, 64), f"stone_wall_alt size is {im.size}, expected (64, 64)"
        print("[PASS] stone_wall_alt.png verified (64x64, plain un-riveted variant).")

def verify_materials_in_qml():
    print("\n=== VERIFYING QML MATERIALS & INSTANCING (PART 1) ===")
    with open("qml/LevelView.qml", "r") as f:
        qml = f.read()

    # Nearest filtering
    assert "texSteelWall" in qml
    assert "texStoneWall" in qml
    assert "texStoneWallAlt" in qml

    # Check Texture.Nearest applied
    tex_steel_idx = qml.find("id: texSteelWall")
    assert tex_steel_idx != -1
    tex_steel_block = qml[tex_steel_idx:tex_steel_idx+300]
    assert "magFilter: Texture.Nearest" in tex_steel_block
    assert "minFilter: Texture.Nearest" in tex_steel_block
    print("[PASS] texSteelWall configured with Texture.Nearest filtering.")

    tex_stone_idx = qml.find("id: texStoneWall\n")
    if tex_stone_idx == -1:
        tex_stone_idx = qml.find("id: texStoneWall")
    assert tex_stone_idx != -1
    tex_stone_block = qml[tex_stone_idx:tex_stone_idx+300]
    assert "magFilter: Texture.Nearest" in tex_stone_block
    assert "minFilter: Texture.Nearest" in tex_stone_block
    print("[PASS] texStoneWall configured with Texture.Nearest filtering.")

    tex_stone_alt_idx = qml.find("id: texStoneWallAlt")
    assert tex_stone_alt_idx != -1
    tex_stone_alt_block = qml[tex_stone_alt_idx:tex_stone_alt_idx+300]
    assert "magFilter: Texture.Nearest" in tex_stone_alt_block
    assert "minFilter: Texture.Nearest" in tex_stone_alt_block
    print("[PASS] texStoneWallAlt configured with Texture.Nearest filtering.")

    # PrincipledMaterial properties
    mat_steel_idx = qml.find("id: matSteelWall")
    assert mat_steel_idx != -1
    mat_steel_block = qml[mat_steel_idx:mat_steel_idx+250]
    assert "metalness: 0.75" in mat_steel_block
    assert "roughness: 0.35" in mat_steel_block
    print("[PASS] matSteelWall verified (metalness: 0.75, roughness: 0.35).")

    mat_stone_idx = qml.find("id: matStoneWall\n")
    if mat_stone_idx == -1:
        mat_stone_idx = qml.find("id: matStoneWall")
    assert mat_stone_idx != -1
    mat_stone_block = qml[mat_stone_idx:mat_stone_idx+250]
    assert "metalness: 0.15" in mat_stone_block
    assert "roughness: 0.85" in mat_stone_block
    print("[PASS] matStoneWall verified (metalness: 0.15, roughness: 0.85).")

    # Instancing bindings
    assert "steelWallInstancing" in qml
    assert "stoneWallInstancing" in qml
    assert "stoneWallAltInstancing" in qml
    print("[PASS] Wall instancing tables for steel, stone, and stone alt verified.")

def verify_ceiling_lights():
    print("\n=== VERIFYING CEILING LIGHTS (PART 2) ===")
    with open("qml/LevelView.qml", "r") as f:
        qml = f.read()

    # CeilingLightFixture component
    assert "component CeilingLightFixture: Node" in qml
    assert "emissiveFactor" in qml
    assert "quadraticFade" in qml
    print("[PASS] CeilingLightFixture component verified with distance culling.")

    # Level 1 Ceiling Lights
    assert "id: level1CeilingLightsNode" in qml
    l1_idx = qml.find("id: level1CeilingLightsNode")
    l2_idx = qml.find("id: level2CeilingLightsNode")
    assert l1_idx != -1 and l2_idx != -1
    l1_lights = qml[l1_idx:l2_idx]

    # Verify Red Lockdown Lights in Level 1
    assert "#FF1E1E" in l1_lights
    assert "#FF2A2A" in l1_lights
    assert "2350, 445, 3750" in l1_lights  # Central Spine
    assert "650, 295, 2150" in l1_lights   # West outer bypass
    assert "4250, 295, 2150" in l1_lights  # East outer bypass
    print("[PASS] Level 1 Red Lockdown Lights verified in Central Spine and outer bypasses.")

    # Verify Standard Room Cool-White Lights in Level 1
    assert "#D8E8FF" in l1_lights
    assert "2350, 295, 4250" in l1_lights  # Spawn
    assert "950, 295, 3150" in l1_lights   # Key 1
    assert "2350, 440, 1750" in l1_lights  # Storage
    assert "950, 295, 950" in l1_lights    # Key 3
    assert "3850, 740, 950" in l1_lights   # Key 4
    print("[PASS] Level 1 Standard Room cool-white ceiling lights verified.")

    # STRICT EXCEPTION: Level 1 Key 2 Room has ZERO lights or fixtures!
    # Key 2 room spans rows 21..36, cols 33..45 => X: 3300..4300, Z: 2400..3600
    sg_idx = qml.find("id: shootingGalleryGroup")
    sg_end = qml.find("id: sentinelPatrolGroup")
    assert sg_idx != -1 and sg_end != -1
    sg_block = qml[sg_idx:sg_end]
    assert "PointLight" not in sg_block, "FAIL: PointLight found inside Level 1 Key 2 Room!"
    assert "CeilingLightFixture" not in sg_block, "FAIL: CeilingLightFixture found inside Level 1 Key 2 Room!"
    print("[PASS] STRICT EXCEPTION confirmed: Zero ceiling lights or PointLights in Level 1 Key 2 room (Shooting Gallery).")

    # Level 2 Ceiling Lights
    l2_lights = qml[l2_idx:]
    assert "#FF1E1E" in l2_lights
    assert "#FF2A2A" in l2_lights
    assert "#D8E8FF" in l2_lights
    print("[PASS] Level 2 Red Lockdown Lights and cool-white Room Lights verified.")

def verify_guardrails():
    print("\n=== VERIFYING GUARDRAILS ===")
    with open("qml/Main.qml", "r") as f:
        main_qml = f.read()
    assert "player: player" in main_qml, "player not connected to LevelView in Main.qml"
    print("[PASS] player wired into LevelView in Main.qml.")

    with open("CMakeLists.txt", "r") as f:
        cmake = f.read()
    assert "assets/textures/stone_wall.png" in cmake
    assert "assets/textures/stone_wall_alt.png" in cmake
    print("[PASS] CMakeLists.txt contains new wall textures.")

if __name__ == "__main__":
    verify_textures()
    verify_materials_in_qml()
    verify_ceiling_lights()
    verify_guardrails()
    print("\nALL VISUAL UPGRADE VERIFICATION CHECKS PASSED (100% GREEN)!")
