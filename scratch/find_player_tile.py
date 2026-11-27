# scratch/find_player_tile.py
from PIL import Image

im = Image.open(r"C:\Users\HP\.gemini\antigravity\brain\379ff316-6967-455f-8e3f-4390eb1a06af\.user_uploaded\media_1795811915729_ddf093ca.jpg")
w, h = im.size

# Look at the minimap area
# In the screenshot (1024x510), the minimap box is roughly x in [720, 990], y in [35, 310]
# Let's find the exact minimap background rectangle (it has a cyan border or blue grid)
# Let's find the player triangle: it has pure cyan interior #00e5ff and white border #ffffff
player_pts = []
for y in range(20, 300):
    for x in range(700, 1000):
        r, g, b = im.getpixel((x, y))[:3]
        if r < 50 and g > 200 and b > 230: # cyan
            player_pts.append((x, y))

if player_pts:
    min_x = min(p[0] for p in player_pts)
    max_x = max(p[0] for p in player_pts)
    min_y = min(p[1] for p in player_pts)
    max_y = max(p[1] for p in player_pts)
    cx = (min_x + max_x) / 2
    cy = (min_y + max_y) / 2
    print(f"Player chevron screen pos: ({cx:.1f}, {cy:.1f}), bounds: X [{min_x}..{max_x}], Y [{min_y}..{max_y}]")

# Let's also find the bounds of the minimap itself:
# Look for the top-left and bottom-right of the minimap box
# The header says "FABRICATION FLOORS" in the minimap top-left
# Let's inspect rows and cols
print(f"Image width={w}, height={h}")
