import os
import math
from PIL import Image, ImageDraw, ImageFont

def generate_container_texture(filename, main_color, accent_color, cont_id, cont_class, max_wt, symbol_type):
    width = 512
    height = 512
    img = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # 1. Base metal gradient fill
    r_base, g_base, b_base = main_color
    for y in range(height):
        # Subtle vertical lighting gradient (brighter near top, darker near bottom)
        factor = 0.85 + 0.25 * (1.0 - y / height)
        # Edge darkening
        r = int(min(255, max(0, r_base * factor)))
        g = int(min(255, max(0, g_base * factor)))
        b = int(min(255, max(0, b_base * factor)))
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    # 2. Corrugated vertical ribs (ribs run vertically, spaced every 32px)
    rib_width = 32
    for x in range(32, width - 32, rib_width):
        # Rib bevel: left side highlight, right side shadow
        for i in range(rib_width // 2):
            t = i / (rib_width // 2)
            # Highlight slope
            hl_r = int(min(255, r_base * (1.15 + 0.15 * t)))
            hl_g = int(min(255, g_base * (1.15 + 0.15 * t)))
            hl_b = int(min(255, b_base * (1.15 + 0.15 * t)))
            draw.line([(x + i, 40), (x + i, height - 40)], fill=(hl_r, hl_g, hl_b, 255))
        for i in range(rib_width // 2):
            t = i / (rib_width // 2)
            # Shadow slope
            sh_r = int(max(0, r_base * (0.85 - 0.25 * t)))
            sh_g = int(max(0, g_base * (0.85 - 0.25 * t)))
            sh_b = int(max(0, b_base * (0.85 - 0.25 * t)))
            draw.line([(x + rib_width // 2 + i, 40), (x + rib_width // 2 + i, height - 40)], fill=(sh_r, sh_g, sh_b, 255))
        # Deep recess groove
        draw.line([(x, 40), (x, height - 40)], fill=(20, 20, 25, 200))

    # 3. Outer Structural Steel Perimeter Frame (Dark Gunmetal Rails)
    frame_col = (30, 36, 44, 255)
    frame_border = (60, 70, 82, 255)
    # Top rail
    draw.rectangle([0, 0, width, 40], fill=frame_col, outline=frame_border, width=2)
    # Bottom rail
    draw.rectangle([0, height - 40, width, height], fill=frame_col, outline=frame_border, width=2)
    # Left rail
    draw.rectangle([0, 0, 32, height], fill=frame_col, outline=frame_border, width=2)
    # Right rail
    draw.rectangle([width - 32, 0, width, height], fill=frame_col, outline=frame_border, width=2)

    # 4. Corner Castings (Heavy steel blocks with twistlock sockets)
    corner_size = 46
    for cx, cy in [(0, 0), (width - corner_size, 0), (0, height - corner_size), (width - corner_size, height - corner_size)]:
        draw.rectangle([cx, cy, cx + corner_size, cy + corner_size], fill=(22, 26, 32, 255), outline=(90, 105, 120, 255), width=2)
        # Twistlock oval hole
        ox, oy = cx + corner_size // 2, cy + corner_size // 2
        draw.ellipse([ox - 10, oy - 14, ox + 10, oy + 14], fill=(8, 10, 12, 255), outline=(120, 135, 150, 255), width=2)

    # 5. Rivet Studs along rails
    for x in range(50, width - 50, 24):
        # Top rivets
        draw.ellipse([x - 3, 20 - 3, x + 3, 20 + 3], fill=(80, 95, 110, 255), outline=(15, 20, 25, 255))
        # Bottom rivets
        draw.ellipse([x - 3, height - 20 - 3, x + 3, height - 20 + 3], fill=(80, 95, 110, 255), outline=(15, 20, 25, 255))
    for y in range(50, height - 50, 28):
        # Left rivets
        draw.ellipse([16 - 3, y - 3, 16 + 3, y + 3], fill=(80, 95, 110, 255), outline=(15, 20, 25, 255))
        # Right rivets
        draw.ellipse([width - 16 - 3, y - 3, width - 16 + 3, y + 3], fill=(80, 95, 110, 255), outline=(15, 20, 25, 255))

    # 6. Yellow & Black Hazard Stripes along bottom edge
    stripe_w = 16
    for s in range(0, width, stripe_w * 2):
        pts = [(s, height - 36), (s + stripe_w, height - 36), (s + stripe_w - 12, height - 6), (s - 12, height - 6)]
        draw.polygon(pts, fill=(241, 196, 15, 230))
        pts_b = [(s + stripe_w, height - 36), (s + stripe_w * 2, height - 36), (s + stripe_w * 2 - 12, height - 6), (s + stripe_w - 12, height - 6)]
        draw.polygon(pts_b, fill=(15, 15, 18, 230))

    # 7. Dual Door Locking Bars (vertical galvanized steel rods down center)
    rod_x1 = width // 2 - 32
    rod_x2 = width // 2 + 32
    for rx in (rod_x1, rod_x2):
        # Rod shadow
        draw.rectangle([rx - 8, 42, rx + 8, height - 42], fill=(12, 14, 18, 180))
        # Steel rod body
        draw.rectangle([rx - 6, 42, rx + 6, height - 42], fill=(160, 175, 190, 255), outline=(40, 50, 60, 255), width=1)
        # Specular shine line down rod
        draw.line([(rx - 2, 42), (rx - 2, height - 42)], fill=(230, 240, 250, 220))
        # Cam lock brackets
        for by in (70, height // 2 - 50, height // 2 + 50, height - 70):
            draw.rectangle([rx - 12, by - 8, rx + 12, by + 8], fill=(60, 70, 80, 255), outline=(20, 25, 30, 255), width=2)
            draw.ellipse([rx - 10, by - 3, rx - 6, by + 1], fill=(200, 210, 220, 255))
            draw.ellipse([rx + 6, by - 3, rx + 10, by + 1], fill=(200, 210, 220, 255))
        # Locking handle / lever in middle
        draw.rectangle([rx - 14, height // 2 - 4, rx + 24, height // 2 + 6], fill=(210, 130, 30, 255), outline=(30, 20, 10, 255), width=1)
        draw.rectangle([rx + 16, height // 2 - 16, rx + 24, height // 2 + 20], fill=(220, 20, 20, 255), outline=(0, 0, 0, 255), width=1)

    # 8. Industrial Stencil Badges & Placards
    # Vanguard Freight Stencil Badge (Left side)
    draw.rectangle([54, 60, 190, 140], fill=(16, 20, 26, 220), outline=(80, 95, 110, 255), width=2)
    # Stencil Text
    draw.text((62, 68), "VANGUARD", fill=(240, 246, 252, 255))
    draw.text((62, 84), "LOGISTICS // SECTOR 1", fill=(120, 140, 160, 255))
    draw.text((62, 102), cont_id, fill=accent_color)
    draw.text((62, 120), cont_class, fill=(200, 210, 225, 255))

    # Right side Weight & Specs Placard
    draw.rectangle([width - 190, 60, width - 54, 140], fill=(16, 20, 26, 220), outline=(80, 95, 110, 255), width=2)
    draw.text((width - 182, 68), "SPECIFICATION", fill=(240, 246, 252, 255))
    draw.text((width - 182, 84), max_wt, fill=(241, 196, 15, 255))
    draw.text((width - 182, 102), "TARE: 3,820 KG", fill=(160, 175, 190, 255))
    draw.text((width - 182, 120), "VOL: 76.2 CU.M", fill=(160, 175, 190, 255))

    # Central Hazard Diamond Placard
    hdx = width // 2
    hdy = 195
    hds = 34
    draw.polygon([(hdx, hdy - hds), (hdx + hds, hdy), (hdx, hdy + hds), (hdx - hds, hdy)], fill=(243, 156, 18, 255), outline=(10, 10, 12, 255), width=2)
    # Inner border
    draw.polygon([(hdx, hdy - hds + 4), (hdx + hds - 4, hdy), (hdx, hdy + hds - 4), (hdx - hds + 4, hdy)], fill=None, outline=(0, 0, 0, 255), width=2)
    draw.text((hdx - 12, hdy - 8), symbol_type, fill=(0, 0, 0, 255))

    # Large Serial Number Stenciled in Middle
    draw.text((60, 260), cont_id, fill=(255, 255, 255, 230))
    draw.text((60, 280), "ARMORED FREIGHT UNIT", fill=(200, 215, 230, 200))
    draw.text((60, 296), "SEAL INTEGRITY: 100% OK", fill=(46, 204, 113, 240))

    # Right side barcode
    bc_x = width - 170
    bc_y = 260
    draw.rectangle([bc_x, bc_y, bc_x + 115, bc_y + 40], fill=(240, 245, 250, 255), outline=(0, 0, 0, 255), width=1)
    bar_pos = bc_x + 6
    for w_bar in [3, 1, 4, 2, 1, 3, 2, 4, 1, 2, 3, 1, 4, 2, 3, 2, 1, 4, 2]:
        draw.rectangle([bar_pos, bc_y + 4, bar_pos + w_bar, bc_y + 36], fill=(0, 0, 0, 255))
        bar_pos += w_bar + 2

    # Save to file
    img.save(filename, "PNG")
    print(f"Generated {filename}")

os.makedirs("assets/textures", exist_ok=True)
generate_container_texture(
    "assets/textures/container_red.png",
    main_color=(192, 57, 43),
    accent_color=(255, 100, 100, 255),
    cont_id="CONT-842-RED",
    cont_class="HAZMAT CLASS 4",
    max_wt="MAX WT: 30,480 KG",
    symbol_type="FLAM"
)
generate_container_texture(
    "assets/textures/container_blue.png",
    main_color=(41, 128, 185),
    accent_color=(100, 200, 255, 255),
    cont_id="CONT-719-BLU",
    cont_class="CRYO CLASS 2",
    max_wt="MAX WT: 30,480 KG",
    symbol_type="CRYO"
)
generate_container_texture(
    "assets/textures/container_orange.png",
    main_color=(211, 84, 0),
    accent_color=(255, 175, 50, 255),
    cont_id="CONT-330-ORG",
    cont_class="MUNITIONS CL 1",
    max_wt="MAX WT: 24,000 KG",
    symbol_type="EXPL"
)
generate_container_texture(
    "assets/textures/container_green.png",
    main_color=(39, 174, 96),
    accent_color=(120, 255, 150, 255),
    cont_id="CONT-512-GRN",
    cont_class="BIO-SPECIMEN CL 6",
    max_wt="MAX WT: 24,000 KG",
    symbol_type="BIO"
)
