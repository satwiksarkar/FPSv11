# scratch/apply_leveldata_patch.py
import re

with open("scratch/level1_new_matrix.txt", "r", encoding="utf-8") as f:
    matrix_48 = f.read().strip()

with open("src/LevelData.cpp", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Replace arrays level1_v1, level1_v2, level1
idx_v1 = content.find("const int LevelData::level1_v1[48][48] = {")
idx_l2 = content.find("const int LevelData::level2[LEVEL2_SIZE][LEVEL2_SIZE] = {")
assert idx_v1 != -1 and idx_l2 != -1, "Array declarations not found"

new_arrays = f"""const int LevelData::level1_v1[48][48] = {{
{matrix_48}
}};

const int LevelData::level1_v2[48][48] = {{
{matrix_48}
}};

const int LevelData::level1[48][48] = {{
{matrix_48}
}};

"""
content = content[:idx_v1] + new_arrays + content[idx_l2:]

# 2. Update getTile for Level 1
tile_sig = "int LevelData::getTile(int level, int row, int col, int variant)\n{"
idx_tile = content.find(tile_sig)
assert idx_tile != -1, "getTile not found"
idx_tile_l2 = content.find("    } else if (level == 2) {", idx_tile)
assert idx_tile_l2 != -1, "getTile level 2 not found"

new_tile_l1 = """int LevelData::getTile(int level, int row, int col, int variant)
{
    Q_UNUSED(variant);
    if (level == 1) {
        if (row < 0 || row >= LEVEL1_SIZE || col < 0 || col >= LEVEL1_SIZE) return TileCode::Wall;
        return level1[row][col];
"""
content = content[:idx_tile] + new_tile_l1 + content[idx_tile_l2:]

# 3. Update getSpawnPoint for Level 1
spawn_sig = "QVector3D LevelData::getSpawnPoint(int level, int variant)\n{"
idx_spawn = content.find(spawn_sig)
assert idx_spawn != -1, "getSpawnPoint not found"
idx_spawn_l2 = content.find("    } else if (level == 2) {", idx_spawn)
assert idx_spawn_l2 != -1, "getSpawnPoint level 2 not found"

new_spawn_l1 = """QVector3D LevelData::getSpawnPoint(int level, int variant)
{
    Q_UNUSED(variant);
    float bs = GameConfig::BLOCK_SIZE;
    if (level == 1) {
        return QVector3D((23.0f + 0.5f) * bs, 0.0f, (42.0f + 0.5f) * bs);
"""
content = content[:idx_spawn] + new_spawn_l1 + content[idx_spawn_l2:]

# 4. Update getExitCenterPosition for Level 1
exit_sig = "QVector3D LevelData::getExitCenterPosition(int level, int variant)\n{"
idx_exit = content.find(exit_sig)
assert idx_exit != -1, "getExitCenterPosition not found"
idx_exit_l2 = content.find("    } else if (level == 2) {", idx_exit)
assert idx_exit_l2 != -1, "getExitCenterPosition level 2 not found"

new_exit_l1 = """QVector3D LevelData::getExitCenterPosition(int level, int variant)
{
    Q_UNUSED(variant);
    float bs = GameConfig::BLOCK_SIZE;
    if (level == 1) {
        return QVector3D((23.0f + 0.5f) * bs, 2.0f, (2.0f + 0.5f) * bs);
"""
content = content[:idx_exit] + new_exit_l1 + content[idx_exit_l2:]

# 5. Insert getFloorHeight and getCeilingHeight right before checkReachability
height_methods = """float LevelData::getFloorHeight(int level, int row, int col)
{
    if (level != 1) return 0.0f;
    if (row < 0 || row >= LEVEL1_SIZE || col < 0 || col >= LEVEL1_SIZE) return 0.0f;

    // Key 4 (Mixed Vault): elevated central catwalk at rows 10..12, cols 37..39 (2.0m = 200.0f)
    if (row >= 10 && row <= 12 && col >= 37 && col <= 39) {
        return 200.0f;
    }
    // Key 4 jumpable access crate at row 13, col 38 (1.0m = 100.0f)
    if (row == 13 && col == 38) {
        return 100.0f;
    }

    // Storage Room (Ambush): Staggered jumpable cargo crate stacks (1m -> 2m)
    if ((row == 8 || row == 9) && (col == 19 || col == 20)) {
        return 100.0f;
    }
    if ((row == 8 || row == 9) && (col == 27 || col == 28)) {
        return 200.0f;
    }

    return 0.0f;
}

float LevelData::getCeilingHeight(int level, int row, int col)
{
    if (level != 1) return 300.0f;
    if (row < 0 || row >= LEVEL1_SIZE || col < 0 || col >= LEVEL1_SIZE) return 450.0f;

    // Spawn Airlock (South, Safe Zone: 6x4 tiles): low ceiling (3m = 300.0f)
    if (row >= 40 && row <= 47 && col >= 21 && col <= 26) {
        return 300.0f;
    }
    // Exit Elevator (Far North: 6x4 tiles): low ceiling (3m = 300.0f)
    if (row >= 1 && row <= 5 && col >= 21 && col <= 26) {
        return 300.0f;
    }
    // Outer Bypass Corridors (West & East: 2 tiles wide): low ceiling (3m = 300.0f)
    if (row >= 18 && row <= 25 && col >= 5 && col <= 8) {
        return 300.0f;
    }
    if (row >= 18 && row <= 23 && col >= 41 && col <= 44) {
        return 300.0f;
    }
    // Key 3 (Sentinel Patrol): low-med ceiling (4m = 400.0f)
    if (row >= 6 && row <= 17 && col >= 5 && col <= 14) {
        return 400.0f;
    }
    // Central Spine (South-to-North): medium ceiling (4.5m = 450.0f)
    if (row >= 14 && row <= 39 && col >= 22 && col <= 25) {
        return 450.0f;
    }
    // Key 1 (Kiting Bay): medium ceiling (5m = 500.0f)
    if (row >= 26 && row <= 35 && col >= 5 && col <= 14) {
        return 500.0f;
    }
    // Key 2 (Shooting Gallery): high ceiling (7m = 700.0f)
    if (row >= 24 && row <= 35 && col >= 33 && col <= 42) {
        return 700.0f;
    }
    // Key 4 (Mixed Vault): high ceiling (7m = 700.0f)
    if (row >= 6 && row <= 17 && col >= 33 && col <= 44) {
        return 700.0f;
    }
    // Storage Room Ambush: high ceiling (7.5m = 750.0f)
    if (row >= 6 && row <= 13 && col >= 17 && col <= 30) {
        return 750.0f;
    }

    return 450.0f;
}

"""
reach_sig = "bool LevelData::checkReachability(int level, QString &outLog, int variant)"
idx_reach = content.find(reach_sig)
assert idx_reach != -1, "checkReachability not found"
content = content[:idx_reach] + height_methods + content[idx_reach:]

# 6. Update Level 1 in checkReachability
idx_reach = content.find(reach_sig)
idx_reach_l1 = content.find("    if (level == 1) {", idx_reach)
idx_reach_l2 = content.find("    if (level == 2) {", idx_reach_l1)
assert idx_reach_l1 != -1 and idx_reach_l2 != -1, "checkReachability level 1 block not found"

new_reach_l1 = """    if (level == 1) {
        // Level 1 "Fabrication Floors" (48x48) progression validation
        // Phase 0: 0 keys acquired -> exit bulkhead locked
        auto p0 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {}, false, false, variant);
        if (p0.exitReached) {
            outLog = QStringLiteral("Level 1 failed: Exit Elevator accessible with 0 keys!");
            return false;
        }
        // Phase 1: 3 keys acquired -> exit bulkhead still locked
        auto p1 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2}, false, false, variant);
        if (p1.exitReached) {
            outLog = QStringLiteral("Level 1 failed: Exit Elevator prematurely accessible with only 3 keys!");
            return false;
        }
        // Phase 2: All 4 keys acquired -> exit reachable
        auto p2 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, false, variant);
        if (!p2.exitReached) {
            outLog = QStringLiteral("Level 1 failed: Exit Elevator unreachable with all 4 keys!");
            return false;
        }
        // Anti-Bypass verification: all 4 keys held, but Exit door locked
        auto ab = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, true, variant);
        if (ab.exitReached) {
            outLog = QStringLiteral("Level 1 Anti-Bypass failed: Exit Elevator reachable while bulkhead is locked!");
            return false;
        }
        outLog = QStringLiteral("Level 1 'Fabrication Floors' (48x48) progression verified: 4 keys, 4 sectors, Exit Elevator secured with zero bypass.");
        return true;
    }

"""
content = content[:idx_reach_l1] + new_reach_l1 + content[idx_reach_l2:]

# 7. Update Level 1 Entity Spawns
spawns_l1_sig = "QList<QVector3D> LevelData::getLevel1CorridorDroneSpawns(int variant)"
idx_spawns_l1 = content.find(spawns_l1_sig)
idx_spawns_l2 = content.find("// ==================== LEVEL 2 ENTITY SPAWNS ====================")
assert idx_spawns_l1 != -1 and idx_spawns_l2 != -1, "entity spawns block not found"

new_spawns_l1 = """QList<QVector3D> LevelData::getLevel1DynamicSpawnAnchors()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        // Key 1 (Kiting Bay) - 4 corners surrounding central fabrication unit
        QVector3D((8.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs),
        QVector3D((12.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs),
        QVector3D((8.0f + 0.5f) * bs, 0.0f, (34.0f + 0.5f) * bs),
        QVector3D((12.0f + 0.5f) * bs, 0.0f, (34.0f + 0.5f) * bs),

        // Central Spine - Staggered near cover pillars & sensors
        QVector3D((23.0f + 0.5f) * bs, 0.0f, (35.0f + 0.5f) * bs),
        QVector3D((24.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs),
        QVector3D((23.0f + 0.5f) * bs, 0.0f, (21.0f + 0.5f) * bs),
        QVector3D((24.0f + 0.5f) * bs, 0.0f, (16.0f + 0.5f) * bs),

        // Key 2 (Shooting Gallery) - Along rows between waist-high cover
        QVector3D((35.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
        QVector3D((38.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
        QVector3D((41.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
        QVector3D((35.0f + 0.5f) * bs, 0.0f, (34.0f + 0.5f) * bs),
        QVector3D((41.0f + 0.5f) * bs, 0.0f, (34.0f + 0.5f) * bs),

        // Key 3 (Sentinel Patrol) - Square ring corridor
        QVector3D((7.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs),
        QVector3D((13.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs),
        QVector3D((10.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
        QVector3D((10.0f + 0.5f) * bs, 0.0f, (15.0f + 0.5f) * bs),

        // Key 4 (Mixed Vault) - Flanking L-walls and elevated platform
        QVector3D((35.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
        QVector3D((42.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
        QVector3D((35.0f + 0.5f) * bs, 0.0f, (15.0f + 0.5f) * bs),
        QVector3D((42.0f + 0.5f) * bs, 0.0f, (15.0f + 0.5f) * bs),

        // Outer Bypass Corridors (West & East)
        QVector3D((7.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs),
        QVector3D((42.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs)
    };
}

QList<QVector3D> LevelData::getLevel1StorageAmbushAnchors()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((19.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
        QVector3D((27.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
        QVector3D((23.0f + 0.5f) * bs, 0.0f, (9.0f + 0.5f) * bs),
        QVector3D((20.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs),
        QVector3D((26.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs),
        QVector3D((23.0f + 0.5f) * bs, 0.0f, (12.0f + 0.5f) * bs)
    };
}

QList<QVector3D> LevelData::getLevel1CorridorDroneSpawns(int variant)
{
    Q_UNUSED(variant);
    return getLevel1DynamicSpawnAnchors();
}

QList<QVector3D> LevelData::getLevel1LoadingBayDroneSpawns(int variant)
{
    Q_UNUSED(variant);
    return getLevel1StorageAmbushAnchors();
}

QList<PickupItemDef> LevelData::getLevel1Pickups(int variant)
{
    Q_UNUSED(variant);
    float bs = GameConfig::BLOCK_SIZE;
    return {
        // Key 1 (Kiting Bay)
        { QVector3D((6.0f + 0.5f) * bs, 25.0f, (27.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((13.0f + 0.5f) * bs, 25.0f, (34.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        // Central Spine
        { QVector3D((23.0f + 0.5f) * bs, 25.0f, (30.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((24.0f + 0.5f) * bs, 25.0f, (18.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        // Key 2 (Shooting Gallery)
        { QVector3D((41.0f + 0.5f) * bs, 25.0f, (35.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((34.0f + 0.5f) * bs, 25.0f, (35.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        // Key 3 (Sentinel Patrol)
        { QVector3D((6.0f + 0.5f) * bs, 25.0f, (7.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        // Key 4 (Mixed Vault)
        { QVector3D((43.0f + 0.5f) * bs, 25.0f, (7.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        // Storage Room
        { QVector3D((20.0f + 0.5f) * bs, 25.0f, (7.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((27.0f + 0.5f) * bs, 25.0f, (7.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") }
    };
}

"""
content = content[:idx_spawns_l1] + new_spawns_l1 + content[idx_spawns_l2:]

# 8. Update getLevelDoors for Level 1
doors_sig = "QList<DoorDef> LevelData::getLevelDoors(int level, int variant)\n{"
idx_doors = content.find(doors_sig)
assert idx_doors != -1, "getLevelDoors not found"
idx_doors_l1 = content.find("    if (level == 1) {", idx_doors)
idx_doors_l2 = content.find("    } else if (level == 2) {", idx_doors_l1)
assert idx_doors_l1 != -1 and idx_doors_l2 != -1, "getLevelDoors level 1 block not found"

new_doors_l1 = """    if (level == 1) {
        return {
            // Door 0: Exit Elevator Main Bulkhead (requires all 4 keys, unlocked by 4-digit code)
            { 0, 5, 23, 0.0f, 3 /* MainExit */, -1, 4, 0b1111, false, QStringLiteral("EXIT ELEVATOR BULKHEAD") },
            // Door 1: Spawn Airlock Bulkhead to Central Spine
            { 1, 39, 23, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("SPAWN AIRLOCK GATE") },
            // Door 2: Storage Bay Access from Central Spine
            { 2, 13, 23, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("STORAGE BAY ACCESS") },
            // Door 3: Kiting Bay Access from Central Spine
            { 3, 31, 15, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("KITING BAY ACCESS") },
            // Door 4: Shooting Gallery Access from Central Spine
            { 4, 31, 32, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("SHOOTING GALLERY ACCESS") },
            // Door 5: Patrol Sector Access from Storage Room
            { 5, 10, 15, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("PATROL SECTOR ACCESS") },
            // Door 6: Mixed Vault Access from Storage Room
            { 6, 10, 32, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("MIXED VAULT ACCESS") }
        };
    }"""
content = content[:idx_doors_l1] + new_doors_l1 + content[idx_doors_l2+5:]

# 9. Update getLevelKeys for Level 1
keys_sig = "QList<KeyDef> LevelData::getLevelKeys(int level, int variant)\n{"
idx_keys = content.find(keys_sig)
assert idx_keys != -1, "getLevelKeys not found"
idx_keys_l1 = content.find("    if (level == 1) {", idx_keys)
idx_keys_l2 = content.find("    } else if (level == 2) {", idx_keys_l1)
assert idx_keys_l1 != -1 and idx_keys_l2 != -1, "getLevelKeys level 1 block not found"

new_keys_l1 = """    if (level == 1) {
        return {
            { 1, 0, 31, 6, QStringLiteral("KITING BAY ACCESS KEY 1") },
            { 1, 1, 26, 41, QStringLiteral("SHOOTING GALLERY ACCESS KEY 2") },
            { 1, 2, 11, 9, QStringLiteral("SENTINEL PATROL ACCESS KEY 3") },
            { 1, 3, 11, 38, QStringLiteral("MIXED VAULT ACCESS KEY 4") }
        };
    }"""
content = content[:idx_keys_l1] + new_keys_l1 + content[idx_keys_l2+5:]

with open("src/LevelData.cpp", "w", encoding="utf-8") as f:
    f.write(content)

print("LevelData.cpp successfully patched with 0 errors!")
