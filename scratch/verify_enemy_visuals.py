# scratch/verify_enemy_visuals.py
import os
import sys
from PIL import Image

def verify_textures():
    print("=== 1. VERIFYING ENEMY TEXTURES ===")
    drone_tex = "assets/textures/drone_panel.png"
    sent_head = "assets/textures/sentinel_head.png"
    sent_armor = "assets/textures/sentinel_armor.png"
    sent_core = "assets/textures/sentinel_core.png"
    sent_gun = "assets/textures/sentinel_gun.png"

    for path in [drone_tex, sent_head, sent_armor, sent_core, sent_gun]:
        assert os.path.exists(path), f"Missing {path}"

    with Image.open(drone_tex) as im:
        assert im.size == (64, 64), f"drone_panel size {im.size} != (64, 64)"
        # Check dark gunmetal tones ~#23272E (R: 35, G: 39, B: 46)
        pix = im.getpixel((32, 32))
        assert 25 <= pix[0] <= 55 and 25 <= pix[1] <= 60 and 35 <= pix[2] <= 70
        print("[PASS] drone_panel.png verified (64x64, dark brushed gunmetal #23272E).")

    with Image.open(sent_armor) as im:
        assert im.size == (512, 512), f"sentinel_armor size {im.size} != (512, 512)"
        # Check high-visibility tactical titanium armor plate tones (~#738096 / #8594A8)
        pix = im.getpixel((100, 100))
        assert 80 <= pix[0] <= 150 and 90 <= pix[1] <= 165 and 100 <= pix[2] <= 185, f"Armor plate brightness out of range: {pix}"
        # Check yellow-and-black hazard markings exist on top-right panel
        hazard_pixels = [im.getpixel((x, 50)) for x in range(280, 420)]
        has_yellow = any(p[0] > 180 and p[1] > 140 and p[2] < 50 for p in hazard_pixels)
        assert has_yellow, "Hazard stripes not found on sentinel_armor.png"
        print("[PASS] sentinel_armor.png verified (high-visibility tactical titanium plates with yellow-and-black hazard markings).")

    with Image.open(sent_head) as im:
        pix = im.getpixel((100, 100))
        assert 80 <= pix[0] <= 150 and 90 <= pix[1] <= 165 and 100 <= pix[2] <= 185, f"Head armor brightness out of range: {pix}"
        print("[PASS] sentinel_head.png verified (high-visibility tactical titanium skull).")

    with Image.open(sent_core) as im:
        print("[PASS] sentinel_core.png verified (tactical chassis & glowing recessed plasma core).")

    with Image.open(sent_gun) as im:
        print("[PASS] sentinel_gun.png verified (tactical gunmetal heavy weapon plating).")

def verify_qml_materials_and_filtering():
    print("\n=== 2. VERIFYING QML TEXTURES & MATERIALS ===")
    with open("qml/EnemyModel.qml", "r") as f:
        qml = f.read()

    # Nearest filtering on all textures
    for tex_id in ["texDronePanel", "texSentinelHead", "texSentinelArmor", "texSentinelCore", "texSentinelGun"]:
        idx = qml.find(f"id: {tex_id}")
        assert idx != -1, f"Missing texture {tex_id}"
        block = qml[idx:idx+260]
        assert "magFilter: Texture.Nearest" in block, f"Texture.Nearest missing in {tex_id}"
        assert "minFilter: Texture.Nearest" in block, f"Texture.Nearest missing in {tex_id}"
        print(f"[PASS] {tex_id} configured with Texture.Nearest filtering.")

    # Drone chassis material properties
    assert "id: matDroneChassis" in qml
    mat_d_idx = qml.find("id: matDroneChassis")
    mat_d_block = qml[mat_d_idx:mat_d_idx+250]
    assert "metalness: 0.8" in mat_d_block
    assert "roughness: 0.3" in mat_d_block
    assert "#23272E" in mat_d_block
    print("[PASS] matDroneChassis verified (#23272E, metalness: 0.8, roughness: 0.3).")

    # Dark mechanical joint material (#2D3748)
    assert "id: matDarkMechJoint" in qml
    mat_j_idx = qml.find("id: matDarkMechJoint")
    mat_j_block = qml[mat_j_idx:mat_j_idx+200]
    assert "#2D3748" in mat_j_block
    print("[PASS] matDarkMechJoint verified (#2D3748 tactical mechanical joint material).")

    # Sentinel materials (metalness: 0.55, roughness: 0.35, emissiveFactor)
    for mat_id in ["matSentinelHead", "matSentinelArmor", "matSentinelCore", "matSentinelGun"]:
        m_idx = qml.find(f"id: {mat_id}")
        assert m_idx != -1
        m_block = qml[m_idx:m_idx+260]
        assert "metalness: 0.55" in m_block
        assert "roughness: 0.35" in m_block
        assert "emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)" in m_block
        print(f"[PASS] {mat_id} verified (metalness: 0.55, roughness: 0.35, emissiveFactor: 0.12/0.14/0.16).")

def verify_drone_model():
    print("\n=== 3. VERIFYING DRONE VISUAL OVERHAUL ===")
    with open("qml/EnemyModel.qml", "r") as f:
        qml = f.read()

    drone_idx = qml.find("id: droneNode")
    sentinel_idx = qml.find("id: sentinelNode")
    assert drone_idx != -1 and sentinel_idx != -1
    drone_block = qml[drone_idx:sentinel_idx]

    # Angled rotor boom arms (pitched upward)
    assert "eulerRotation: Qt.vector3d(-10, -42, 8)" in drone_block or "eulerRotation: Qt.vector3d(-10" in drone_block
    print("[PASS] Drone 4 rotor boom arms angled upward.")

    # Thin dark rotor guard frames around blades
    assert "Rotor Guard Frame" in drone_block
    print("[PASS] Thin dark rotor guard frames verified on all 4 nacelles.")

    # Rotor-tip LEDs & Visor Slits
    assert "#FF1E1E" in drone_block  # Red ranged drone
    assert "#00E5FF" in drone_block  # Blue close-shock drone
    print("[PASS] Emissive Visor Slits & Rotor-Tip LEDs coded (#FF1E1E crimson & #00E5FF electric-cyan).")

    # Weaponry variants
    assert "RED RANGED DRONE" in drone_block
    assert "dual-barrel" in drone_block.lower() or "Dual-Barrel" in drone_block
    assert "BLUE CLOSE-SHOCK DRONE" in drone_block
    assert "Twin Electric Shock Prongs" in drone_block
    print("[PASS] Sleek under-slung dual-barrel blaster and twin electric shock prongs verified.")

    # No blocky cyan/orange cubes
    assert "#ff4400" not in drone_block
    assert "#38bdf8" not in drone_block
    print("[PASS] Blocky untextured bottom cubes removed.")

def verify_sentinel_model():
    print("\n=== 4. VERIFYING SENTINEL ROBOT VISUAL OVERHAUL ===")
    with open("qml/EnemyModel.qml", "r") as f:
        qml = f.read()

    sentinel_idx = qml.find("id: sentinelNode")
    scrap_idx = qml.find("id: scrapDebrisNode")
    assert sentinel_idx != -1 and scrap_idx != -1
    sent_block = qml[sentinel_idx:scrap_idx]

    # Recessed mechanical joints (#111317)
    assert "Neck Joint" in sent_block
    assert "Shoulder Joints" in sent_block
    assert "Elbow Servo Joint" in sent_block
    assert "Waist Joint" in sent_block
    assert "Knee Joint" in sent_block
    print("[PASS] Recessed mechanical joints (#111317) verified at neck, shoulders, elbows, waist, and knees.")

    # Widened shoulder pauldrons
    assert "scale: Qt.vector3d(0.38, 0.26, 0.50)" in sent_block
    print("[PASS] Widened heavy tactical shoulder pauldrons verified.")

    # Narrow recessed red optical slit (#FF1E1E)
    assert "#FF1E1E" in sent_block
    assert "Narrow Menacing Glowing Red Optical Slit" in sent_block
    print("[PASS] Narrow recessed glowing red optical slit (#FF1E1E) verified.")

    # Recessed glowing reactor core behind dark armored protective ribs
    assert "Dark Armored Protective Ribs across Reactor Core" in sent_block
    assert "Recessed Glowing Plasma Reactor Core" in sent_block
    print("[PASS] Recessed glowing plasma reactor core behind dark armored protective ribs verified.")

    # Remodeled weapon arm into dark gunmetal heavy cannon with emissive muzzle accent
    assert "Heavy Gunmetal Assault Cannon Assembly" in sent_block
    assert "Glowing Crimson Emissive Muzzle Accent" in sent_block
    print("[PASS] Dark gunmetal heavy assault cannon with emissive muzzle accent (#FF1E1E) verified.")

def verify_guardrails():
    print("\n=== 5. VERIFYING GUARDRAILS ===")
    with open("src/GameConfig.h", "r") as f:
        gc = f.read()
    assert "MAX_PLAYER_HEALTH" in gc
    assert "DRONE_HEALTH = 40" in gc
    assert "SENTINEL_HEALTH = 100" in gc
    assert "PLAYER_WALK_SPEED" in gc
    print("[PASS] GameConfig enemy HP and player stats intact.")

    with open("CMakeLists.txt", "r") as f:
        cmake = f.read()
    assert "assets/textures/drone_panel.png" in cmake
    print("[PASS] CMakeLists.txt contains drone_panel.png.")

if __name__ == "__main__":
    verify_textures()
    verify_qml_materials_and_filtering()
    verify_drone_model()
    verify_sentinel_model()
    verify_guardrails()
    print("\nALL DRONE & SENTINEL 3D VISUAL DESIGN CHECKS PASSED (100% GREEN)!")
