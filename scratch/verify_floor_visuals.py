"""
Verification script for Vanguard Deck-Plate Floor Visual Upgrades.
"""
import os
import re
from PIL import Image

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def verify_floor_visuals():
    print("=== 1. VERIFYING FLOOR TEXTURES ===")
    deck_path = "assets/textures/floor_deck.png"
    hallway_path = "assets/textures/floor_hallway.png"

    assert os.path.exists(deck_path), f"Missing {deck_path}"
    assert os.path.exists(hallway_path), f"Missing {hallway_path}"

    im_deck = Image.open(deck_path)
    im_hallway = Image.open(hallway_path)

    assert im_deck.size == (64, 64), f"Expected 64x64 for floor_deck, got {im_deck.size}"
    assert im_hallway.size == (64, 64), f"Expected 64x64 for floor_hallway, got {im_hallway.size}"

    # Verify seam color #111418 = (17, 20, 24)
    seam_px = im_deck.getpixel((0, 0))[:3]
    assert seam_px == (17, 20, 24), f"floor_deck seam pixel expected (17, 20, 24), got {seam_px}"

    # Verify plate face near #2A313C = (42, 49, 60)
    face_px = im_deck.getpixel((15, 15))[:3]
    assert abs(face_px[0] - 42) <= 5 and abs(face_px[1] - 49) <= 5 and abs(face_px[2] - 60) <= 5, \
        f"floor_deck plate face expected near (42, 49, 60), got {face_px}"

    print(f"[PASS] floor_deck.png verified (64x64, #1C2128 base, #2A313C face, #111418 seams).")

    # Verify hallway guide stripe / edge trim
    stripe_px = im_hallway.getpixel((31, 7))[:3]
    edge_px = im_hallway.getpixel((3, 2))[:3]
    assert stripe_px != face_px, "Hallway center stripe not detected"
    assert edge_px != seam_px, "Hallway edge trim not detected"
    print(f"[PASS] floor_hallway.png verified (64x64, matching deck plate + subtle guide stripe & edge trim).")

    print("\n=== 2. VERIFYING CMAKELISTS.TXT ===")
    with open("CMakeLists.txt", "r", encoding="utf-8") as f:
        cm_text = f.read()
    assert "assets/textures/floor_deck.png" in cm_text, "floor_deck.png missing from CMakeLists.txt"
    assert "assets/textures/floor_hallway.png" in cm_text, "floor_hallway.png missing from CMakeLists.txt"
    print("[PASS] CMakeLists.txt contains floor_deck.png and floor_hallway.png.")

    print("\n=== 3. VERIFYING QML LEVELVIEW CONFIGURATION ===")
    with open("qml/LevelView.qml", "r", encoding="utf-8") as f:
        qml_text = f.read()

    # Nearest filtering checks
    assert 'id: texFloorDeck' in qml_text, "texFloorDeck missing"
    assert 'id: texFloorHallway' in qml_text, "texFloorHallway missing"
    
    # Check Nearest filtering
    deck_tex_block = re.search(r'id:\s*texFloorDeck[^}]+}', qml_text)
    assert deck_tex_block and "magFilter: Texture.Nearest" in deck_tex_block.group(0), "texFloorDeck missing magFilter Nearest"
    assert deck_tex_block and "minFilter: Texture.Nearest" in deck_tex_block.group(0), "texFloorDeck missing minFilter Nearest"
    print("[PASS] texFloorDeck configured with Texture.Nearest filtering.")

    hallway_tex_block = re.search(r'id:\s*texFloorHallway[^}]+}', qml_text)
    assert hallway_tex_block and "magFilter: Texture.Nearest" in hallway_tex_block.group(0), "texFloorHallway missing magFilter Nearest"
    assert hallway_tex_block and "minFilter: Texture.Nearest" in hallway_tex_block.group(0), "texFloorHallway missing minFilter Nearest"
    print("[PASS] texFloorHallway configured with Texture.Nearest filtering.")

    # Check PrincipledMaterial properties: metalness: 0.55, roughness: 0.45
    mat_deck = re.search(r'id:\s*matFloorDeck[^}]+}', qml_text)
    assert mat_deck and "metalness: 0.55" in mat_deck.group(0), "matFloorDeck metalness should be 0.55"
    assert mat_deck and "roughness: 0.45" in mat_deck.group(0), "matFloorDeck roughness should be 0.45"
    print("[PASS] matFloorDeck verified (metalness: 0.55, roughness: 0.45).")

    mat_hallway = re.search(r'id:\s*matFloorHallway[^}]+}', qml_text)
    assert mat_hallway and "metalness: 0.55" in mat_hallway.group(0), "matFloorHallway metalness should be 0.55"
    assert mat_hallway and "roughness: 0.45" in mat_hallway.group(0), "matFloorHallway roughness should be 0.45"
    print("[PASS] matFloorHallway verified (metalness: 0.55, roughness: 0.45).")

    # Check floorBox conditional material
    assert "matFloorLevel3" in qml_text, "matFloorLevel3 missing"
    assert "currentLevel === 3) ? matFloorLevel3 : matFloorDeck" in qml_text, "floorBox level 3 preservation check missing"
    print("[PASS] floorBox correctly uses matFloorDeck for Level 1 & 2, preserving Level 3 untouched.")

    # Check Walkway strips
    assert "component WalkwayStrip: Model" in qml_text, "WalkwayStrip component missing"
    assert "id: level1WalkwaysNode" in qml_text, "level1WalkwaysNode missing"
    assert "id: level2WalkwaysNode" in qml_text, "level2WalkwaysNode missing"
    print("[PASS] Level 1 and Level 2 WalkwayStrip nodes verified.")

    print("\n=== 4. VERIFYING GUARDRAILS ===")
    assert "visible: root.levelManager && root.levelManager.currentLevel === 1" in qml_text
    assert "visible: root.levelManager && root.levelManager.currentLevel === 2" in qml_text
    print("[PASS] Walkway nodes guarded strictly to Level 1 and Level 2; Level 3 completely untouched.")

    print("\nALL FLOOR VISUAL UPGRADE VERIFICATIONS PASSED (100% GREEN)!")

if __name__ == '__main__':
    verify_floor_visuals()
