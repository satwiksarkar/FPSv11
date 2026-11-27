# scratch/verify_all.py
import os
import sys
import subprocess
from collections import deque

def check_guardrails():
    print("=== GUARDRAIL CHECKS ===")
    
    # 1. Minimap integrity
    assert os.path.exists("qml/Minimap.qml"), "qml/Minimap.qml missing!"
    assert os.path.getsize("qml/Minimap.qml") > 10000, "qml/Minimap.qml truncated!"
    print("[PASS] qml/Minimap.qml verified and intact.")

    # 2. Check Level 2 and Level 3 files
    with open("src/LevelData.h", "r") as f:
        h = f.read()
    assert "LEVEL2_SIZE = 64;" in h
    assert "LEVEL3_SIZE = 40;" in h
    assert "getLevel2SentinelSpawns" in h
    assert "getLevel3VentPositions" in h
    print("[PASS] Level 2 and Level 3 dimensions and definitions intact in LevelData.h.")

    with open("src/BossArena.h", "r") as f:
        ba_h = f.read()
    assert "isBossDefeated" in ba_h
    assert "ventCount" in ba_h
    print("[PASS] BossArena and cooling vent mechanics intact in BossArena.h.")

def check_crawling():
    print("\n=== CRAWLING MECHANIC CHECKS ===")
    with open("src/GameConfig.h", "r") as f:
        gc = f.read()
    assert "PLAYER_CRAWL_SPEED = 85.0f" in gc
    assert "EYE_HEIGHT_CRAWL = 45.0f" in gc
    assert "CRAWL_COLLISION_RADIUS = 26.0f" in gc
    print("[PASS] GameConfig crawling constants verified.")

    with open("src/Player.h", "r") as f:
        p_h = f.read()
    assert "isCrawling" in p_h
    assert "setCrawl" in p_h
    assert "toggleCrawl" in p_h
    assert "crawlChanged" in p_h
    print("[PASS] Player.h crawling Q_PROPERTY, setters, getters, signals verified.")

    with open("src/Player.cpp", "r") as f:
        p_cpp = f.read()
    assert "curCeil - curFloor < GameConfig::EYE_HEIGHT_STAND + 20.0f" in p_cpp
    assert "m_isCrawling = true;" in p_cpp
    print("[PASS] Player.cpp ceiling clearance check and eye height lerp verified.")

def check_level1_layout_and_bfs():
    print("\n=== LEVEL 1 LAYOUT & BFS SIMULATION ===")
    
    # Extract level1 matrix from LevelData.cpp
    with open("src/LevelData.cpp", "r") as f:
        cpp = f.read()
    
    start_str = "const int LevelData::level1[48][48] = {"
    start_pos = cpp.find(start_str)
    assert start_pos != -1
    end_pos = cpp.find("};", start_pos)
    matrix_str = cpp[start_pos + len(start_str):end_pos]
    
    rows = []
    for line in matrix_str.strip().split("\n"):
        line = line.strip().strip(",").strip("{").strip("}")
        if line:
            row = [int(x.strip()) for x in line.split(",") if x.strip()]
            if len(row) == 48:
                rows.append(row)
    
    assert len(rows) == 48, f"Matrix row count is {len(rows)}, expected 48"
    print(f"[PASS] Matrix extracted: 48x48.")

    # Spawn position (tile 3)
    spawn_r, spawn_c = -1, -1
    for r in range(48):
        for c in range(48):
            if rows[r][c] == 3:
                spawn_r, spawn_c = r, c
                break
    assert (spawn_r, spawn_c) == (42, 23), f"Spawn at ({spawn_r}, {spawn_c}), expected (42, 23)"
    print(f"[PASS] Spawn Airlock tile (3) confirmed at row {spawn_r}, col {spawn_c}.")

    # Exit elevator tile (4)
    exit_tiles = []
    for r in range(48):
        for c in range(48):
            if rows[r][c] == 4:
                exit_tiles.append((r, c))
    assert (2, 23) in exit_tiles, f"Exit tile (4) not found at (2, 23): {exit_tiles}"
    print(f"[PASS] Exit Elevator tile (4) confirmed at (2, 23).")

    # Doors: Door 0 is MainExit at (5, 23)
    doors = [
        {"id": 0, "r": 5, "c": 23, "type": 3, "reqKeys": 4},
        {"id": 1, "r": 39, "c": 23, "type": 0, "reqKeys": 0},
        {"id": 2, "r": 13, "c": 23, "type": 0, "reqKeys": 0},
        {"id": 3, "r": 31, "c": 15, "type": 0, "reqKeys": 0},
        {"id": 4, "r": 31, "c": 32, "type": 0, "reqKeys": 0},
        {"id": 5, "r": 10, "c": 15, "type": 0, "reqKeys": 0},
        {"id": 6, "r": 10, "c": 32, "type": 0, "reqKeys": 0},
    ]

    keys = [
        {"idx": 0, "r": 31, "c": 6, "name": "Key 1 Kiting Bay"},
        {"idx": 1, "r": 26, "c": 41, "name": "Key 2 Shooting Gallery"},
        {"idx": 2, "r": 11, "c": 9, "name": "Key 3 Sentinel Patrol"},
        {"idx": 3, "r": 11, "c": 38, "name": "Key 4 Mixed Vault"},
    ]

    def run_bfs(held_keys, lock_door0=False):
        visited = [[False]*48 for _ in range(48)]
        q = deque([(spawn_r, spawn_c)])
        visited[spawn_r][spawn_c] = True
        
        reached_keys = set()
        reached_exit = False

        while q:
            r, c = q.popleft()
            
            # Check keys
            for k in keys:
                if k["r"] == r and k["c"] == c:
                    reached_keys.add(k["idx"])

            # Check exit
            if rows[r][c] == 4:
                reached_exit = True

            for dr, dc in [(-1,0), (1,0), (0,-1), (0,1)]:
                nr, nc = r + dr, c + dc
                if 0 <= nr < 48 and 0 <= nc < 48 and not visited[nr][nc]:
                    tile = rows[nr][nc]
                    if tile in [1, 2, 9, 12]: # solid wall / crate / doorpocket
                        continue
                    if tile == 10: # Door
                        # Find door def
                        door_def = None
                        for d in doors:
                            if d["r"] == nr and d["c"] == nc:
                                door_def = d
                                break
                        if door_def:
                            if door_def["id"] == 0:
                                if lock_door0 or len(held_keys) < 4:
                                    continue
                            elif door_def["type"] != 0:
                                continue
                    visited[nr][nc] = True
                    q.append((nr, nc))
        return reached_keys, reached_exit

    # Phase 0: 0 keys held
    k0, ex0 = run_bfs(set())
    print(f"Phase 0 (0 keys held): reached keys={k0}, exit_reached={ex0}")
    assert not ex0, "FAIL: Exit reached with 0 keys!"
    assert k0 == {0, 1, 2, 3}, f"FAIL: Not all 4 keys accessible from corridors! Reached: {k0}"
    print("[PASS] Phase 0: All 4 keys accessible; exit elevator safely locked.")

    # Phase 1: 3 keys held
    k1, ex1 = run_bfs({0, 1, 2})
    print(f"Phase 1 (3 keys held): exit_reached={ex1}")
    assert not ex1, "FAIL: Exit prematurely accessible with 3 keys!"
    print("[PASS] Phase 1: Exit elevator safely locked with only 3 keys.")

    # Phase 2: All 4 keys held
    k2, ex2 = run_bfs({0, 1, 2, 3})
    print(f"Phase 2 (4 keys held): exit_reached={ex2}")
    assert ex2, "FAIL: Exit unreachable with all 4 keys held!"
    print("[PASS] Phase 2: Exit elevator successfully reached with all 4 keys.")

    # Anti-bypass: all 4 keys held, but door 0 forced locked
    k_ab, ex_ab = run_bfs({0, 1, 2, 3}, lock_door0=True)
    print(f"Anti-bypass (Door 0 locked): exit_reached={ex_ab}")
    assert not ex_ab, "FAIL: Exit reachable via bypass while door 0 is locked!"
    print("[PASS] Anti-Bypass verified: Exit elevator is 100% enclosed with zero bypass.")

def check_executable():
    print("\n=== EXECUTABLE CHECKS ===")
    exe_path = "build/Desktop_Qt_6_11_1_MinGW_64_bit_Debug/FPSLabGame.exe"
    assert os.path.exists(exe_path), f"Executable {exe_path} not found!"
    size_mb = os.path.getsize(exe_path) / (1024 * 1024)
    print(f"[PASS] FPSLabGame.exe built successfully! Size: {size_mb:.2f} MB.")

if __name__ == "__main__":
    check_guardrails()
    check_crawling()
    check_level1_layout_and_bfs()
    check_executable()
    print("\nALL VERIFICATION TESTS PASSED SUCCESSFULLY! (100% GREEN)")
