# patch_leveldata_correct.py
with open("scratch/level1_new_matrix.txt", "r", encoding="utf-8") as f:
    matrix_48x48_lines = f.read().strip()

matrix_block = "const int LevelData::level1[48][48] = {\n" + matrix_48x48_lines + "\n};"
matrix_v2_block = "const int LevelData::level1_v2[48][48] = {\n" + matrix_48x48_lines + "\n};"

with open("src/LevelData.cpp", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Replace level1_v2[80][80] definition
start_v2 = content.find("const int LevelData::level1_v2[80][80] = {")
end_v2 = content.find("};\nconst int LevelData::level1[80][80] = {", start_v2)
if start_v2 != -1 and end_v2 != -1:
    content = content[:start_v2] + matrix_v2_block + "\n" + content[end_v2+3:]
else:
    print("Warning: level1_v2[80][80] block not found")

# 2. Replace level1[80][80] definition
start_l1 = content.find("const int LevelData::level1[80][80] = {")
end_l1 = content.find("};\nconst int LevelData::level2[LEVEL2_SIZE][LEVEL2_SIZE] = {", start_l1)
if start_l1 != -1 and end_l1 != -1:
    content = content[:start_l1] + matrix_block + "\n" + content[end_l1+3:]
else:
    print("Warning: level1[80][80] block not found")

# 3. Update getSpawnPoint for level 1
spawn_target = """    if (level == 1) {
        if (variant == 2) {
            return QVector3D((39.0f + 0.5f) * bs, 0.0f, (68.0f + 0.5f) * bs);
        } else {
            return QVector3D((23.0f + 0.5f) * bs, 0.0f, (42.0f + 0.5f) * bs);
        }
    }"""
spawn_replacement = """    if (level == 1) {
        return QVector3D((23.0f + 0.5f) * bs, 0.0f, (42.0f + 0.5f) * bs);
    }"""
content = content.replace(spawn_target, spawn_replacement)

# 4. Update getExitCenterPosition for level 1
exit_target = """    if (level == 1) {
        if (variant == 2) {
            return QVector3D((40.0f + 0.5f) * bs, 2.0f, (7.0f + 0.5f) * bs);
        } else {
            return QVector3D((24.0f + 0.5f) * bs, 2.0f, (6.0f + 0.5f) * bs);
        }
    }"""
exit_replacement = """    if (level == 1) {
        return QVector3D((23.0f + 0.5f) * bs, 2.0f, (2.0f + 0.5f) * bs);
    }"""
content = content.replace(exit_target, exit_replacement)

# 5. Insert getFloorHeight and getCeilingHeight right before checkReachability
height_methods = """
float LevelData::getFloorHeight(int level, int row, int col)
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
content = content.replace("bool LevelData::checkReachability(int level, QString &outLog, int variant)",
                          height_methods + "\nbool LevelData::checkReachability(int level, QString &outLog, int variant)")

# 6. Update Level 1 Reachability Check in checkReachability
reach_target_start = content.find("    if (level == 1) {")
reach_target_end = content.find("    if (level == 2) {", reach_target_start)
if reach_target_start != -1 and reach_target_end != -1:
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
    content = content[:reach_target_start] + new_reach_l1 + content[reach_target_end:]

# 7. Replace Level 1 Entity Spawns & Pickups
spawn_anchors_code = """
QList<QVector3D> LevelData::getLevel1DynamicSpawnAnchors()
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

spawns_l1_start = content.find("QList<QVector3D> LevelData::getLevel1CorridorDroneSpawns(int variant)")
spawns_l2_start = content.find("// ==================== LEVEL 2 ENTITY SPAWNS ====================")
if spawns_l1_start != -1 and spawns_l2_start != -1:
    content = content[:spawns_l1_start] + spawn_anchors_code.strip() + "\n\n" + content[spawns_l2_start:]

# 8. Replace getLevelDoors for level 1
door_start = content.find("QList<DoorDef> LevelData::getLevelDoors(int level, int variant)\n{")
if door_start != -1:
    door_l1_start = content.find("    if (level == 1) {", door_start)
    door_l2_start = content.find("    } else if (level == 2) {", door_l1_start)
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
    content = content[:door_l1_start] + new_doors_l1 + content[door_l2_start+5:]

# 9. Replace getLevelKeys for level 1
keys_start = content.find("QList<KeyDef> LevelData::getLevelKeys(int level, int variant)\n{")
if keys_start != -1:
    keys_l1_start = content.find("    if (level == 1) {", keys_start)
    keys_l2_start = content.find("    } else if (level == 2) {", keys_l1_start)
    new_keys_l1 = """    if (level == 1) {
        return {
            { 1, 0, 31, 6, QStringLiteral("KITING BAY ACCESS KEY 1") },
            { 1, 1, 26, 41, QStringLiteral("SHOOTING GALLERY ACCESS KEY 2") },
            { 1, 2, 11, 9, QStringLiteral("SENTINEL PATROL ACCESS KEY 3") },
            { 1, 3, 11, 38, QStringLiteral("MIXED VAULT ACCESS KEY 4") }
        };
    }"""
    content = content[:keys_l1_start] + new_keys_l1 + content[keys_l2_start+5:]

with open("src/LevelData.cpp", "w", encoding="utf-8") as f:
    f.write(content)

print("LevelData.cpp successfully patched with correct offsets!")
