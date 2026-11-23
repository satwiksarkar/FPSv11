
# Map Design and Validation for Project VANGUARD Level 1 Variants
# Tile codes:
# 0: Empty Floor, 1: Wall, 2: Crate, 3: Spawn, 4: Exit, 5: Ammo, 10: Door, 12: DoorPocket

def create_v1_map():
    # 48x48 compact facility
    SIZE = 48
    grid = [[1 for _ in range(SIZE)] for _ in range(SIZE)]
    
    # Helper to carve room/corridor
    def carve(r1, r2, c1, c2, tile=0):
        for r in range(r1, r2 + 1):
            for c in range(c1, c2 + 1):
                grid[r][c] = tile
                
    # 1. Central Hub: Rows 20..27, Cols 20..27
    carve(20, 27, 20, 27, 0)
    
    # 2. South Checkpoint & Spawn: Rows 38..45, Cols 21..26
    carve(38, 45, 21, 26, 0)
    grid[42][23] = 3 # PlayerSpawn
    
    # Corridor South to Hub: Rows 28..37, Cols 22..24 (width 3)
    carve(28, 37, 22, 24, 0)
    
    # 3. North Extraction Approach & Chamber:
    # Corridor North from Hub: Rows 13..19, Cols 22..24 (width 3)
    carve(13, 19, 22, 24, 0)
    # Extraction Chamber: Rows 4..11, Cols 20..27
    carve(4, 11, 20, 27, 0)
    grid[6][24] = 4 # Level1Exit platform
    # Extraction Door D1-EXIT at row 12, col 23..24 (Door at 12, 24, Pocket at 12, 23)
    grid[12][24] = 10 # Door
    grid[12][23] = 12 # DoorPocket
    
    # 4. East Wing: Electrical & Power Substation
    # Corridor East from Hub: Rows 23..25, Cols 28..32 (width 3)
    carve(23, 25, 28, 32, 0)
    # Electrical Control Room: Rows 6..18, Cols 31..39
    carve(6, 18, 31, 39, 0)
    # Corridor linking Hub East to Electrical Room: Rows 19..22, Cols 31..33
    carve(19, 22, 31, 33, 0)
    # Electrical Vault: Rows 7..15, Cols 41..46
    carve(7, 15, 41, 46, 0)
    # Vault Door D1-ELEC at Row 11, Col 40 (Axis 90.0: passage along X, wall along Z)
    grid[11][40] = 10
    grid[10][40] = 12
    # Key 1 at (11, 44)
    # Electrical puzzle console at (9, 35), Fuse pickup at (14, 35)
    
    # Gas Repair Station East: Rows 30..36, Cols 34..42
    carve(30, 36, 34, 42, 0)
    # Corridor South-East from Hub: Rows 25..29, Cols 28..36
    carve(25, 29, 28, 36, 0)
    
    # 5. West Wing: Administration & Password Vault
    # Corridor West from Hub: Rows 23..25, Cols 15..19 (width 3)
    carve(23, 25, 15, 19, 0)
    # Records & Admin Hall: Rows 28..37, Cols 6..18
    carve(28, 37, 6, 18, 0)
    # Linking corridor Hub to Admin: Rows 26..29, Cols 13..15
    carve(26, 29, 13, 15, 0)
    # Password Clue 1 at (31, 8), Clue 2 at (35, 12)
    # Password Vault: Rows 40..46, Cols 7..17
    carve(40, 46, 7, 17, 0)
    # Vault Door D1-PASS at Row 39, Col 12 (Axis 0.0: passage along Z, wall along X)
    grid[39][12] = 10
    grid[39][11] = 12
    # Key 2 at (43, 12)
    
    # North-West Logistics Room: Rows 8..18, Cols 6..17
    carve(8, 18, 6, 17, 0)
    # Corridor West to Logistics: Rows 19..22, Cols 13..15
    carve(19, 22, 13, 15, 0)

    return grid

print('Script written successfully')
