# scratch/find_exact_player.py
from PIL import Image

im = Image.open(r"C:\Users\HP\.gemini\antigravity\brain\379ff316-6967-455f-8e3f-4390eb1a06af\.user_uploaded\media_1795811915729_ddf093ca.jpg")
w, h = im.size

# Look for the minimap border in the top-right
# The minimap is anchored right, top margin is in HUD column
# Let's find the minimap border: cyan border #00e5ff
# Let's search from right edge inwards
border_xs = []
border_ys = []
for y in range(h):
    for x in range(w):
        r, g, b = im.getpixel((x, y))[:3]
        # Border color is #00e5ff -> r < 20, g > 220, b > 240
        if r < 30 and g > 220 and b > 240:
            border_xs.append(x)
            border_ys.append(y)

# Let's find the minimap rect
# Top-left has "FABRICATION FLOORS", bottom has "[M] MINIMIZE"
# The minimap border is a rectangle:
# Let's look for horizontal lines and vertical lines of the minimap box
print(f"Total bright cyan pixels: {len(border_xs)}")
# Find player chevron specifically:
# Player chevron has white outline (#ffffff) and cyan fill
# In the screenshot, let's find the chevron vertices:
chev_pts = []
for y in range(30, 200):
    for x in range(700, 850):
        r, g, b = im.getpixel((x, y))[:3]
        if r < 30 and g > 220 and b > 240:
            chev_pts.append((x, y))

if chev_pts:
    min_x, max_x = min(p[0] for p in chev_pts), max(p[0] for p in chev_pts)
    min_y, max_y = min(p[1] for p in chev_pts), max(p[1] for p in chev_pts)
    print(f"Chevron cluster: x [{min_x}..{max_x}], y [{min_y}..{max_y}]")

# Let's find the top-left of the mapCanvas (inside the minimap):
# Let's find where the exit elevator orange circle is:
# Orange circle is around (23, 2) in map coordinates!
orange_pts = []
for y in range(20, 200):
    for x in range(700, 1000):
        r, g, b = im.getpixel((x, y))[:3]
        if r > 220 and 120 < g < 180 and b < 50: # orange
            orange_pts.append((x, y))

if orange_pts:
    ox = sum(p[0] for p in orange_pts) / len(orange_pts)
    oy = sum(p[1] for p in orange_pts) / len(orange_pts)
    print(f"Orange exit circle at screen ({ox:.1f}, {oy:.1f})")
    # Exit circle is at (col=23.5, row=2.5) in 48x48 grid!
    # Therefore, tileW = ? tileH = ?

# Let's find the minimap rect corners
# The minimap rect has border.color: "#00e5ff" (or dark background)
# Let's find the left edge and right edge of the minimap box:
for x in range(700, 750):
    # check vertical line
    cnt = sum(1 for y in range(40, 300) if im.getpixel((x, y))[2] > 180 and im.getpixel((x, y))[0] < 50)
    if cnt > 100:
        print(f"Minimap left border at x={x}")
        break

for x in range(1010, 950, -1):
    cnt = sum(1 for y in range(40, 300) if im.getpixel((x, y))[2] > 180 and im.getpixel((x, y))[0] < 50)
    if cnt > 100:
        print(f"Minimap right border at x={x}")
        break

for y in range(20, 60):
    cnt = sum(1 for x in range(750, 980) if im.getpixel((x, y))[2] > 180 and im.getpixel((x, y))[0] < 50)
    if cnt > 100:
        print(f"Minimap top border at y={y}")
        break

for y in range(350, 250, -1):
    cnt = sum(1 for x in range(750, 980) if im.getpixel((x, y))[2] > 180 and im.getpixel((x, y))[0] < 50)
    if cnt > 100:
        print(f"Minimap bottom border at y={y}")
        break

blue_pts = []
for y in range(40, 200):
    for x in range(740, 820):
        r, g, b = im.getpixel((x, y))[:3]
        if 40 < r < 80 and 100 < g < 160 and b > 180: # blue circle
            blue_pts.append((x, y))

if blue_pts:
    bx = sum(p[0] for p in blue_pts) / len(blue_pts)
    by = sum(p[1] for p in blue_pts) / len(blue_pts)
    print(f"Blue Key 3 circle at screen ({bx:.1f}, {by:.1f})")
    # Key 3 circle is at col=9.5, row=11.5!
    # Let's compare Exit circle (23.5, 2.5) -> (860.2, 51.3)
    # and Key 3 circle (9.5, 11.5) -> (bx, by)
    d_col = 23.5 - 9.5 # 14 cols
    d_row = 11.5 - 2.5 # 9 rows
    scale_x = (860.2 - bx) / d_col
    scale_y = (by - 51.3) / d_row
    print(f"Scale: {scale_x:.2f} px/col, {scale_y:.2f} px/row")
    
    # Now find player (col, row):
    p_col = 23.5 - (860.2 - 773.5) / scale_x
    p_row = 2.5 + (73.0 - 51.3) / scale_y
    print(f"PLAYER IS AT COL={p_col:.1f}, ROW={p_row:.1f}!!")
