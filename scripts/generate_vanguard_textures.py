import os
import struct
import zlib

def make_png(width, height, pixel_data, filename):
    """
    Generate an uncompressed 16x16 PNG with RGBA pixels.
    pixel_data: list of (r, g, b, a) tuples of length width * height.
    """
    raw_scanlines = bytearray()
    for y in range(height):
        raw_scanlines.append(0)  # Filter type None
        for x in range(width):
            r, g, b, a = pixel_data[y * width + x]
            raw_scanlines.extend((r, g, b, a))

    compressed = zlib.compress(bytes(raw_scanlines), 9)

    def chunk(chunk_type, data):
        length = struct.pack(">I", len(data))
        crc = struct.pack(">I", zlib.crc32(chunk_type + data) & 0xffffffff)
        return length + chunk_type + data + crc

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png.extend(chunk(b"IHDR", ihdr_data))
    png.extend(chunk(b"IDAT", compressed))
    png.extend(chunk(b"IEND", b""))

    with open(filename, "wb") as f:
        f.write(png)
    print(f"Generated: {filename} ({len(png)} bytes)")

def generate_textures(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    W, H = 16, 16

    # 1. STEEL WALL: Dark industrial reinforced steel panel with rivets
    steel_pixels = []
    for y in range(H):
        for x in range(W):
            border = (x == 0 or x == W - 1 or y == 0 or y == H - 1)
            inner_border = (x == 1 or x == W - 2 or y == 1 or y == H - 2)
            rivet = ((x in (2, W - 3)) and (y in (2, W - 3)))
            if border:
                c = (35, 40, 48, 255)       # Dark seam
            elif inner_border:
                c = (85, 95, 110, 255)      # Bevel highlight
            elif rivet:
                c = (170, 180, 195, 255)    # Bright metallic rivet
            else:
                base = 65 + ((x ^ y * 3) % 9) - 4
                c = (base, base + 5, base + 12, 255) # Matte brushed steel
            steel_pixels.append(c)
    make_png(W, H, steel_pixels, os.path.join(out_dir, "steel_wall.png"))

    # 2. CRATE: Industrial metal shipping crate with diagonal reinforcement braces
    crate_pixels = []
    for y in range(H):
        for x in range(W):
            border = (x <= 1 or x >= W - 2 or y <= 1 or y >= H - 2)
            diag1 = abs(x - y) <= 1
            diag2 = abs((W - 1 - x) - y) <= 1
            if border:
                c = (140, 95, 35, 255)      # Heavy reinforced bronze/amber edge
            elif diag1 or diag2:
                c = (165, 115, 45, 255)     # Diagonal cross brace
            else:
                sh = 85 + ((x * 7 + y * 13) % 11) - 5
                c = (sh + 20, sh + 5, 25, 255) # Corrugated inner panel
            crate_pixels.append(c)
    make_png(W, H, crate_pixels, os.path.join(out_dir, "crate.png"))

    # 3. FLOOR PLATE: Industrial diamond plate / steel deck
    floor_pixels = []
    for y in range(H):
        for x in range(W):
            grid_border = (x == 0 or y == 0)
            pattern = ((x + y) % 4 == 0) or ((x - y) % 4 == 0 and x % 2 == 0)
            if grid_border:
                c = (22, 25, 30, 255)       # Grid gap
            elif pattern:
                c = (70, 78, 88, 255)       # Raised tread
            else:
                c = (42, 46, 54, 255)       # Plate base
            floor_pixels.append(c)
    make_png(W, H, floor_pixels, os.path.join(out_dir, "floor_plate.png"))

    # 4. EXIT ELEVATOR: Extraction platform with glowing green chevron / hazard stripes
    exit_pixels = []
    for y in range(H):
        for x in range(W):
            border = (x == 0 or x == W - 1 or y == 0 or y == H - 1)
            chevron = ((x + y) % 6 < 3)
            glow_center = (5 <= x <= 10 and 5 <= y <= 10)
            if border:
                c = (30, 50, 35, 255)
            elif glow_center:
                c = (46, 204, 113, 255)     # Glowing neon extraction green
            elif chevron:
                c = (39, 174, 96, 255)      # Industrial green stripe
            else:
                c = (20, 24, 28, 255)       # Dark metallic contrast
            exit_pixels.append(c)
    make_png(W, H, exit_pixels, os.path.join(out_dir, "exit_elevator.png"))

    # 5. AMMO BOX: Military green munitions crate with yellow stencil marker
    ammo_pixels = []
    for y in range(H):
        for x in range(W):
            border = (x == 0 or x == W - 1 or y == 0 or y == H - 1)
            stencil = (6 <= x <= 9 and 6 <= y <= 9)
            stripe = (y == 4 or y == 11)
            if border:
                c = (25, 35, 25, 255)
            elif stencil or stripe:
                c = (241, 196, 15, 255)     # Munitions hazard yellow
            else:
                c = (46, 75, 48, 255)       # Olive drab container
            ammo_pixels.append(c)
    make_png(W, H, ammo_pixels, os.path.join(out_dir, "ammo_box.png"))

    # 6. CORE WALL: VANGUARD core armored mainframe block with pulsing red conduits
    core_pixels = []
    for y in range(H):
        for x in range(W):
            conduit = (x in (4, 11) or y in (4, 11))
            core_node = (conduit and ((x == 4 and y == 4) or (x == 11 and y == 4) or (x == 4 and y == 11) or (x == 11 and y == 11)))
            if core_node:
                c = (255, 60, 40, 255)      # Core node bright emitter
            elif conduit:
                c = (200, 30, 30, 255)      # Glowing red data conduit
            else:
                base = 25 + ((x * 3 + y * 5) % 7)
                c = (base, base + 2, base + 6, 255) # Heavily armored dark alloy
            core_pixels.append(c)
    make_png(W, H, core_pixels, os.path.join(out_dir, "core_wall.png"))

if __name__ == "__main__":
    generate_textures("assets/textures")
