# scratch/generate_sentinel_textures.py
import math
import numpy as np
from PIL import Image, ImageDraw

def create_sentinel_head():
    size = (512, 512)
    # Bright silver-titanium brushed metal background
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            noise = (math.sin(x * 0.3) * 6 + math.cos(y * 0.15) * 6 + (x % 4) * 3)
            val = int(np.clip(180 + noise, 155, 215))
            np_base[y, x] = [val - 5, val, val + 10, 255] # Clean silver-blue tint
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer border chamfer
    draw.rectangle([8, 8, 503, 503], outline=(230, 240, 255, 255), width=3)
    draw.rectangle([12, 12, 499, 499], outline=(100, 115, 135, 255), width=3)

    # 1. Forehead / Brow Armor Plate (Bright polished titanium)
    draw.rectangle([50, 35, 462, 165], fill=(195, 205, 220, 255), outline=(75, 85, 100, 255), width=4)
    draw.rectangle([56, 41, 456, 159], outline=(240, 248, 255, 255), width=2)

    # Chrome hex bolts on brow
    for bx in [75, 150, 256, 362, 437]:
        draw.ellipse([bx - 9, 65 - 9, bx + 9, 65 + 9], fill=(120, 135, 155, 255), outline=(60, 70, 85, 255), width=2)
        draw.ellipse([bx - 6, 65 - 6, bx + 6, 65 + 6], fill=(225, 235, 250, 255))
        draw.line([bx - 5, 65, bx + 5, 65], fill=(50, 60, 75, 255), width=2)

    # Tactical Hazard Banner on Forehead
    draw.rectangle([160, 100, 352, 140], fill=(45, 55, 68, 255), outline=(80, 95, 115, 255), width=2)
    for hx in range(165, 345, 18):
        draw.polygon([(hx, 102), (hx + 10, 102), (hx + 3, 138), (hx - 7, 138)], fill=(245, 200, 20, 255))

    # 2. Cybernetic Visor / Eye Socket Cavity (Horizontal Red Glowing Sensor)
    draw.rectangle([40, 180, 472, 285], fill=(45, 20, 25, 255), outline=(60, 70, 85, 255), width=5)
    # Inner metallic sensor track
    draw.rectangle([55, 195, 457, 270], fill=(25, 10, 14, 255), outline=(140, 40, 50, 255), width=2)

    # Glowing Crimson Visor Beam (High-luminosity ruby optical sensor)
    draw.rectangle([65, 212, 447, 252], fill=(240, 25, 45, 255))
    draw.rectangle([75, 220, 437, 244], fill=(255, 95, 110, 255))
    draw.rectangle([95, 226, 417, 238], fill=(255, 235, 240, 255))

    # Scanline overlay on visor
    for sy in range(196, 270, 4):
        draw.line([55, sy, 457, sy], fill=(0, 0, 0, 100), width=1)

    # Dual Glowing Lenses (T-800 eye optics)
    for ex in [165, 347]:
        draw.ellipse([ex - 28, 232 - 28, ex + 28, 232 + 28], fill=(255, 35, 55, 255), outline=(255, 220, 225, 255), width=3)
        draw.ellipse([ex - 15, 232 - 15, ex + 15, 232 + 15], fill=(255, 160, 175, 255))
        draw.ellipse([ex - 7, 232 - 7, ex + 7, 232 + 7], fill=(255, 255, 255, 255))

    # 3. Temple & Cheek Heat Sink Vents (Light chrome with dark ventilation slits)
    for side in [0, 1]:
        tx1 = 40 if side == 0 else 405
        tx2 = 105 if side == 0 else 472
        draw.rectangle([tx1, 300, tx2, 445], fill=(185, 195, 210, 255), outline=(70, 80, 95, 255), width=3)
        draw.rectangle([tx1 + 3, 303, tx2 - 3, 442], outline=(235, 245, 255, 255), width=1)
        for vy in range(315, 435, 16):
            draw.rectangle([tx1 + 6, vy, tx2 - 6, vy + 7], fill=(45, 52, 65, 255))

    # 4. Titanium Jaw / Respirator Grill (Center Lower Face)
    draw.rectangle([120, 300, 392, 475], fill=(190, 200, 215, 255), outline=(70, 80, 95, 255), width=4)
    draw.rectangle([126, 306, 386, 469], outline=(240, 248, 255, 255), width=2)
    # Vertical air filtration slats
    for sx in range(145, 375, 18):
        draw.rectangle([sx, 320, sx + 9, 455], fill=(50, 60, 75, 255), outline=(130, 145, 165, 255), width=1)
        # Polished chrome highlight on slats
        draw.line([sx + 2, 322, sx + 2, 453], fill=(220, 235, 250, 255), width=1)

    # Hydraulic Jaw Pistons on Sides (Polished Stainless Steel)
    draw.rectangle([105, 360, 120, 455], fill=(215, 225, 240, 255), outline=(75, 85, 100, 255), width=2)
    draw.line([109, 362, 109, 453], fill=(255, 255, 255, 255), width=2)
    draw.rectangle([392, 360, 407, 455], fill=(215, 225, 240, 255), outline=(75, 85, 100, 255), width=2)
    draw.line([396, 362, 396, 453], fill=(255, 255, 255, 255), width=2)

    # 5. Chin Armor Block
    draw.rectangle([170, 465, 342, 502], fill=(175, 185, 200, 255), outline=(65, 75, 90, 255), width=3)
    draw.line([175, 470, 337, 470], fill=(240, 248, 255, 255), width=2)

    img.save("assets/textures/sentinel_head.png", "PNG", optimize=True)
    print("Saved bright assets/textures/sentinel_head.png")

def create_sentinel_armor():
    size = (512, 512)
    # Bright silver-titanium composite plate
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(0, 512):
        for x in range(0, 512):
            # Carbon weave check pattern in light tones
            weave = 12 if ((x // 8) + (y // 8)) % 2 == 0 else 0
            val = int(np.clip(170 + weave + (x % 3) * 2, 150, 205))
            np_base[y, x] = [val - 5, val, val + 8, 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer Bevel Borders
    draw.rectangle([8, 8, 503, 503], outline=(240, 248, 255, 255), width=3)
    draw.rectangle([12, 12, 499, 499], outline=(70, 80, 95, 255), width=3)

    # 4 Heavy Modular Titanium Armor Plates
    panels = [
        [28, 28, 240, 240],
        [272, 28, 484, 240],
        [28, 272, 240, 484],
        [272, 272, 484, 484]
    ]

    for p in panels:
        draw.rectangle(p, fill=(190, 200, 215, 255), outline=(65, 75, 90, 255), width=4)
        # Inner plate polished bevel
        draw.rectangle([p[0] + 6, p[1] + 6, p[2] - 6, p[3] - 6], outline=(245, 250, 255, 255), width=2)
        # Hex bolts on panel corners
        for cx, cy in [(p[0] + 18, p[1] + 18), (p[2] - 18, p[1] + 18),
                      (p[0] + 18, p[3] - 18), (p[2] - 18, p[3] - 18)]:
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(120, 135, 155, 255), outline=(55, 65, 80, 255), width=2)
            draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(230, 240, 255, 255))
            draw.line([cx - 4, cy, cx + 4, cy], fill=(50, 60, 75, 255), width=2)

    # Industrial Hazard Warning Stripes on Top-Right Panel (Vibrant Yellow & Dark Gunmetal)
    hx_start = 285
    hy_start = 45
    for i in range(7):
        ox = i * 26
        draw.polygon([(hx_start + ox, hy_start), (hx_start + ox + 14, hy_start),
                      (hx_start + ox - 14, hy_start + 55), (hx_start + ox - 28, hy_start + 55)],
                     fill=(245, 200, 20, 255))
        draw.polygon([(hx_start + ox + 14, hy_start), (hx_start + ox + 26, hy_start),
                      (hx_start + ox - 2, hy_start + 55), (hx_start + ox - 14, hy_start + 55)],
                     fill=(45, 55, 68, 255))

    # Center Power Relay / Junction Hub (Chrome ring with vibrant cyan/amber indicator)
    draw.rectangle([212, 212, 300, 300], fill=(160, 172, 190, 255), outline=(60, 70, 85, 255), width=4)
    draw.ellipse([224, 224, 288, 288], fill=(210, 222, 238, 255), outline=(240, 45, 55, 255), width=3)
    draw.ellipse([238, 238, 274, 274], fill=(255, 60, 70, 255))
    draw.ellipse([248, 248, 264, 264], fill=(255, 220, 225, 255))

    # Cooling Louvers on Bottom-Left Panel
    for ly in range(315, 445, 18):
        draw.rectangle([48, ly, 222, ly + 9], fill=(55, 65, 80, 255), outline=(130, 145, 165, 255), width=1)
        draw.line([50, ly + 2, 220, ly + 2], fill=(225, 235, 250, 255), width=1)

    # Hydraulic Actuator Rails (Center Vertical Bars - Polished Chrome)
    draw.rectangle([242, 28, 270, 212], fill=(215, 225, 240, 255), outline=(70, 80, 95, 255), width=2)
    draw.line([247, 30, 247, 210], fill=(255, 255, 255, 255), width=2)
    draw.rectangle([242, 300, 270, 484], fill=(215, 225, 240, 255), outline=(70, 80, 95, 255), width=2)
    draw.line([247, 302, 247, 482], fill=(255, 255, 255, 255), width=2)

    img.save("assets/textures/sentinel_armor.png", "PNG", optimize=True)
    print("Saved bright assets/textures/sentinel_armor.png")

def create_sentinel_core():
    size = (512, 512)
    # Bright titanium chassis base
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            val = int(np.clip(165 + (math.sin(x * 0.2) + math.cos(y * 0.2)) * 6, 145, 195))
            np_base[y, x] = [val - 5, val, val + 10, 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # Outer Frame
    draw.rectangle([14, 14, 497, 497], outline=(235, 245, 255, 255), width=3)
    draw.rectangle([18, 18, 493, 493], outline=(65, 75, 90, 255), width=4)

    # 1. Central Supercharged Plasma Reactor (Circular Chamber)
    cx, cy, r = 256, 256, 145
    # Outer magnetic containment ring in polished silver
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(195, 205, 220, 255), outline=(60, 70, 85, 255), width=5)
    draw.ellipse([cx - r + 12, cy - r + 12, cx + r - 12, cy + r - 12], outline=(245, 250, 255, 255), width=3)

    # Dark core pit for glowing contrast
    draw.ellipse([cx - 110, cy - 110, cx + 110, cy + 110], fill=(45, 15, 20, 255))
    # Brilliant radiant plasma glow rings
    draw.ellipse([cx - 90, cy - 90, cx + 90, cy + 90], fill=(180, 25, 35, 255))
    draw.ellipse([cx - 70, cy - 70, cx + 70, cy + 70], fill=(235, 45, 55, 255))
    draw.ellipse([cx - 50, cy - 50, cx + 50, cy + 50], fill=(255, 100, 70, 255))
    draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(255, 180, 110, 255))
    draw.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=(255, 245, 235, 255))

    # Titanium Core Ribs / Safety Bars (Bright cross bars over reactor)
    draw.rectangle([cx - r, cy - 12, cx + r, cy + 12], fill=(210, 220, 235, 255), outline=(60, 70, 85, 255), width=2)
    draw.line([cx - r + 2, cy - 6, cx + r - 2, cy - 6], fill=(255, 255, 255, 255), width=2)
    draw.rectangle([cx - 12, cy - r, cx + 12, cy + r], fill=(210, 220, 235, 255), outline=(60, 70, 85, 255), width=2)
    draw.line([cx - 6, cy - r + 2, cx - 6, cy + r - 2], fill=(255, 255, 255, 255), width=2)

    # 2. High-Voltage Braided Power Conduits
    cables = [
        [(35, 55), (155, 175), (235, 40, 45)],
        [(35, 85), (165, 195), (245, 185, 25)],
        [(477, 55), (357, 175), (235, 40, 45)],
        [(477, 85), (347, 195), (0, 160, 255)],
        [(35, 457), (155, 337), (0, 160, 255)],
        [(35, 427), (165, 317), (245, 185, 25)],
        [(477, 457), (357, 337), (235, 40, 45)],
        [(477, 427), (347, 317), (245, 185, 25)],
    ]
    for p1, p2, col in cables:
        draw.line([p1, p2], fill=(35, 42, 52, 255), width=16)
        draw.line([p1, p2], fill=col + (255,), width=10)
        draw.line([p1, p2], fill=(255, 255, 255, 180), width=2)

    # 3. Spinal Column Vertebrae on Top & Bottom (Light Titanium Blocks)
    for vy in range(25, 95, 20):
        draw.rectangle([212, vy, 300, vy + 14], fill=(195, 205, 220, 255), outline=(60, 70, 85, 255), width=2)
        draw.line([216, vy + 3, 296, vy + 3], fill=(245, 250, 255, 255), width=2)
    for vy in range(417, 487, 20):
        draw.rectangle([212, vy, 300, vy + 14], fill=(195, 205, 220, 255), outline=(60, 70, 85, 255), width=2)
        draw.line([216, vy + 3, 296, vy + 3], fill=(245, 250, 255, 255), width=2)

    img.save("assets/textures/sentinel_core.png", "PNG", optimize=True)
    print("Saved bright assets/textures/sentinel_core.png")

def create_sentinel_gun():
    size = (512, 512)
    # Bright silver chassis
    np_base = np.zeros((512, 512, 4), dtype=np.uint8)
    for y in range(512):
        for x in range(512):
            val = int(np.clip(160 + (x % 4) * 3, 145, 185))
            np_base[y, x] = [val - 4, val, val + 8, 255]
    img = Image.fromarray(np_base, "RGBA")
    draw = ImageDraw.Draw(img)

    # 1. Main Receiver Housing (Bright chrome/titanium)
    draw.rectangle([28, 55, 484, 245], fill=(185, 195, 210, 255), outline=(55, 65, 80, 255), width=4)
    draw.rectangle([34, 61, 478, 239], outline=(240, 248, 255, 255), width=2)

    # Carbon Tactical Rail (Top)
    draw.rectangle([40, 68, 472, 105], fill=(70, 80, 95, 255), outline=(130, 145, 165, 255), width=2)
    for rx in range(50, 465, 20):
        draw.rectangle([rx, 74, rx + 10, 99], fill=(35, 42, 52, 255))

    # 2. Plasma Acceleration Chamber (Glowing Energy Coils)
    draw.rectangle([48, 128, 464, 222], fill=(35, 42, 52, 255), outline=(75, 85, 100, 255), width=3)
    for cx in range(60, 445, 36):
        draw.rectangle([cx, 136, cx + 24, 214], fill=(245, 120, 20, 255), outline=(255, 200, 60, 255), width=2)
        draw.rectangle([cx + 6, 142, cx + 18, 208], fill=(255, 240, 160, 255))

    # 3. High-Caliber Barrel / Muzzle Shroud (Bright Titanium)
    draw.rectangle([28, 268, 484, 382], fill=(175, 185, 200, 255), outline=(55, 65, 80, 255), width=4)
    draw.rectangle([34, 274, 478, 376], outline=(235, 245, 255, 255), width=2)
    # Cooling ports on barrel
    for px in range(48, 465, 32):
        draw.ellipse([px, 300, px + 20, 350], fill=(45, 52, 65, 255), outline=(120, 135, 155, 255), width=2)
        draw.ellipse([px + 3, 303, px + 17, 347], outline=(200, 215, 235, 255), width=1)

    # 4. Battery / Power Cell Magazine (Bottom)
    draw.rectangle([115, 400, 397, 492], fill=(180, 190, 205, 255), outline=(55, 65, 80, 255), width=3)
    # Power indicator LEDs
    for lx in range(135, 375, 35):
        draw.rectangle([lx, 435, lx + 22, 457], fill=(245, 35, 55, 255), outline=(255, 200, 210, 255), width=1)
        draw.rectangle([lx + 6, 440, lx + 16, 452], fill=(255, 220, 225, 255))

    # Danger stencil
    draw.rectangle([205, 410, 307, 426], fill=(245, 200, 20, 255))
    draw.text((215, 412), "HIGH VOLTAGE", fill=(0, 0, 0, 255))

    img.save("assets/textures/sentinel_gun.png", "PNG", optimize=True)
    print("Saved bright assets/textures/sentinel_gun.png")

if __name__ == "__main__":
    create_sentinel_head()
    create_sentinel_armor()
    create_sentinel_core()
    create_sentinel_gun()
    print("All bright sentinel textures created successfully.")
