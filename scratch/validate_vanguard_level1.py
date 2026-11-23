
import collections

# Tile codes
TILE_EMPTY = 0
TILE_WALL = 1
TILE_CRATE = 2
TILE_SPAWN = 3
TILE_EXIT = 4
TILE_AMMO = 5
TILE_DOOR = 10
TILE_POCKET = 12

def create_version_1():
    # 48x48
    H, W = 48, 48
    m = [[TILE_WALL for _ in range(W)] for _ in range(H)]
    
    def fill_rect(r1, r2, c1, c2, val=TILE_EMPTY):
        for r in range(r1, r2 + 1):
            for c in range(c1, c2 + 1):
                m[r][c] = val

    # 1. Central Hub: (20..27, 20..27)
    fill_rect(20, 27, 20, 27)

    # 2. South Checkpoint & Spawn: (38..45, 21..26)
    fill_rect(38, 45, 21, 26)
    m[42][23] = TILE_SPAWN

    # South Arterial Corridor: (28..37, 22..24) - width 3
    fill_rect(28, 37, 22, 24)

    # 3. North Freight Elevator (Exit):
    # North Corridor: (13..19, 23..25) - width 3
    fill_rect(13, 19, 23, 25)
    # Extraction Chamber: (4..11, 21..27)
    fill_rect(4, 11, 21, 27)
    m[6][24] = TILE_EXIT
    # Exit Bulkhead Door D1-EXIT at row 12, col 24 (Pocket at 12, 23)
    m[12][24] = TILE_DOOR
    m[12][23] = TILE_POCKET

    # 4. East Wing: Electrical & Gas Control
    # East Arterial Corridor: (23..25, 28..32) - width 3
    fill_rect(23, 25, 28, 32)
    # Electrical Control Room: (7..18, 32..39)
    fill_rect(7, 18, 32, 39)
    # Link Hub East to Electrical: (19..22, 32..34)
    fill_rect(19, 22, 32, 34)
    # Electrical Vault: (7..15, 41..46)
    fill_rect(7, 15, 41, 46)
    # Vault Door D1-ELEC at row 11, col 40 (Pocket at 10, 40)
    m[11][40] = TILE_DOOR
    m[10][40] = TILE_POCKET

    # Gas Control & Repair Room: (27..35, 32..42)
    fill_rect(27, 35, 32, 42)
    # Link Hub to Gas Room: (26..28, 28..32)
    fill_rect(26, 28, 28, 32)

    # 5. West Wing: Administration & Password Vault
    # West Arterial Corridor: (23..25, 15..19) - width 3
    fill_rect(23, 25, 15, 19)
    # Records & Clue Hall: (26..37, 7..17)
    fill_rect(26, 38, 7, 17)
    # Link Hub to Admin: (24..26, 17..20)
    fill_rect(24, 26, 17, 20)
    # Password Vault: (40..46, 7..17)
    fill_rect(40, 46, 7, 17)
    # Password Vault Door D1-PASS at row 39, col 12 (Pocket at 39, 11)
    m[39][12] = TILE_DOOR
    m[39][11] = TILE_POCKET

    # Warehouse Logistics Room (North-West): (7..18, 7..18)
    fill_rect(7, 18, 7, 18)
    # Corridor linking Hub to Warehouse: (19..22, 14..16)
    fill_rect(19, 22, 14, 16)
    # Corridor linking Warehouse to North Approach Corridor (outside exit door): (14..16, 18..22)
    fill_rect(14, 16, 18, 22)

    return m

def create_version_2():
    # 80x80 full facility
    H, W = 80, 80
    m = [[TILE_WALL for _ in range(W)] for _ in range(H)]
    
    def fill_rect(r1, r2, c1, c2, val=TILE_EMPTY):
        for r in range(r1, r2 + 1):
            for c in range(c1, c2 + 1):
                m[r][c] = val

    # Central Manufacturing Hub: (35..45, 35..45)
    fill_rect(35, 45, 35, 45)

    # South Security Checkpoint & Spawn: (64..73, 36..44)
    fill_rect(64, 73, 36, 44)
    m[68][39] = TILE_SPAWN # Spawn

    # South Arterial Corridor: (46..63, 39..41) - width 3
    fill_rect(46, 63, 39, 41)

    # North Freight Elevator (Exit):
    # North Arterial Corridor: (17..34, 39..41) - width 3
    fill_rect(17, 34, 39, 41)
    # Extraction Chamber: (4..15, 35..45)
    fill_rect(4, 15, 35, 45)
    m[7][40] = TILE_EXIT
    # Extraction Bulkhead Door D1-EXIT at row 16, col 40 (Pocket at 16, 39)
    m[16][40] = TILE_DOOR
    m[16][39] = TILE_POCKET

    # East Arterial Corridor: (39..41, 46..61) - width 3
    fill_rect(39, 41, 46, 61)

    # Electrical Control & Power Substation (North-East):
    # Generator & Power Substation: (6..16, 54..68)
    fill_rect(6, 16, 54, 68)
    # Electrical Control Room: (17..24, 56..64)
    fill_rect(17, 24, 56, 64)
    # Corridor linking East Arterial to Electrical: (25..38, 59..61) - width 3
    fill_rect(25, 38, 59, 61)
    # Electrical Vault: (5..15, 70..77)
    fill_rect(5, 15, 70, 77)
    # Vault Door D1-ELEC at row 10, col 69 (Pocket at 9, 69)
    m[10][69] = TILE_DOOR
    m[9][69] = TILE_POCKET

    # Gas Control Room & Maintenance Workshop (South-East):
    # Maintenance Workshop: (60..74, 54..74)
    fill_rect(60, 74, 54, 74)
    # Gas Control Substation: (48..58, 56..66)
    fill_rect(48, 58, 56, 66)
    # Corridor linking East Arterial to Maintenance across Gas Substation: (42..60, 59..61) - width 3
    fill_rect(42, 60, 59, 61)

    # West Arterial Corridor: (39..41, 19..34) - width 3
    fill_rect(39, 41, 19, 34)

    # Cargo Logistics & Shipping Bay (North-West):
    # Main Cargo Bay: (6..22, 6..24)
    fill_rect(6, 22, 6, 24)
    # Logistics Offices: (6..14, 25..33)
    fill_rect(6, 14, 25, 33)
    # Corridor linking West Arterial to Cargo: (23..38, 17..19) - width 3
    fill_rect(23, 38, 17, 19)
    # Cargo to North Arterial Corridor (outside exit door): (18..20, 34..38)
    fill_rect(18, 20, 34, 38)

    # Administration Sector & Password Vault (South-West):
    # Reception & Executive Suites: (54..68, 6..22)
    fill_rect(54, 68, 6, 22)
    # Archive Records Room: (54..68, 23..32)
    fill_rect(54, 68, 23, 32)
    # Corridor linking West Arterial to Admin: (42..53, 17..19) - width 3
    fill_rect(42, 53, 17, 19)
    # Password Vault: (70..77, 10..24)
    fill_rect(70, 77, 10, 24)
    # Password Vault Door D1-PASS at row 69, col 16 (Pocket at 69, 15)
    m[69][16] = TILE_DOOR
    m[69][15] = TILE_POCKET

    return m

def validate_bfs(m, H, W, spawn, doors, keys, exit_tile, clues, puzzle_pos, gas_stations):
    # multi-phase BFS
    def run_bfs(open_doors):
        visited = [[False for _ in range(W)] for _ in range(H)]
        q = collections.deque()
        sr, sc = spawn
        visited[sr][sc] = True
        q.append((sr, sc))
        
        while q:
            r, c = q.popleft()
            for dr, dc in [(-1,0), (1,0), (0,-1), (0,1)]:
                nr, nc = r + dr, c + dc
                if 0 <= nr < H and 0 <= nc < W and not visited[nr][nc]:
                    tile = m[nr][nc]
                    if tile in [TILE_WALL, TILE_CRATE, TILE_POCKET]:
                        continue
                    if tile == TILE_DOOR:
                        if (nr, nc) not in open_doors:
                            continue
                    visited[nr][nc] = True
                    q.append((nr, nc))
        return visited

    # Phase 1: All doors closed
    v1 = run_bfs(set())
    # Verify reachable in Phase 1:
    assert v1[puzzle_pos[0]][puzzle_pos[1]], 'Puzzle not reachable in Phase 1'
    for c in clues:
        assert v1[c[0]][c[1]], f'Clue {c} not reachable in Phase 1'
    for g in gas_stations:
        assert v1[g[0]][g[1]], f'Gas station {g} not reachable in Phase 1'
    # Verify vaults NOT reachable in Phase 1
    for k in keys:
        assert not v1[k[0]][k[1]], f'Key {k} leaked into Phase 1!'
    assert not v1[exit_tile[0]][exit_tile[1]], 'Exit leaked into Phase 1!'

    # Phase 2: Electrical door open
    elec_door = doors['ELEC']
    v2 = run_bfs({elec_door})
    # Check electrical vault keys
    elec_keys = keys[:len(keys)//2] if len(keys) == 4 else [keys[0]]
    for k in elec_keys:
        assert v2[k[0]][k[1]], f'Elec key {k} not reachable in Phase 2'
    # Password keys still locked
    pass_keys = keys[len(keys)//2:] if len(keys) == 4 else [keys[1]]
    for k in pass_keys:
        assert not v2[k[0]][k[1]], f'Pass key {k} reachable in Phase 2!'
    assert not v2[exit_tile[0]][exit_tile[1]], 'Exit reachable in Phase 2!'

    # Phase 3: Both vault doors open
    pass_door = doors['PASS']
    v3 = run_bfs({elec_door, pass_door})
    for k in keys:
        assert v3[k[0]][k[1]], f'Key {k} not reachable in Phase 3'
    assert not v3[exit_tile[0]][exit_tile[1]], 'Exit reachable in Phase 3!'

    # Phase 4: All doors open
    exit_door = doors['EXIT']
    v4 = run_bfs({elec_door, pass_door, exit_door})
    assert v4[exit_tile[0]][exit_tile[1]], 'Exit not reachable in Phase 4!'

    print('BFS Validation PASSED with 100% integrity!')

print('Testing Version 1...')
m1 = create_version_1()
validate_bfs(m1, 48, 48, spawn=(42, 23),
             doors={'ELEC': (11, 40), 'PASS': (39, 12), 'EXIT': (12, 24)},
             keys=[(11, 44), (43, 12)],
             exit_tile=(6, 24),
             clues=[(31, 8), (35, 12)],
             puzzle_pos=(9, 35),
             gas_stations=[(31, 38), (16, 24)])

print('Testing Version 2...')
m2 = create_version_2()
validate_bfs(m2, 80, 80, spawn=(68, 39),
             doors={'ELEC': (10, 69), 'PASS': (69, 16), 'EXIT': (16, 40)},
             keys=[(8, 74), (12, 74), (74, 13), (74, 18)],
             exit_tile=(7, 40),
             clues=[(57, 10), (64, 8), (67, 20), (56, 24)],
             puzzle_pos=(10, 62),
             gas_stations=[(66, 62), (10, 60), (14, 14)])

print('All Variant BFS Validations Succeeded!')
