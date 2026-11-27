# scratch/find_arrow.py
from PIL import Image

im = Image.open("scratch/minimap_crop.png")
w, h = im.size
print(f"Minimap crop size: {w}x{h}")

# Find cyan pixels (#00e5ff or similar high blue/green, low red)
cyan_pts = []
for y in range(h):
    for x in range(w):
        r, g, b = im.getpixel((x, y))[:3]
        if r < 80 and g > 180 and b > 200:
            cyan_pts.append((x, y))

if cyan_pts:
    min_x = min(p[0] for p in cyan_pts)
    max_x = max(p[0] for p in cyan_pts)
    min_y = min(p[1] for p in cyan_pts)
    max_y = max(p[1] for p in cyan_pts)
    center_x = (min_x + max_x) // 2
    center_y = (min_y + max_y) // 2
    print(f"Cyan arrow found at crop x={center_x}, y={center_y} (box {min_x}..{max_x}, {min_y}..{max_y})")
    print(f"Relative to crop: x={center_x/w:.2f}, y={center_y/h:.2f}")
else:
    print("Cyan arrow not found!")
