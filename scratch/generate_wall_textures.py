# Generates steel_wall.png, stone_wall.png, and stone_wall_alt.png
import os
import numpy as np
from PIL import Image

os.makedirs('assets/textures', exist_ok=True)
W, H = 64, 64

# Steel Wall
steel = np.zeros((H, W, 4), dtype=np.uint8)
np.random.seed(42)
for y in range(H):
    t = y / float(H)
    base_r = int(74 + 39 * (1.0 - t * 0.4))
    base_g = int(85 + 43 * (1.0 - t * 0.4))
    base_b = int(104 + 46 * (1.0 - t * 0.4))
    for x in range(W):
        grain = np.random.randint(-6, 7)
        steel[y, x] = [np.clip(base_r + grain, 0, 255), np.clip(base_g + grain, 0, 255), np.clip(base_b + grain, 0, 255), 255]

for _ in range(35):
    ry = np.random.randint(4, 52)
    streak_val = np.random.randint(-12, 14)
    length = np.random.randint(15, 60)
    start_x = np.random.randint(0, W - length + 1)
    for x in range(start_x, start_x + length):
        steel[ry, x, :3] = np.clip(steel[ry, x, :3].astype(int) + streak_val, 0, 255)

steel[0, :, :3] = [38, 44, 54]
steel[H - 1, :, :3] = [28, 32, 40]
steel[:, 0, :3] = [38, 44, 54]
steel[:, W - 1, :3] = [38, 44, 54]
steel[28, :, :3] = [40, 46, 56]
steel[29, :, :3] = [105, 118, 138]

for ty in range(1, 4):
    steel[ty, :, :3] = [45 + ty * 3, 52 + ty * 3, 64 + ty * 3]

for rx in [15, 46]:
    steel[4:54, rx, :3] = [50, 58, 70]
    steel[4:54, rx + 1, :3] = [100, 114, 134]
    steel[4:54, rx + 2, :3] = [125, 140, 162]
    for ry in [8, 20, 34, 46]:
        steel[ry, rx + 1, :3] = [210, 220, 235]
        steel[ry + 1, rx + 1, :3] = [30, 35, 42]

for by in range(52, 55):
    steel[by, :, :3] = [38, 44, 52]
steel[52, :, :3] = [95, 108, 126]

stripe_width = 5
for cy in range(55, 63):
    for cx in range(W):
        if ((cx + cy) // stripe_width) % 2 == 0:
            steel[cy, cx, :3] = [225 + (cx % 3) * 6, 185 + (cx % 3) * 5, 15]
        else:
            steel[cy, cx, :3] = [28 + (cx % 2) * 5, 28 + (cx % 2) * 5, 32 + (cx % 2) * 5]

Image.fromarray(steel).save('assets/textures/steel_wall.png')

# Stone Wall (bolted)
stone = np.zeros((H, W, 4), dtype=np.uint8)
for y in range(H):
    for x in range(W):
        noise = np.random.randint(-10, 11)
        base = 108 + noise
        stone[y, x] = [base - 5, base - 2, base + 2, 255]

stone[0, :, :3] = [55, 57, 60]
stone[H - 1, :, :3] = [45, 47, 50]
stone[:, 0, :3] = [55, 57, 60]
stone[:, W - 1, :3] = [45, 47, 50]
stone[1, 1:W-1, :3] = [140, 145, 150]
stone[1:H-1, 1, :3] = [135, 140, 145]
stone[H-2, 1:W-1, :3] = [65, 68, 72]
stone[1:H-1, W-2, :3] = [65, 68, 72]
stone[31, :, :3] = [50, 52, 56]
stone[32, :, :3] = [130, 134, 140]
stone[:, 31, :3] = [50, 52, 56]
stone[:, 32, :3] = [130, 134, 140]

bolt_positions = [
    (5, 5), (5, 26), (5, 37), (5, 58),
    (26, 5), (26, 26), (26, 37), (26, 58),
    (37, 5), (37, 26), (37, 37), (37, 58),
    (58, 5), (58, 26), (58, 37), (58, 58)
]
for bx, by in bolt_positions:
    stone[by, bx, :3] = [190, 195, 205]
    stone[by, bx+1, :3] = [160, 165, 175]
    stone[by+1, bx, :3] = [120, 125, 135]
    stone[by+1, bx+1, :3] = [40, 42, 45]
    for dx, dy in [(-1, 0), (0, -1), (2, 0), (0, 2), (-1, -1), (2, 2)]:
        if 0 <= bx+dx < W and 0 <= by+dy < H:
            stone[by+dy, bx+dx, :3] = [60, 62, 66]

Image.fromarray(stone).save('assets/textures/stone_wall.png')

# Stone Wall Alt (un-riveted)
stone_alt = np.zeros((H, W, 4), dtype=np.uint8)
np.random.seed(88)
for y in range(H):
    for x in range(W):
        noise = np.random.randint(-9, 10)
        base = 106 + noise
        stone_alt[y, x] = [base - 4, base - 1, base + 3, 255]

stone_alt[0, :, :3] = [55, 57, 60]
stone_alt[H - 1, :, :3] = [45, 47, 50]
stone_alt[:, 0, :3] = [55, 57, 60]
stone_alt[:, W - 1, :3] = [45, 47, 50]
stone_alt[1, 1:W-1, :3] = [138, 143, 148]
stone_alt[1:H-1, 1, :3] = [132, 138, 142]
stone_alt[H-2, 1:W-1, :3] = [65, 68, 72]
stone_alt[1:H-1, W-2, :3] = [65, 68, 72]
stone_alt[21, :, :3] = [52, 54, 58]
stone_alt[22, :, :3] = [128, 132, 138]
stone_alt[43, :, :3] = [52, 54, 58]
stone_alt[44, :, :3] = [128, 132, 138]
stone_alt[1:21, 32, :3] = [52, 54, 58]
stone_alt[1:21, 33, :3] = [128, 132, 138]
stone_alt[22:43, 16, :3] = [52, 54, 58]
stone_alt[22:43, 17, :3] = [128, 132, 138]
stone_alt[22:43, 48, :3] = [52, 54, 58]
stone_alt[22:43, 49, :3] = [128, 132, 138]
stone_alt[44:63, 32, :3] = [52, 54, 58]
stone_alt[44:63, 33, :3] = [128, 132, 138]

for _ in range(40):
    px = np.random.randint(2, W - 2)
    py = np.random.randint(2, H - 2)
    stone_alt[py, px, :3] = np.clip(stone_alt[py, px, :3].astype(int) - 18, 0, 255)

Image.fromarray(stone_alt).save('assets/textures/stone_wall_alt.png')
print('Script scratch/generate_wall_textures.py written successfully!')
