import os
import math
from PIL import Image, ImageDraw, ImageFont

def get_fonts():
    try:
        font_huge = ImageFont.truetype("arialbd.ttf", 40)
        font_large = ImageFont.truetype("arialbd.ttf", 26)
        font_med = ImageFont.truetype("arialbd.ttf", 16)
        font_small = ImageFont.truetype("arial.ttf", 12)
        font_tiny = ImageFont.truetype("arial.ttf", 10)
    except:
        font_huge = ImageFont.load_default()
        font_large = ImageFont.load_default()
        font_med = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_tiny = ImageFont.load_default()
    return font_huge, font_large, font_med, font_small, font_tiny

def generate_food_pack_texture(path):
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    font_huge, font_large, font_med, font_small, font_tiny = get_fonts()

    # 1. Base Dark Military Khaki/Olive Foil Pouch Gradient
    for y in range(height):
        factor = 0.88 + 0.22 * (1.0 - y / height)
        r = int(58 * factor)
        g = int(68 * factor)
        b = int(48 * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # Foil wrinkles / texture lines
    for x in range(0, width, 16):
        draw.line([(x, 0), (x, height)], fill=(255, 255, 255, 6))

    # 2. Heat-sealed crimped edges on all 4 borders
    seal_w = 26
    crimp_col1 = (35, 42, 30, 255)
    crimp_col2 = (80, 95, 70, 255)
    draw.rectangle([0, 0, width, seal_w], fill=crimp_col1, outline=crimp_col2)
    draw.rectangle([0, height - seal_w, width, height], fill=crimp_col1, outline=crimp_col2)
    draw.rectangle([0, 0, seal_w, height], fill=crimp_col1, outline=crimp_col2)
    draw.rectangle([width - seal_w, 0, width, height], fill=crimp_col1, outline=crimp_col2)

    # Serrated crimping marks
    for x in range(seal_w, width - seal_w, 6):
        draw.line([(x, 3), (x, seal_w - 3)], fill=crimp_col2, width=1)
        draw.line([(x, height - seal_w + 3), (x, height - 3)], fill=crimp_col2, width=1)
    for y in range(seal_w, height - seal_w, 6):
        draw.line([(3, y), (seal_w - 3, y)], fill=crimp_col2, width=1)
        draw.line([(width - seal_w + 3, y), (width - 3, y)], fill=crimp_col2, width=1)

    # 3. Tear Notches
    draw.polygon([(seal_w - 4, 60), (seal_w + 14, 60), (seal_w - 4, 74)], fill=(241, 196, 15, 255))
    draw.polygon([(width - seal_w + 4, 60), (width - seal_w - 14, 60), (width - seal_w + 4, 74)], fill=(241, 196, 15, 255))
    draw.text((seal_w + 22, 54), "◄ TEAR HERE TO OPEN ►", fill=(241, 196, 15, 240), font=font_small)

    # 4. Main Header Container Box
    bx1, by1 = 44, 85
    bx2, by2 = width - 44, 185
    draw.rectangle([bx1, by1, bx2, by2], fill=(24, 30, 20, 230), outline=(46, 204, 113, 255), width=2)

    draw.text((bx1 + 18, by1 + 12), "VANGUARD COMBAT RATION", fill=(46, 204, 113, 255), font=font_large)
    draw.text((bx1 + 20, by1 + 46), "STANDARD FIELD SURVIVAL PACK // MRE", fill=(220, 235, 220, 255), font=font_med)
    draw.text((bx1 + 20, by1 + 70), "MENU 04: BRAISED PROTEIN STEW & NUTRIENT PASTE", fill=(180, 195, 175, 255), font=font_small)

    # Health restoration badge (Right side of header)
    hbx = bx2 - 95
    hby = by1 + 12
    draw.rectangle([hbx, hby, bx2 - 12, by2 - 12], fill=(39, 174, 96, 255), outline=(20, 80, 40, 255), width=1)
    draw.text((hbx + 18, hby + 8), "+20", fill=(255, 255, 255, 255), font=font_large)
    draw.text((hbx + 16, hby + 44), "HEALTH", fill=(220, 255, 220, 255), font=font_small)

    # 5. Central Graphic: Nutritional Seal & Food Icon
    cx, cy = 135, 275
    # Outer circle
    draw.ellipse([cx - 65, cy - 65, cx + 65, cy + 65], fill=(30, 38, 26, 255), outline=(46, 204, 113, 255), width=3)
    # Green cross emblem
    cross_w, cross_l = 18, 48
    draw.rectangle([cx - cross_w // 2, cy - cross_l // 2, cx + cross_w // 2, cy + cross_l // 2], fill=(46, 204, 113, 255))
    draw.rectangle([cx - cross_l // 2, cy - cross_w // 2, cx + cross_l // 2, cy + cross_w // 2], fill=(46, 204, 113, 255))
    # Wheat ears / border arcs
    draw.arc([cx - 55, cy - 55, cx + 55, cy + 55], 30, 150, fill=(241, 196, 15, 255), width=2)
    draw.arc([cx - 55, cy - 55, cx + 55, cy + 55], 210, 330, fill=(241, 196, 15, 255), width=2)

    # Nutritional Facts Table on Right Side
    nx, ny = 225, 210
    draw.rectangle([nx, ny, width - 44, 345], fill=(22, 28, 18, 220), outline=(80, 100, 70, 255), width=1)
    draw.text((nx + 14, ny + 8), "NUTRITION SPECIFICATION", fill=(241, 196, 15, 255), font=font_med)
    draw.line([(nx + 10, ny + 30), (width - 54, ny + 30)], fill=(80, 100, 70, 255), width=1)
    draw.text((nx + 14, ny + 36), "ENERGY: 2,450 KCAL (10,250 kJ)", fill=(230, 240, 230, 255), font=font_small)
    draw.text((nx + 14, ny + 56), "ELECTROLYTES: SODIUM, POTASSIUM", fill=(200, 215, 200, 255), font=font_small)
    draw.text((nx + 14, ny + 76), "VITAMINS: A, B-COMPLEX, C, D3, IRON", fill=(200, 215, 200, 255), font=font_small)
    draw.text((nx + 14, ny + 96), "SHELF LIFE: 5 YEARS // LOT 104-V", fill=(46, 204, 113, 255), font=font_small)

    # 6. Inspection Stamp & Barcode
    # Circular Inspection Stamp
    st_x, st_y = 120, 420
    draw.ellipse([st_x - 45, st_y - 45, st_x + 45, st_y + 45], outline=(241, 196, 15, 200), width=2)
    draw.text((st_x - 36, st_y - 20), "INSPECTED", fill=(241, 196, 15, 220), font=font_tiny)
    draw.text((st_x - 30, st_y - 4), "PASSED", fill=(241, 196, 15, 220), font=font_med)
    draw.text((st_x - 36, st_y + 14), "V-QUARANTINE", fill=(241, 196, 15, 220), font=font_tiny)

    # Barcode
    bc_x, bc_y = 225, 385
    draw.rectangle([bc_x, bc_y, bc_x + 220, bc_y + 60], fill=(240, 245, 240, 255), outline=(0, 0, 0, 255), width=1)
    b_pos = bc_x + 12
    for w_bar in [3, 1, 4, 2, 1, 3, 2, 4, 1, 2, 3, 1, 4, 2, 3, 2, 1, 4, 2, 3, 2, 4, 1, 2, 3]:
        draw.rectangle([b_pos, bc_y + 6, b_pos + w_bar, bc_y + 44], fill=(0, 0, 0, 255))
        b_pos += w_bar + 3
    draw.text((bc_x + 40, bc_y + 46), "8 49204 10408 2", fill=(0, 0, 0, 255), font=font_tiny)

    img.save(path, "PNG")
    print(f"Generated {path}")

def generate_bandage_texture(path):
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    font_huge, font_large, font_med, font_small, font_tiny = get_fonts()

    # 1. Base Tactical Medical Cyan/Navy Blue Pouch Gradient
    for y in range(height):
        factor = 0.85 + 0.25 * (1.0 - y / height)
        r = int(24 * factor)
        g = int(48 * factor)
        b = int(72 * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # Cross-hatch sterile fabric gauze pattern
    for x in range(0, width, 8):
        draw.line([(x, 0), (x, height)], fill=(255, 255, 255, 8))
    for y in range(0, height, 8):
        draw.line([(0, y), (width, y)], fill=(255, 255, 255, 8))

    # 2. Waterproof Heat-Sealed Edge Borders
    seal_w = 28
    draw.rectangle([0, 0, width, seal_w], fill=(15, 30, 48, 255), outline=(0, 180, 255, 255))
    draw.rectangle([0, height - seal_w, width, height], fill=(15, 30, 48, 255), outline=(0, 180, 255, 255))
    draw.rectangle([0, 0, seal_w, height], fill=(15, 30, 48, 255), outline=(0, 180, 255, 255))
    draw.rectangle([width - seal_w, 0, width, height], fill=(15, 30, 48, 255), outline=(0, 180, 255, 255))

    # Clean White Center Medical Panel
    px1, py1 = 44, 44
    px2, py2 = width - 44, height - 44
    draw.rectangle([px1, py1, px2, py2], fill=(240, 246, 252, 255), outline=(0, 140, 255, 255), width=3)

    # Blue Medical Header Bar
    draw.rectangle([px1, py1, px2, py1 + 65], fill=(22, 100, 180, 255))
    draw.text((px1 + 20, py1 + 8), "COMBAT FIELD DRESSING", fill=(255, 255, 255, 255), font=font_large)
    draw.text((px1 + 22, py1 + 40), "STERILE COMPRESS BANDAGE // RAPID CLOT", fill=(180, 225, 255, 255), font=font_small)

    # 3. Medical Cross Emblem (Deep Red / Blue)
    cx, cy = width // 2, 215
    # White circle shadow
    draw.ellipse([cx - 75, cy - 75, cx + 75, cy + 75], fill=(225, 235, 245, 255), outline=(22, 100, 180, 255), width=3)

    # Vibrant Red Cross
    cross_w, cross_l = 28, 90
    draw.rectangle([cx - cross_w // 2, cy - cross_l // 2, cx + cross_w // 2, cy + cross_l // 2], fill=(231, 76, 60, 255), outline=(180, 40, 30, 255))
    draw.rectangle([cx - cross_l // 2, cy - cross_w // 2, cx + cross_l // 2, cy + cross_w // 2], fill=(231, 76, 60, 255), outline=(180, 40, 30, 255))

    # Cross bevel highlight
    draw.line([(cx - cross_w // 2 + 2, cy - cross_l // 2 + 2), (cx + cross_w // 2 - 2, cy - cross_l // 2 + 2)], fill=(255, 160, 150, 255), width=2)
    draw.line([(cx - cross_l // 2 + 2, cy - cross_w // 2 + 2), (cx - cross_l // 2 + 2, cy + cross_w // 2 - 2)], fill=(255, 160, 150, 255), width=2)

    # 4. Specifications Banner & HP Value
    draw.rectangle([px1 + 18, 310, px2 - 18, 375], fill=(24, 38, 56, 255), outline=(0, 150, 255, 255), width=2)
    draw.text((px1 + 32, 320), "TRAUMA RECOVERY", fill=(0, 210, 255, 255), font=font_large)
    draw.text((px1 + 34, 350), "ELASTIC COMPRESS + HEMOSTATIC AGENT", fill=(200, 220, 240, 255), font=font_small)

    # +30 HP Badge
    draw.rectangle([px2 - 110, 318, px2 - 28, 368], fill=(41, 128, 185, 255), outline=(0, 210, 255, 255), width=1)
    draw.text((px2 - 100, 324), "+30", fill=(255, 255, 255, 255), font=font_large)
    draw.text((px2 - 88, 350), "HP", fill=(220, 240, 255, 255), font=font_small)

    # 5. Medical Symbols & Certification
    draw.text((px1 + 24, 395), "STERILE [EO] // SINGLE USE", fill=(40, 60, 80, 255), font=font_med)
    draw.text((px1 + 24, 418), "GAUZE ROLL: 10cm x 4.5m // NON-ADHERENT PAD", fill=(80, 100, 120, 255), font=font_small)
    draw.text((px1 + 24, 436), "VANGUARD MEDICAL STANDARDS // LOT: BDG-992", fill=(41, 128, 185, 255), font=font_small)

    # CE & Medical Cross Symbols (Right bottom)
    draw.rectangle([px2 - 130, 395, px2 - 24, 450], fill=(230, 238, 248, 255), outline=(180, 200, 220, 255), width=1)
    draw.text((px2 - 118, 404), "CE 0123", fill=(30, 50, 70, 255), font=font_large)
    draw.text((px2 - 116, 432), "REF #8820", fill=(100, 120, 140, 255), font=font_tiny)

    img.save(path, "PNG")
    print(f"Generated {path}")

def generate_medkit_texture(path):
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    font_huge, font_large, font_med, font_small, font_tiny = get_fonts()

    # 1. Base High-Impact Medical Composite Casing (Light Crisp Medical Off-White / Grey)
    for y in range(height):
        factor = 0.92 + 0.16 * (1.0 - y / height)
        r = int(235 * factor)
        g = int(240 * factor)
        b = int(245 * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # 2. Outer Carbon-Steel Reinforced Heavy Frame (Tactical Dark Slate)
    frame_w = 34
    frame_col = (30, 36, 44, 255)
    frame_border = (192, 57, 43, 255) # Red emergency border
    draw.rectangle([0, 0, width, frame_w], fill=frame_col, outline=frame_border, width=2)
    draw.rectangle([0, height - frame_w, width, height], fill=frame_col, outline=frame_border, width=2)
    draw.rectangle([0, 0, frame_w, height], fill=frame_col, outline=frame_border, width=2)
    draw.rectangle([width - frame_w, 0, width, height], fill=frame_col, outline=frame_border, width=2)

    # 3. Heavy Corner Protective Bumpers (Hex bolts in corners)
    corner_size = 56
    for cx, cy in [(0, 0), (width - corner_size, 0), (0, height - corner_size), (width - corner_size, height - corner_size)]:
        draw.rectangle([cx, cy, cx + corner_size, cy + corner_size], fill=(20, 24, 30, 255), outline=(100, 115, 130, 255), width=2)
        # Hex bolt in center of corner bumper
        bx, by = cx + corner_size // 2, cy + corner_size // 2
        for a in range(6):
            angle = a * math.pi / 3
            draw.polygon([(bx + 5 * math.cos(a * math.pi / 3), by + 5 * math.sin(a * math.pi / 3)) for a in range(6)], fill=(180, 195, 210, 255), outline=(10, 15, 20, 255))

    # 4. Top & Bottom Red Warning Rails
    draw.rectangle([frame_w, frame_w, width - frame_w, frame_w + 14], fill=(192, 57, 43, 255))
    draw.rectangle([frame_w, height - frame_w - 14, width - frame_w, height - frame_w], fill=(192, 57, 43, 255))

    # 5. Top Carrying Handle & Latches
    handle_cx = width // 2
    draw.rectangle([handle_cx - 65, 6, handle_cx + 65, 26], fill=(55, 65, 75, 255), outline=(140, 155, 170, 255), width=2)
    draw.rectangle([handle_cx - 50, 12, handle_cx + 50, 22], fill=(15, 18, 22, 255))

    # Dual locking latches
    for lx in [width // 2 - 110, width // 2 + 110]:
        draw.rectangle([lx - 16, 28, lx + 16, 68], fill=(160, 175, 190, 255), outline=(30, 36, 44, 255), width=2)
        draw.rectangle([lx - 10, 44, lx + 10, 62], fill=(241, 196, 15, 255), outline=(0, 0, 0, 255), width=1)

    # 6. Center Hero Graphic: Large Medical Emergency Cross Shield
    cx, cy = width // 2, 215
    # Beveled circular base
    draw.ellipse([cx - 88, cy - 88, cx + 88, cy + 88], fill=(255, 255, 255, 255), outline=(192, 57, 43, 255), width=5)
    draw.ellipse([cx - 82, cy - 82, cx + 82, cy + 82], outline=(220, 225, 230, 255), width=2)

    # Bold Red Cross
    cross_w, cross_l = 36, 110
    draw.rectangle([cx - cross_w // 2, cy - cross_l // 2, cx + cross_w // 2, cy + cross_l // 2], fill=(214, 48, 49, 255), outline=(150, 20, 20, 255))
    draw.rectangle([cx - cross_l // 2, cy - cross_w // 2, cx + cross_l // 2, cy + cross_w // 2], fill=(214, 48, 49, 255), outline=(150, 20, 20, 255))

    # Cross 3D bevel specular highlights
    draw.line([(cx - cross_w // 2 + 3, cy - cross_l // 2 + 3), (cx + cross_w // 2 - 3, cy - cross_l // 2 + 3)], fill=(255, 170, 170, 255), width=3)
    draw.line([(cx - cross_l // 2 + 3, cy - cross_w // 2 + 3), (cx - cross_l // 2 + 3, cy + cross_w // 2 - 3)], fill=(255, 170, 170, 255), width=3)

    # 7. Main Typography & Identification
    # Top Header
    draw.text((frame_w + 18, 58), "EMERGENCY MEDICAL KIT", fill=(192, 57, 43, 255), font=font_large)
    draw.text((frame_w + 20, 88), "ADVANCED TRAUMA LIFE SUPPORT SYSTEM", fill=(60, 70, 80, 255), font=font_small)

    # Bottom Spec Box
    bx1, by1 = frame_w + 14, 325
    bx2, by2 = width - frame_w - 14, height - frame_w - 22
    draw.rectangle([bx1, by1, bx2, by2], fill=(25, 30, 38, 240), outline=(192, 57, 43, 255), width=2)

    # Recovery Value Badge (+50 HP)
    hbx = bx2 - 110
    draw.rectangle([hbx, by1 + 10, bx2 - 12, by2 - 10], fill=(192, 57, 43, 255), outline=(255, 100, 100, 255), width=1)
    draw.text((hbx + 16, by1 + 16), "+50", fill=(255, 255, 255, 255), font=font_huge)
    draw.text((hbx + 14, by1 + 62), "CRITICAL AID", fill=(255, 220, 220, 255), font=font_tiny)

    # Specs text
    draw.text((bx1 + 18, by1 + 14), "CONTENTS // SURGICAL GRADE", fill=(241, 196, 15, 255), font=font_med)
    draw.text((bx1 + 18, by1 + 38), "• AUTOMATED BIO-FOAM CANISTER (RAPID SEAL)", fill=(240, 245, 250, 255), font=font_small)
    draw.text((bx1 + 18, by1 + 56), "• EPINEPHRINE & NEURO-STIMULANT AUTO-INJECTOR", fill=(240, 245, 250, 255), font=font_small)
    draw.text((bx1 + 18, by1 + 74), "• DIGITAL DEFIBRILLATOR // PLASMA SUTURE PACK", fill=(200, 215, 230, 255), font=font_small)

    img.save(path, "PNG")
    print(f"Generated {path}")

if __name__ == "__main__":
    os.makedirs("assets/textures", exist_ok=True)
    generate_food_pack_texture("assets/textures/food_pack.png")
    generate_bandage_texture("assets/textures/bandage.png")
    generate_medkit_texture("assets/textures/medkit.png")
