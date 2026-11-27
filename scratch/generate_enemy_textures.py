# scratch/generate_enemy_textures.py
import math
import numpy as np
from PIL import Image, ImageDraw

def create_drone_panel():
    size = (64, 64)
    # Dark brushed gunmetal matching #23272E (RGB: 35, 39, 46)
    np_base = np.zeros((64, 64, 4), dtype=np.uint8)
    for y in range(64):
        for x in range(64):
            grain = (x % 3) * 2 - (y % 2) * 1 + int(math.sin(x * 0.5) * 3)
            r = int(np.clip(35 + grain, 28, 45))
            g = int(np.clip(39 + grain, 32, 49))
            b = int(np.clip(46 + grain, 38, 56))
            np_base[y, x] = [r, g, b, 255]

    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Dark outer chamfer bevel
    draw.rectangle([0, 0, 63, 63], outline=(22, 25, 30, 255), width=1)
    draw.line([1, 1, 62, 1], fill=(55, 62, 72, 255), width=1)
    draw.line([1, 1, 1, 62], fill=(55, 62, 72, 255), width=1)
    draw.line([1, 62, 62, 62], fill=(18, 20, 24, 255), width=1)
    draw.line([62, 1, 62, 62], fill=(18, 20, 24, 255), width=1)

    # Modular interior panel seam
    draw.rectangle([8, 8, 55, 55], outline=(20, 22, 27, 255), width=1)
    draw.rectangle([9, 9, 54, 54], outline=(48, 54, 64, 255), width=1)

    # Central structural reinforcement rib
    draw.rectangle([28, 12, 35, 51], fill=(29, 32, 38, 255), outline=(18, 20, 24, 255), width=1)
    draw.line([30, 14, 30, 49], fill=(52, 58, 68, 255), width=1)

    # Corner hex rivets
    for rx, ry in [(5, 5), (58, 5), (5, 58), (58, 58), (14, 14), (49, 14), (14, 49), (49, 49)]:
        draw.point((rx, ry), fill=(18, 20, 24, 255))
        draw.point((rx - 1, ry), fill=(60, 68, 80, 255))

    img.save("assets/textures/drone_panel.png", "PNG", optimize=True)
    print("Saved assets/textures/drone_panel.png")

def create_sentinel_head():
    # 512x512 High-Visibility Tactical Titanium Head Plates
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            noise = (math.sin(x * 0.3) * 5 + math.cos(y * 0.2) * 5 + (x % 4) * 2)
            val = int(np.clip(115 + noise, 95, 135))
            np_base[y, x] = [int(val * 0.92), int(val * 1.02), int(val * 1.18), 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer border bevel with light metallic chamfer
    draw.rectangle([8, 8, 503, 503], outline=(175, 195, 220, 255), width=3)
    draw.rectangle([12, 12, 499, 499], outline=(60, 72, 90, 255), width=3)

    # 1. Forehead / Brow Armor Plate
    draw.rectangle([50, 35, 462, 165], fill=(120, 135, 160, 255), outline=(65, 75, 95, 255), width=4)
    draw.rectangle([56, 41, 456, 159], outline=(185, 200, 225, 255), width=2)

    # Chrome hex bolts on brow
    for bx in [75, 150, 256, 362, 437]:
        draw.ellipse([bx - 9, 65 - 9, bx + 9, 65 + 9], fill=(85, 95, 115, 255), outline=(45, 55, 70, 255), width=2)
        draw.ellipse([bx - 5, 65 - 5, bx + 5, 65 + 5], fill=(210, 225, 245, 255))

    # High-Visibility Tactical Hazard Chevrons on Forehead
    draw.rectangle([160, 100, 352, 140], fill=(30, 35, 45, 255), outline=(80, 95, 115, 255), width=2)
    for hx in range(165, 345, 18):
        draw.polygon([(hx, 102), (hx + 10, 102), (hx + 3, 138), (hx - 7, 138)], fill=(250, 195, 20, 255))

    # 2. Recessed Optical Cavity & High-Luminosity Crimson Visor (#FF1E1E)
    draw.rectangle([40, 180, 472, 285], fill=(35, 40, 52, 255), outline=(50, 60, 75, 255), width=5)
    draw.rectangle([55, 195, 457, 270], fill=(22, 25, 32, 255), outline=(120, 30, 40, 255), width=2)

    # Menacing glowing crimson visor slit with white-hot core
    draw.rectangle([65, 218, 447, 246], fill=(255, 30, 30, 255))
    draw.rectangle([85, 223, 427, 241], fill=(255, 110, 110, 255))
    draw.rectangle([120, 227, 392, 237], fill=(255, 240, 240, 255))

    # Scanline overlay on optical cavity
    for sy in range(196, 270, 4):
        draw.line([55, sy, 457, sy], fill=(0, 0, 0, 100), width=1)

    # Dual Glowing Ruby Focal Lenses
    for ex in [165, 347]:
        draw.ellipse([ex - 24, 232 - 24, ex + 24, 232 + 24], fill=(255, 30, 30, 255), outline=(255, 180, 180, 255), width=2)
        draw.ellipse([ex - 12, 232 - 12, ex + 12, 232 + 12], fill=(255, 180, 180, 255))
        draw.ellipse([ex - 6, 232 - 6, ex + 6, 232 + 6], fill=(255, 255, 255, 255))

    # 3. Temple & Cheek Vents
    for side in [0, 1]:
        tx1 = 40 if side == 0 else 405
        tx2 = 105 if side == 0 else 472
        draw.rectangle([tx1, 300, tx2, 445], fill=(115, 128, 150, 255), outline=(60, 70, 85, 255), width=3)
        draw.rectangle([tx1 + 3, 303, tx2 - 3, 442], outline=(175, 190, 215, 255), width=1)
        for vy in range(315, 435, 16):
            draw.rectangle([tx1 + 6, vy, tx2 - 6, vy + 7], fill=(35, 40, 52, 255))

    # 4. Heavy Titanium Respirator Grill with Chrome Slats
    draw.rectangle([120, 300, 392, 475], fill=(110, 125, 145, 255), outline=(60, 70, 85, 255), width=4)
    draw.rectangle([126, 306, 386, 469], outline=(175, 190, 215, 255), width=2)
    for sx in range(145, 375, 18):
        draw.rectangle([sx, 320, sx + 9, 455], fill=(40, 48, 62, 255), outline=(90, 105, 125, 255), width=1)
        draw.line([sx + 2, 322, sx + 2, 453], fill=(200, 215, 235, 255), width=1)

    # Hydraulic Jaw Pistons (Polished Steel)
    draw.rectangle([105, 360, 120, 455], fill=(165, 180, 205, 255), outline=(65, 75, 95, 255), width=2)
    draw.line([109, 362, 109, 453], fill=(250, 255, 255, 255), width=2)
    draw.rectangle([392, 360, 407, 455], fill=(165, 180, 205, 255), outline=(65, 75, 95, 255), width=2)
    draw.line([396, 362, 396, 453], fill=(250, 255, 255, 255), width=2)

    # 5. Chin Armor Block
    draw.rectangle([170, 465, 342, 502], fill=(115, 128, 150, 255), outline=(60, 70, 85, 255), width=3)
    draw.line([175, 470, 337, 470], fill=(185, 200, 225, 255), width=2)

    img.save("assets/textures/sentinel_head.png", "PNG", optimize=True)
    print("Saved high-visibility assets/textures/sentinel_head.png")

def create_sentinel_armor():
    # 512x512 High-Visibility Tactical Titanium Armor Plates
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            weave = 6 if ((x // 8) + (y // 8)) % 2 == 0 else 0
            val = int(np.clip(110 + weave + (x % 3) * 2, 90, 130))
            np_base[y, x] = [int(val * 0.92), int(val * 1.02), int(val * 1.18), 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer Bevel Borders with Bright Chamfer
    draw.rectangle([8, 8, 503, 503], outline=(175, 195, 220, 255), width=3)
    draw.rectangle([12, 12, 499, 499], outline=(60, 72, 90, 255), width=3)

    # 4 Heavy Modular Titanium Plates
    panels = [
        [28, 28, 240, 240],
        [272, 28, 484, 240],
        [28, 272, 240, 484],
        [272, 272, 484, 484]
    ]

    for p in panels:
        draw.rectangle(p, fill=(115, 128, 150, 255), outline=(60, 70, 90, 255), width=4)
        draw.rectangle([p[0] + 6, p[1] + 6, p[2] - 6, p[3] - 6], outline=(175, 190, 215, 255), width=2)
        # Chrome hex bolts on panel corners
        for cx, cy in [(p[0] + 18, p[1] + 18), (p[2] - 18, p[1] + 18),
                      (p[0] + 18, p[3] - 18), (p[2] - 18, p[3] - 18)]:
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(85, 95, 115, 255), outline=(45, 55, 70, 255), width=2)
            draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(210, 225, 245, 255))

    # Vibrant Yellow-and-Black Hazard Markings on Top-Right Panel (Shoulder Armor area)
    hx_start = 285
    hy_start = 45
    for i in range(7):
        ox = i * 26
        draw.polygon([(hx_start + ox, hy_start), (hx_start + ox + 13, hy_start),
                      (hx_start + ox - 13, hy_start + 55), (hx_start + ox - 26, hy_start + 55)],
                     fill=(250, 195, 20, 255))
        draw.polygon([(hx_start + ox + 13, hy_start), (hx_start + ox + 26, hy_start),
                      (hx_start + ox, hy_start + 55), (hx_start + ox - 13, hy_start + 55)],
                     fill=(28, 32, 42, 255))

    # Center Power Hub / Mechanical Coupler
    draw.rectangle([212, 212, 300, 300], fill=(45, 55, 72, 255), outline=(35, 42, 54, 255), width=4)
    draw.ellipse([224, 224, 288, 288], fill=(35, 42, 54, 255), outline=(140, 160, 190, 255), width=3)
    draw.ellipse([238, 238, 274, 274], fill=(255, 40, 50, 255))
    draw.ellipse([248, 248, 264, 264], fill=(255, 180, 190, 255))

    # Cooling Louvers on Bottom-Left Panel
    for ly in range(315, 445, 18):
        draw.rectangle([48, ly, 222, ly + 9], fill=(35, 42, 54, 255), outline=(85, 100, 120, 255), width=1)

    # Hydraulic Actuator Rails with Chrome Highlights
    draw.rectangle([242, 28, 270, 212], fill=(130, 145, 170, 255), outline=(55, 65, 80, 255), width=2)
    draw.line([247, 30, 247, 210], fill=(220, 235, 255, 255), width=2)
    draw.rectangle([242, 300, 270, 484], fill=(130, 145, 170, 255), outline=(55, 65, 80, 255), width=2)
    draw.line([247, 302, 247, 482], fill=(220, 235, 255, 255), width=2)

    img.save("assets/textures/sentinel_armor.png", "PNG", optimize=True)
    print("Saved high-visibility assets/textures/sentinel_armor.png")

def create_sentinel_core():
    # 512x512 Tactical Chassis with Recessed Glowing Plasma Reactor Core
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            val = int(np.clip(100 + (math.sin(x * 0.2) + math.cos(y * 0.2)) * 5, 80, 120))
            np_base[y, x] = [int(val * 0.92), int(val * 1.02), int(val * 1.18), 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer Frame
    draw.rectangle([14, 14, 497, 497], outline=(160, 180, 210, 255), width=3)
    draw.rectangle([18, 18, 493, 493], outline=(55, 65, 80, 255), width=4)

    # 1. Central Recessed Plasma Reactor Chamber
    cx, cy, r = 256, 256, 145
    # Outer magnetic containment ring
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 95, 120, 255), outline=(50, 60, 75, 255), width=5)
    draw.ellipse([cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12], outline=(160, 180, 210, 255), width=3)

    # Deep recessed core pit
    draw.ellipse([cx - 110, cy - 110, cx + 110, cy + 110], fill=(25, 30, 40, 255))
    # Glowing plasma core with fiery radiant heat
    draw.ellipse([cx - 92, cy - 92, cx + 92, cy + 92], fill=(220, 30, 40, 255))
    draw.ellipse([cx - 72, cy - 72, cx + 72, cy + 72], fill=(255, 100, 30, 255))
    draw.ellipse([cx - 52, cy - 52, cx + 52, cy + 52], fill=(255, 190, 60, 255))
    draw.ellipse([cx - 32, cy - 32, cx + 32, cy + 32], fill=(255, 235, 150, 255))
    draw.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(255, 255, 250, 255))

    # Protective Grille Bars across Reactor Core
    for ry in [-80, -40, 0, 40, 80]:
        draw.rectangle([cx - r + 10, cy + ry - 8, cx + r - 10, cy + ry + 8],
                       fill=(45, 55, 70, 255), outline=(30, 38, 50, 255), width=2)
        draw.line([cx - r + 12, cy + ry - 4, cx + r - 12, cy + ry - 4], fill=(135, 150, 175, 255), width=1)

    # Vertical containment struts
    draw.rectangle([cx - 14, cy - r + 6, cx + 14, cy + r - 6],
                   fill=(55, 65, 82, 255), outline=(35, 42, 54, 255), width=2)

    # 2. Heavy Braided Conduits
    cables = [
        [(35, 55), (155, 175), (220, 35, 45)],
        [(35, 85), (165, 195), (240, 180, 25)],
        [(477, 55), (357, 175), (220, 35, 45)],
        [(477, 85), (347, 195), (0, 180, 255)],
        [(35, 457), (155, 337), (0, 180, 255)],
        [(35, 427), (165, 317), (240, 180, 25)],
        [(477, 457), (357, 337), (220, 35, 45)],
        [(477, 427), (347, 317), (240, 180, 25)],
    ]
    for p1, p2, col in cables:
        draw.line([p1, p2], fill=(30, 36, 48, 255), width=16)
        draw.line([p1, p2], fill=col + (255,), width=8)

    # 3. Spinal Column Vertebrae
    for vy in range(25, 95, 20):
        draw.rectangle([212, vy, 300, vy + 14], fill=(90, 105, 130, 255), outline=(45, 55, 70, 255), width=2)
        draw.line([216, vy + 3, 296, vy + 3], fill=(175, 190, 215, 255), width=1)
    for vy in range(417, 487, 20):
        draw.rectangle([212, vy, 300, vy + 14], fill=(90, 105, 130, 255), outline=(45, 55, 70, 255), width=2)
        draw.line([216, vy + 3, 296, vy + 3], fill=(175, 190, 215, 255), width=1)

    img.save("assets/textures/sentinel_core.png", "PNG", optimize=True)
    print("Saved high-visibility assets/textures/sentinel_core.png")

def create_sentinel_gun():
    # 512x512 Tactical Gunmetal Heavy Cannon
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            val = int(np.clip(95 + (x % 4) * 2, 75, 115))
            np_base[y, x] = [int(val * 0.92), int(val * 1.02), int(val * 1.18), 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # 1. Main Receiver Housing
    draw.rectangle([28, 55, 484, 245], fill=(95, 110, 130, 255), outline=(50, 60, 75, 255), width=4)
    draw.rectangle([34, 61, 478, 239], outline=(165, 180, 205, 255), width=2)

    # Tactical Picatinny Rail (Top)
    draw.rectangle([40, 68, 472, 105], fill=(60, 70, 85, 255), outline=(95, 110, 130, 255), width=2)
    for rx in range(50, 465, 20):
        draw.rectangle([rx, 74, rx + 10, 99], fill=(35, 42, 54, 255))

    # 2. Plasma Acceleration Chamber with Glowing Crimson Energy Coils (#FF1E1E)
    draw.rectangle([48, 128, 464, 222], fill=(35, 42, 54, 255), outline=(75, 90, 110, 255), width=3)
    for cx in range(60, 445, 36):
        draw.rectangle([cx, 136, cx + 24, 214], fill=(255, 30, 40, 255), outline=(255, 120, 120, 255), width=2)
        draw.rectangle([cx + 6, 142, cx + 18, 208], fill=(255, 200, 200, 255))

    # 3. High-Caliber Cannon Barrel / Muzzle Shroud
    draw.rectangle([28, 268, 484, 382], fill=(85, 98, 118, 255), outline=(50, 60, 75, 255), width=4)
    draw.rectangle([34, 274, 478, 376], outline=(160, 175, 200, 255), width=2)
    # Cooling ports
    for px in range(48, 465, 32):
        draw.ellipse([px, 300, px + 20, 350], fill=(35, 42, 54, 255), outline=(95, 110, 130, 255), width=2)

    # 4. Battery / Power Cell Magazine (Bottom)
    draw.rectangle([115, 400, 397, 492], fill=(95, 110, 130, 255), outline=(50, 60, 75, 255), width=3)
    for lx in range(135, 375, 35):
        draw.rectangle([lx, 435, lx + 22, 457], fill=(255, 30, 40, 255), outline=(255, 140, 140, 255), width=1)

    img.save("assets/textures/sentinel_gun.png", "PNG", optimize=True)
    print("Saved high-visibility assets/textures/sentinel_gun.png")

if __name__ == "__main__":
    create_drone_panel()
    create_sentinel_head()
    create_sentinel_armor()
    create_sentinel_core()
    create_sentinel_gun()
    print("All enemy textures regenerated successfully!")
