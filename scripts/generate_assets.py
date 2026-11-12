import os
import struct
import zlib
import wave
import math
import random

# Ensure output directories exist
os.makedirs("assets/textures", exist_ok=True)
os.makedirs("assets/sounds", exist_ok=True)
os.makedirs("assets/models", exist_ok=True)

# ==============================================================================
# 1. PURE PYTHON 16x16 PIXEL-ART PNG GENERATOR
# ==============================================================================
def write_png(filename, width, height, pixels):
    """Writes an uncompressed RGBA PNG image."""
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0)  # Filter type 0 (None)
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw_bytes.extend([r, g, b, a])
    
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    ihdr = chunk(b"IHDR", ihdr_data)
    idat = chunk(b"IDAT", zlib.compress(bytes(raw_bytes), 9))
    iend = chunk(b"IEND", b"")

    with open(filename, "wb") as f:
        f.write(signature + ihdr + idat + iend)
    print(f"Generated texture: {filename}")

# Seed random for deterministic, reproducible retro pixel art
random.seed(42)

# --- 1. Sand (Warm desert dunes) ---
pixels_sand = []
for y in range(16):
    for x in range(16):
        v = random.choice([0, 5, -5, 10, -8])
        r = min(255, max(0, 222 + v))
        g = min(255, max(0, 193 + v))
        b = min(255, max(0, 126 + v))
        pixels_sand.append((r, g, b, 255))
write_png("assets/textures/sand.png", 16, 16, pixels_sand)

# --- 2. Sandstone (Carved layered desert stone) ---
pixels_sandstone = []
for y in range(16):
    is_seam = (y % 4 == 0)
    for x in range(16):
        v = random.randint(-4, 4)
        if is_seam:
            pixels_sandstone.append((180, 145, 80, 255))
        else:
            pixels_sandstone.append((200 + v, 165 + v, 100 + v, 255))
write_png("assets/textures/sandstone.png", 16, 16, pixels_sandstone)

# --- 3. Grass (Vibrant top meadow) ---
pixels_grass = []
for y in range(16):
    for x in range(16):
        v = random.choice([-15, -8, 0, 8, 15])
        r = min(255, max(0, 76 + v // 2))
        g = min(255, max(0, 166 + v))
        b = min(255, max(0, 56 + v // 2))
        pixels_grass.append((r, g, b, 255))
write_png("assets/textures/grass.png", 16, 16, pixels_grass)

# --- 4. Dirt (Rich earthy soil) ---
pixels_dirt = []
for y in range(16):
    for x in range(16):
        v = random.choice([-12, -6, 0, 6, 12])
        r = min(255, max(0, 134 + v))
        g = min(255, max(0, 88 + v))
        b = min(255, max(0, 41 + v))
        pixels_dirt.append((r, g, b, 255))
write_png("assets/textures/dirt.png", 16, 16, pixels_dirt)

# --- 5. Wood (Oak timber planks) ---
pixels_wood = []
for y in range(16):
    is_plank_border = (y % 4 == 0)
    for x in range(16):
        grain = ((x * 3 + y * 7) % 5) * 3
        if is_plank_border:
            pixels_wood.append((90, 55, 25, 255))
        else:
            pixels_wood.append((140 + grain, 90 + grain, 45 + grain, 255))
write_png("assets/textures/wood.png", 16, 16, pixels_wood)

# --- 6. Leaves (Bushy tree foliage) ---
pixels_leaves = []
for y in range(16):
    for x in range(16):
        v = random.choice([-20, -10, 0, 10, 20])
        r = min(255, max(0, 45 + v // 2))
        g = min(255, max(0, 122 + v))
        b = min(255, max(0, 45 + v // 2))
        pixels_leaves.append((r, g, b, 255))
write_png("assets/textures/leaves.png", 16, 16, pixels_leaves)

# --- 7. Snow (Powder tundra & frost) ---
pixels_snow = []
for y in range(16):
    for x in range(16):
        v = random.choice([-8, -4, 0, 4, 8])
        r = min(255, max(0, 237 + v))
        g = min(255, max(0, 246 + v))
        b = min(255, max(0, 250 + v))
        pixels_snow.append((r, g, b, 255))
write_png("assets/textures/snow.png", 16, 16, pixels_snow)

# --- 8. Ice (Translucent crystal ice) ---
pixels_ice = []
for y in range(16):
    for x in range(16):
        v = ((x ^ y) % 3) * 15
        r = 111 + v
        g = 194 + v
        b = 232
        pixels_ice.append((r, g, b, 230))
write_png("assets/textures/ice.png", 16, 16, pixels_ice)

# --- 9. Stone (Cobblestone masonry) ---
pixels_stone = []
for y in range(16):
    for x in range(16):
        is_mortar = (x % 8 == 0) or (y % 8 == 0) or (y % 4 == 0 and x % 4 == 0)
        v = random.choice([-15, -8, 0, 8, 15])
        if is_mortar:
            pixels_stone.append((90, 95, 105, 255))
        else:
            g = min(255, max(0, 148 + v))
            pixels_stone.append((g, g + 6, g + 18, 255))
write_png("assets/textures/stone.png", 16, 16, pixels_stone)

# --- 10. Door (Reinforced oak door with iron hinges) ---
pixels_door = []
for y in range(16):
    for x in range(16):
        is_iron_band = (y in [3, 4, 11, 12])
        is_bolt = (y in [7, 8] and x in [7, 8])
        is_seam = (x == 0 or x == 15 or y == 0 or y == 15 or x == 8)
        if is_bolt:
            pixels_door.append((255, 204, 0, 255))  # Gold/brass lock
        elif is_iron_band:
            pixels_door.append((40, 45, 52, 255))   # Dark iron hinge
        elif is_seam:
            pixels_door.append((70, 38, 18, 255))   # Plank edge
        else:
            grain = (x * 7 + y * 13) % 15
            pixels_door.append((120 + grain, 70 + grain, 30 + grain, 255))
write_png("assets/textures/door.png", 16, 16, pixels_door)


# ==============================================================================
# 2. PURE PYTHON PROCEDURAL 16-BIT 44.1kHz PCM WAV AUDIO GENERATOR
# ==============================================================================
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    """Writes a 16-bit mono 44.1kHz WAV file."""
    with wave.open(filename, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        # Convert float samples [-1.0, 1.0] to 16-bit signed integers
        raw_frames = bytearray()
        for s in samples:
            s_clamped = max(-1.0, min(1.0, s))
            val = int(s_clamped * 32767.0)
            raw_frames.extend(struct.pack("<h", val))
        wf.writeframes(raw_frames)
    print(f"Generated audio: {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

# --- 1. Gunshot (Sharp explosive crack + decaying resonance) ---
dur = 0.45
num_samples = int(dur * SAMPLE_RATE)
samples_gunshot = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    # Envelope: instantaneous attack, fast exponential decay
    env = math.exp(-t * 18.0)
    # White noise + low-frequency thump (120 Hz falling to 40 Hz)
    noise = (random.random() * 2.0 - 1.0)
    freq = 140.0 * math.exp(-t * 25.0)
    thump = math.sin(2.0 * math.pi * freq * t)
    s = (noise * 0.65 + thump * 0.35) * env
    samples_gunshot.append(s)
write_wav("assets/sounds/gunshot.wav", samples_gunshot)

# --- 2. Reload (Bolt-action mechanical click-slide) ---
dur = 0.4
num_samples = int(dur * SAMPLE_RATE)
samples_reload = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    # Two distinct mechanical clicks at t=0.05 and t=0.22
    s = 0.0
    for click_t in [0.05, 0.22]:
        dt = t - click_t
        if 0 <= dt < 0.08:
            env = math.exp(-dt * 60.0)
            metal = math.sin(2.0 * math.pi * 1800.0 * dt) + 0.5 * math.sin(2.0 * math.pi * 2400.0 * dt)
            s += metal * env * 0.7
    samples_reload.append(s)
write_wav("assets/sounds/reload.wav", samples_reload)

# --- 3. Door (Heavy stone/timber grinding slide) ---
dur = 0.6
num_samples = int(dur * SAMPLE_RATE)
samples_door = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    env = math.sin(math.pi * (t / dur))  # Rise and fall
    rumble = math.sin(2.0 * math.pi * 65.0 * t) + 0.4 * math.sin(2.0 * math.pi * 110.0 * t)
    noise = (random.random() * 2.0 - 1.0) * 0.35
    s = (rumble + noise) * env * 0.6
    samples_door.append(s)
write_wav("assets/sounds/door.wav", samples_door)

# --- 4. Enemy Hit (Punchy meat/block impact thud) ---
dur = 0.22
num_samples = int(dur * SAMPLE_RATE)
samples_hit = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    env = math.exp(-t * 22.0)
    freq = 280.0 * math.exp(-t * 30.0)
    thud = math.sin(2.0 * math.pi * freq * t)
    click = (random.random() * 2.0 - 1.0) * math.exp(-t * 70.0)
    s = (thud * 0.7 + click * 0.3) * env
    samples_hit.append(s)
write_wav("assets/sounds/enemy_hit.wav", samples_hit)

# --- 5. Death (Retro descending arcade tone + collapse) ---
dur = 0.5
num_samples = int(dur * SAMPLE_RATE)
samples_death = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    env = 1.0 - (t / dur)
    # Descending pitch from 400 Hz down to 60 Hz
    freq = 400.0 - 340.0 * (t / dur)
    tone = math.sin(2.0 * math.pi * freq * t)
    noise = (random.random() * 2.0 - 1.0) * (t / dur) * 0.4
    s = (tone * 0.6 + noise) * env * 0.7
    samples_death.append(s)
write_wav("assets/sounds/death.wav", samples_death)

# --- 6. Ambient Desert (Whistling warm wind loop) ---
dur = 2.0
num_samples = int(dur * SAMPLE_RATE)
samples_desert = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    # Subtle amplitude modulation
    mod = 0.6 + 0.4 * math.sin(2.0 * math.pi * 0.5 * t)
    wind = math.sin(2.0 * math.pi * 140.0 * t) * 0.25 + math.sin(2.0 * math.pi * 210.0 * t) * 0.15
    noise = (random.random() * 2.0 - 1.0) * 0.15
    s = (wind + noise) * mod * 0.35
    samples_desert.append(s)
write_wav("assets/sounds/ambient_desert.wav", samples_desert)

# --- 7. Ambient Forest (Gentle breeze & chirp loop) ---
dur = 2.0
num_samples = int(dur * SAMPLE_RATE)
samples_forest = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    breeze = math.sin(2.0 * math.pi * 95.0 * t) * 0.15 + (random.random() * 2.0 - 1.0) * 0.08
    # Occasional high bird chirp at t around 0.8s
    chirp = 0.0
    if 0.8 <= t < 0.95:
        ct = t - 0.8
        chirp = math.sin(2.0 * math.pi * (2600.0 + 800.0 * math.sin(ct * 40.0)) * ct) * math.sin(math.pi * (ct / 0.15)) * 0.25
    s = (breeze + chirp) * 0.4
    samples_forest.append(s)
write_wav("assets/sounds/ambient_forest.wav", samples_forest)

# --- 8. Ambient Snow (Howling cold blizzard loop) ---
dur = 2.0
num_samples = int(dur * SAMPLE_RATE)
samples_snow = []
for i in range(num_samples):
    t = i / SAMPLE_RATE
    # Two slow-beating low frequencies creating a hollow chill
    drone = (math.sin(2.0 * math.pi * 85.0 * t) + math.sin(2.0 * math.pi * 88.0 * t)) * 0.2
    whisper = (random.random() * 2.0 - 1.0) * 0.2
    mod = 0.7 + 0.3 * math.sin(2.0 * math.pi * 0.8 * t)
    s = (drone + whisper) * mod * 0.45
    samples_snow.append(s)
write_wav("assets/sounds/ambient_snow.wav", samples_snow)

print("\nAll Stage 9 Assets successfully created!")
