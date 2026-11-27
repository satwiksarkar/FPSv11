# scratch/crop_minimap.py
from PIL import Image

im = Image.open(r"C:\Users\HP\.gemini\antigravity\brain\379ff316-6967-455f-8e3f-4390eb1a06af\.user_uploaded\media_1795811915729_ddf093ca.jpg")
w, h = im.size
print(f"Image size: {w}x{h}")

# Minimap is in top-right
# Top right corner roughly x: 700..1024, y: 0..400
minimap = im.crop((int(w * 0.70), int(h * 0.05), int(w * 0.98), int(h * 0.65)))
minimap.save("scratch/minimap_crop.png")
print("Saved scratch/minimap_crop.png")
