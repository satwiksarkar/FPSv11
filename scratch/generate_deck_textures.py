"""
Generates floor_deck.png and floor_hallway.png for Project VANGUARD.
"""
from PIL import Image
import random
import os

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def create_deck_texture(is_hallway=False):
    random.seed(42) # Reproducible brushed grain
    width, height = 64, 64
    img = Image.new('RGBA', (width, height), (0, 0, 0, 255))
    pixels = img.load()

    c_base = hex_to_rgb('#1C2128')       # (28, 33, 40)
    c_face = hex_to_rgb('#2A313C')       # (42, 49, 60)
    c_seam = hex_to_rgb('#111418')       # (17, 20, 24)
    c_bevel_hi = hex_to_rgb('#36404E')   # (54, 64, 78) - subtle highlight
    c_bevel_lo = hex_to_rgb('#191E25')   # (25, 30, 37) - subtle shadow

    # Initial fill with base
    for y in range(height):
        for x in range(width):
            pixels[x, y] = (*c_base, 255)

    # 2x2 Plate Grid: Plate 0 at (1..30, 1..30), Plate 1 at (33..62, 1..30), etc.
    plate_bounds = [
        (1, 30, 1, 30),
        (33, 62, 1, 30),
        (1, 30, 33, 62),
        (33, 62, 33, 62)
    ]

    for (x1, x2, y1, y2) in plate_bounds:
        # Fill plate face with brushed metal grain
        for y in range(y1, y2 + 1):
            # Horizontal grain line base modulation
            row_noise = random.randint(-2, 2)
            for x in range(x1, x2 + 1):
                col_noise = random.randint(-2, 2)
                # Brushed streaks along x with slight micro-variation
                r = max(0, min(255, c_face[0] + row_noise + (col_noise // 2)))
                g = max(0, min(255, c_face[1] + row_noise + (col_noise // 2)))
                b = max(0, min(255, c_face[2] + row_noise + col_noise))
                pixels[x, y] = (r, g, b, 255)

        # Subtle plate bevel:
        # Top & Left edges: bevel highlight
        for x in range(x1, x2 + 1):
            pixels[x, y1] = (*c_bevel_hi, 255)
        for y in range(y1, y2 + 1):
            pixels[x1, y] = (*c_bevel_hi, 255)

        # Bottom & Right edges: bevel shadow
        for x in range(x1, x2 + 1):
            pixels[x, y2] = (*c_bevel_lo, 255)
        for y in range(y1, y2 + 1):
            pixels[x2, y] = (*c_bevel_lo, 255)

        # Corner rivets in 4 corners of each plate
        rivet_offsets = [
            (x1 + 3, y1 + 3),
            (x2 - 4, y1 + 3),
            (x1 + 3, y2 - 4),
            (x2 - 4, y2 - 4)
        ]

        c_rivet_hi = hex_to_rgb('#4E5A6C') # specular glint
        c_rivet_mid = hex_to_rgb('#2E3743')
        c_rivet_lo = hex_to_rgb('#13171D')  # recessed socket

        for rx, ry in rivet_offsets:
            pixels[rx, ry] = (*c_rivet_hi, 255)
            pixels[rx + 1, ry] = (*c_rivet_mid, 255)
            pixels[rx, ry + 1] = (*c_rivet_mid, 255)
            pixels[rx + 1, ry + 1] = (*c_rivet_lo, 255)

    # Recessed seams (Outer borders and cross dividing line)
    # Outer edge: x=0, x=63, y=0, y=63
    # Center dividing seams: x in [31, 32], y in [31, 32]
    seam_x_coords = [0, 31, 32, 63]
    seam_y_coords = [0, 31, 32, 63]

    for y in range(height):
        for sx in seam_x_coords:
            pixels[sx, y] = (*c_seam, 255)
    for x in range(width):
        for sy in seam_y_coords:
            pixels[x, sy] = (*c_seam, 255)

    # If this is the Hallway variant:
    if is_hallway:
        # 1. Subtle, muted center directional guide stripe along x in [30..33]
        # With faint directional indicator (chevrons/dashes pointing north every 8 pixels)
        c_stripe_base = hex_to_rgb('#485464')  # Muted cool steel guide
        c_stripe_amber = hex_to_rgb('#5E5638') # Faint tactical amber accent
        c_stripe_glow = hex_to_rgb('#3E4856')

        for y in range(height):
            # Recessed groove flanking the center runner
            pixels[29, y] = (*c_seam, 255)
            pixels[34, y] = (*c_seam, 255)

            # Center stripe body
            pattern_pos = y % 16
            if pattern_pos in [6, 7, 8]:
                # Directional chevron / arrow peak
                pixels[30, y] = (*c_stripe_amber, 255)
                pixels[31, y] = (*c_stripe_amber, 255)
                pixels[32, y] = (*c_stripe_amber, 255)
                pixels[33, y] = (*c_stripe_amber, 255)
            elif pattern_pos in [5, 9]:
                pixels[30, y] = (*c_stripe_glow, 255)
                pixels[31, y] = (*c_stripe_base, 255)
                pixels[32, y] = (*c_stripe_base, 255)
                pixels[33, y] = (*c_stripe_glow, 255)
            else:
                pixels[30, y] = (*c_stripe_glow, 255)
                pixels[31, y] = (*c_stripe_base, 255)
                pixels[32, y] = (*c_stripe_base, 255)
                pixels[33, y] = (*c_stripe_glow, 255)

        # 2. Faint edge trim (outer hazard border along x in [3..4] and [59..60])
        c_edge_dark = hex_to_rgb('#1A2028')
        c_edge_amber = hex_to_rgb('#4A442E') # Muted hazard hash

        for y in range(height):
            is_hash = ((x_offset + y) // 4) % 2 == 0 if False else ((y // 4) % 2 == 0)
            col_hash = c_edge_amber if is_hash else c_edge_dark
            pixels[3, y] = (*col_hash, 255)
            pixels[4, y] = (*col_hash, 255)
            pixels[59, y] = (*col_hash, 255)
            pixels[60, y] = (*col_hash, 255)

    return img

if __name__ == '__main__':
    out_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'textures')
    os.makedirs(out_dir, exist_ok=True)

    img_deck = create_deck_texture(is_hallway=False)
    deck_path = os.path.join(out_dir, 'floor_deck.png')
    img_deck.save(deck_path)
    print(f'Saved {deck_path} ({img_deck.size})')

    img_hallway = create_deck_texture(is_hallway=True)
    hallway_path = os.path.join(out_dir, 'floor_hallway.png')
    img_hallway.save(hallway_path)
    print(f'Saved {hallway_path} ({img_hallway.size})')
