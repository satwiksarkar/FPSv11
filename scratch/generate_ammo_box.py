import os
import math
from PIL import Image, ImageDraw, ImageFont

def generate_ammo_box_texture(filename="assets/textures/ammo_box.png"):
    width = 512
    height = 512
    img = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # 1. Base Military Olive-Drab Metal Background with subtle gradient & noise
    # Tactical Army Olive Drab: #374635 (55, 70, 53) to #2a3528 (42, 53, 40)
    for y in range(height):
        factor = 0.88 + 0.24 * (1.0 - y / height)
        # Subtle horizontal vignette from center
        r_b = int(55 * factor)
        g_b = int(72 * factor)
        b_b = int(52 * factor)
        draw.line([(0, y), (width, y)], fill=(r_b, g_b, b_b, 255))

    # Add subtle brushed metal scanlines
    for y in range(0, height, 4):
        draw.line([(0, y), (width, y)], fill=(255, 255, 255, 8))

    # 2. Stamped Heavy Horizontal Reinforcement Ribs in the metal body
    # Two recessed horizontal grooves across middle area
    for rib_y in [140, 360]:
        # Upper shadow
        draw.rectangle([36, rib_y, width - 36, rib_y + 16], fill=(22, 28, 20, 255))
        # Lower highlight
        draw.rectangle([36, rib_y + 16, width - 36, rib_y + 24], fill=(90, 115, 85, 255))
        # Recess interior
        draw.rectangle([38, rib_y + 3, width - 38, rib_y + 13], fill=(30, 38, 28, 255))

    # 3. Outer Reinforced Heavy Carbon Steel Frame (Dark Gunmetal border)
    frame_w = 34
    steel_col = (28, 32, 38, 255)
    steel_border = (65, 75, 85, 255)
    steel_hl = (110, 125, 140, 255)

    # Outer perimeter rails
    draw.rectangle([0, 0, width, frame_w], fill=steel_col, outline=steel_border, width=2)
    draw.rectangle([0, height - frame_w, width, height], fill=steel_col, outline=steel_border, width=2)
    draw.rectangle([0, 0, frame_w, height], fill=steel_col, outline=steel_border, width=2)
    draw.rectangle([width - frame_w, 0, width, height], fill=steel_col, outline=steel_border, width=2)

    # Frame inner bevel highlight lines
    draw.line([(frame_w, frame_w), (width - frame_w, frame_w)], fill=steel_hl, width=1)
    draw.line([(frame_w, frame_w), (frame_w, height - frame_w)], fill=steel_hl, width=1)
    draw.line([(frame_w, height - frame_w), (width - frame_w, height - frame_w)], fill=(12, 14, 18, 255), width=2)
    draw.line([(width - frame_w, frame_w), (width - frame_w, height - frame_w)], fill=(12, 14, 18, 255), width=2)

    # 4. Heavy Reinforced Steel Corner Brackets with L-shapes
    corner_size = 64
    for cx, cy in [(0, 0), (width - corner_size, 0), (0, height - corner_size), (width - corner_size, height - corner_size)]:
        draw.rectangle([cx, cy, cx + corner_size, cy + corner_size], fill=(22, 25, 30, 255), outline=steel_hl, width=2)
        # Inner corner plate bevel
        draw.rectangle([cx + 6, cy + 6, cx + corner_size - 6, cy + corner_size - 6], fill=(36, 42, 50, 255), outline=(15, 18, 22, 255), width=1)

    # 5. Hexagonal Heavy Steel Machine Bolts / Rivets in corners and along rails
    def draw_hex_bolt(bx, by, radius=6):
        pts = []
        for a in range(6):
            angle = a * math.pi / 3
            pts.append((bx + radius * math.cos(angle), by + radius * math.sin(angle)))
        draw.polygon(pts, fill=(180, 195, 210, 255), outline=(20, 25, 30, 255))
        # Inner socket
        draw.polygon([(bx + (radius - 2.5) * math.cos(a * math.pi / 3), by + (radius - 2.5) * math.sin(a * math.pi / 3)) for a in range(6)], fill=(50, 60, 70, 255))
        # Specular glint
        draw.point((int(bx - 1), int(by - 1)), fill=(255, 255, 255, 255))

    # Corner bolts
    for cx, cy in [(18, 18), (width - 18, 18), (18, height - 18), (width - 18, height - 18),
                   (48, 18), (18, 48), (width - 48, 18), (width - 18, 48),
                   (48, height - 18), (18, height - 48), (width - 48, height - 18), (width - 18, height - 48)]:
        draw_hex_bolt(cx, cy, 5)

    # Frame rail rivets
    for x in range(96, width - 96, 40):
        draw_hex_bolt(x, 16, 4)
        draw_hex_bolt(x, height - 16, 4)
    for y in range(96, height - 96, 44):
        draw_hex_bolt(16, y, 4)
        draw_hex_bolt(width - 16, y, 4)

    # 6. Yellow & Black Hazard Stripes on Top and Bottom Rails
    stripe_w = 18
    # Bottom hazard rail
    for s in range(36, width - 36, stripe_w * 2):
        pts = [(s, height - 32), (s + stripe_w, height - 32), (s + stripe_w - 10, height - 6), (s - 10, height - 6)]
        draw.polygon(pts, fill=(241, 196, 15, 240))
        pts_b = [(s + stripe_w, height - 32), (s + stripe_w * 2, height - 32), (s + stripe_w * 2 - 10, height - 6), (s + stripe_w - 10, height - 6)]
        draw.polygon(pts_b, fill=(20, 20, 24, 240))

    # 7. Heavy Latch / Locking Clasp at Top Center
    latch_cx = width // 2
    latch_w = 44
    latch_h = 42
    # Latch base plate
    draw.rectangle([latch_cx - latch_w // 2, 4, latch_cx + latch_w // 2, 4 + latch_h], fill=(45, 52, 60, 255), outline=(100, 115, 130, 255), width=2)
    # Latch lever handle
    draw.rectangle([latch_cx - 14, 16, latch_cx + 14, 46], fill=(190, 160, 80, 255), outline=(30, 25, 10, 255), width=1)
    draw.line([(latch_cx - 10, 20), (latch_cx - 10, 42)], fill=(255, 240, 180, 255), width=2)
    # Red safety locking pin
    draw.ellipse([latch_cx - 6, 26, latch_cx + 6, 38], fill=(231, 76, 60, 255), outline=(60, 10, 10, 255), width=1)

    # 8. Main Center Tactical Stencils:
    # Stencil Header Box
    box_x1 = 58
    box_y1 = 54
    box_x2 = width - 58
    box_y2 = 132
    draw.rectangle([box_x1, box_y1, box_x2, box_y2], fill=(20, 26, 20, 200), outline=(241, 196, 15, 230), width=2)

    # Inner decorative corners on stencil box
    draw.line([(box_x1 + 8, box_y1 + 4), (box_x1 + 4, box_y1 + 4), (box_x1 + 4, box_y1 + 8)], fill=(241, 196, 15, 255), width=2)
    draw.line([(box_x2 - 8, box_y1 + 4), (box_x2 - 4, box_y1 + 4), (box_x2 - 4, box_y1 + 8)], fill=(241, 196, 15, 255), width=2)
    draw.line([(box_x1 + 8, box_y2 - 4), (box_x1 + 4, box_y2 - 4), (box_x1 + 4, box_y2 - 8)], fill=(241, 196, 15, 255), width=2)
    draw.line([(box_x2 - 8, box_y2 - 4), (box_x2 - 4, box_y2 - 4), (box_x2 - 4, box_y2 - 8)], fill=(241, 196, 15, 255), width=2)

    # Try loading a clean font or fallback to default
    try:
        font_large = ImageFont.truetype("arialbd.ttf", 34)
        font_med = ImageFont.truetype("arialbd.ttf", 16)
        font_small = ImageFont.truetype("arial.ttf", 12)
        font_huge = ImageFont.truetype("arialbd.ttf", 46)
    except:
        font_large = ImageFont.load_default()
        font_med = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_huge = ImageFont.load_default()

    # Large Stencil Text: AMMUNITION / HIGH VELOCITY
    draw.text((box_x1 + 16, box_y1 + 10), "AMMUNITION", fill=(241, 196, 15, 255), font=font_large)
    draw.text((box_x1 + 18, box_y1 + 48), "VANGUARD MIL-SPEC // HIGH-EXPLOSIVE AP", fill=(220, 230, 220, 255), font=font_small)

    # Right side of header box: Caliber badge
    cal_box = [box_x2 - 120, box_y1 + 10, box_x2 - 12, box_y2 - 10]
    draw.rectangle(cal_box, fill=(241, 196, 15, 255))
    draw.text((cal_box[0] + 12, cal_box[1] + 6), "12.7mm", fill=(15, 20, 15, 255), font=font_large)
    draw.text((cal_box[0] + 18, cal_box[1] + 42), "ARMOR PIERCING", fill=(30, 40, 30, 255), font=font_small)

    # 9. Center Graphic: 5 High-Caliber Brass Cartridges / Bullets
    # Render realistic brass cartridges in a row in the middle section (Y: 175..325)
    bullet_start_x = 100
    bullet_spacing = 64
    bullet_y = 180
    bullet_h = 135
    bullet_w = 32

    for b_idx in range(5):
        bx = bullet_start_x + b_idx * bullet_spacing

        # Bullet shadow behind
        draw.rectangle([bx + 4, bullet_y + 4, bx + bullet_w + 4, bullet_y + bullet_h + 4], fill=(15, 20, 15, 120))

        # Casing body (brass cylinder: gradient from dark bronze to bright gold shine)
        casing_top = bullet_y + 48
        casing_bot = bullet_y + bullet_h

        # Draw casing with horizontal gradient shine
        for cx in range(bullet_w):
            t = cx / bullet_w
            # Specular highlight peak near 30% from left
            shine = math.exp(-((t - 0.35) ** 2) / 0.05)
            r_c = int(min(255, 180 + 75 * shine))
            g_c = int(min(255, 140 + 90 * shine))
            b_c = int(min(255, 40 + 120 * shine))
            draw.line([(bx + cx, casing_top), (bx + cx, casing_bot)], fill=(r_c, g_c, b_c, 255))

        # Casing rim at bottom
        draw.rectangle([bx - 2, casing_bot - 8, bx + bullet_w + 2, casing_bot], fill=(140, 105, 25, 255), outline=(50, 40, 10, 255), width=1)
        # Extraction groove
        draw.rectangle([bx + 2, casing_bot - 14, bx + bullet_w - 2, casing_bot - 8], fill=(40, 30, 10, 255))

        # Casing neck / shoulder taper
        neck_top = bullet_y + 36
        neck_w = 20
        neck_x = bx + (bullet_w - neck_w) // 2
        shoulder_pts = [(bx, casing_top), (bx + bullet_w, casing_top), (neck_x + neck_w, neck_top + 4), (neck_x, neck_top + 4)]
        draw.polygon(shoulder_pts, fill=(190, 150, 40, 255), outline=(50, 40, 10, 255))

        # Neck
        draw.rectangle([neck_x, neck_top, neck_x + neck_w, neck_top + 4], fill=(200, 160, 45, 255))

        # Copper Bullet Ogive / Tip (pointed streamlined projectile)
        tip_pts = [
            (neck_x, neck_top),
            (neck_x + neck_w, neck_top),
            (neck_x + neck_w - 2, bullet_y + 14),
            (bx + bullet_w // 2, bullet_y),
            (neck_x + 2, bullet_y + 14)
        ]
        # Copper color with highlight
        draw.polygon(tip_pts, fill=(210, 85, 40, 255), outline=(70, 25, 10, 255), width=1)
        # Copper specular line
        draw.line([(bx + bullet_w // 2 - 2, bullet_y + 3), (neck_x + 5, neck_top - 2)], fill=(255, 160, 100, 200), width=2)

    # 10. Munitions Specs & Identification Text
    specs_y = 385
    draw.text((62, specs_y), "CALIBER: 12.7 x 99mm NATO // LOT: 894-B", fill=(240, 245, 240, 240), font=font_med)
    draw.text((62, specs_y + 24), "ARMOR PIERCING INCENDIARY [API-T]", fill=(241, 196, 15, 255), font=font_med)
    draw.text((62, specs_y + 46), "MAX LOAD: 250 RDS // NET WT: 14.2 KG", fill=(180, 200, 180, 220), font=font_small)
    draw.text((62, specs_y + 64), "SECURITY SEAL: INTACT // UNRESTRICTED RESUPPLY", fill=(46, 204, 113, 255), font=font_small)

    # 11. Munitions Hazard Class 1.4S Diamond Placard (Right side)
    hx = width - 105
    hy = 425
    hs = 36
    draw.polygon([(hx, hy - hs), (hx + hs, hy), (hx, hy + hs), (hx - hs, hy)], fill=(230, 126, 34, 255), outline=(15, 18, 22, 255), width=2)
    # Inner border
    draw.polygon([(hx, hy - hs + 4), (hx + hs - 4, hy), (hx, hy + hs - 4), (hx - hs + 4, hy)], fill=None, outline=(255, 255, 255, 220), width=2)
    draw.text((hx - 16, hy - 14), "1.4S", fill=(10, 15, 20, 255), font=font_med)
    draw.text((hx - 12, hy + 4), "EXPL", fill=(10, 15, 20, 255), font=font_small)

    # Save texture
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename, "PNG")
    print(f"Generated {filename} (size: {width}x{height})")

if __name__ == "__main__":
    generate_ammo_box_texture()
