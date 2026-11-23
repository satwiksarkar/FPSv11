with open('scratch/LevelData_new.cpp', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace checkReachability
old_reach_start = 'bool LevelData::checkReachability(int level, QString &outLog)'
idx_rs = text.find(old_reach_start)
assert idx_rs != -1
idx_l2 = text.find('if (level == 2) {', idx_rs)
assert idx_l2 != -1

new_reach_l1 = '''bool LevelData::checkReachability(int level, QString &outLog, int variant)
{
    int w = getMapWidth(level, variant);
    int h = getMapHeight(level, variant);
    int exitCode = getExitTileCode(level);

    int startR = -1, startC = -1;
    for (int r = 0; r < h && startR == -1; ++r) {
        for (int c = 0; c < w; ++c) {
            if (getTile(level, r, c, variant) == TileCode::PlayerSpawn) {
                startR = r;
                startC = c;
                break;
            }
        }
    }

    if (startR == -1) {
        outLog = QStringLiteral("Error: Spawn tile (3) not found in map!");
        return false;
    }

    QList<DoorDef> doors = getLevelDoors(level, variant);
    QList<KeyDef> keys = getLevelKeys(level, variant);

    if (level == 1) {
        if (variant == 2) {
            auto p0 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {}, false, false, 2);
            if (p0.exitReached) {
                outLog = QStringLiteral("Level 1 V2 failed: Exit prematurely accessible with 0 keys!");
                return false;
            }
            auto p1 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1}, false, false, 2);
            if (p1.exitReached) {
                outLog = QStringLiteral("Level 1 V2 failed: Exit prematurely accessible with 2 keys!");
                return false;
            }
            auto p2 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, false, 2);
            if (!p2.exitReached) {
                outLog = QStringLiteral("Level 1 V2 failed: Freight Elevator exit unreachable with all 4 keys!");
                return false;
            }
            auto ab = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, true, 2);
            if (ab.exitReached) {
                outLog = QStringLiteral("Level 1 V2 Anti-Bypass failed: Exit reachable while Freight Elevator door is locked!");
                return false;
            }
            outLog = QStringLiteral("Level 1 Variant 2 (80x80) progression verified: 4 keys, 2 vaults, Freight Elevator secured with zero bypass.");
            return true;
        } else {
            auto p0 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {}, false, false, 1);
            if (p0.exitReached) {
                outLog = QStringLiteral("Level 1 V1 failed: Exit prematurely accessible with 0 keys!");
                return false;
            }
            auto p1 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0}, false, false, 1);
            if (p1.exitReached) {
                outLog = QStringLiteral("Level 1 V1 failed: Exit prematurely accessible with 1 key!");
                return false;
            }
            auto p2 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1}, false, false, 1);
            if (!p2.exitReached) {
                outLog = QStringLiteral("Level 1 V1 failed: Freight Elevator exit unreachable with both keys!");
                return false;
            }
            auto ab = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1}, false, true, 1);
            if (ab.exitReached) {
                outLog = QStringLiteral("Level 1 V1 Anti-Bypass failed: Exit reachable while Freight Elevator door is locked!");
                return false;
            }
            outLog = QStringLiteral("Level 1 Variant 1 (48x48) progression verified: 2 keys, 2 vaults, Freight Elevator secured with zero bypass.");
            return true;
        }
    }

    '''

text = text[:idx_rs] + new_reach_l1 + text[idx_l2:]

idx_spawns = text.find('// ==================== LEVEL 1 ENTITY SPAWNS ====================')
assert idx_spawns != -1
idx_l2_spawns = text.find('// ==================== LEVEL 2 ENTITY SPAWNS ====================')
assert idx_l2_spawns != -1

new_l1_spawns = '''// ==================== LEVEL 1 ENTITY SPAWNS ====================

QList<QVector3D> LevelData::getLevel1CorridorDroneSpawns(int variant)
{
    float bs = GameConfig::BLOCK_SIZE;
    if (variant == 2) {
        return {
            QVector3D((39.0f + 0.5f) * bs, 0.0f, (56.0f + 0.5f) * bs),
            QVector3D((40.0f + 0.5f) * bs, 0.0f, (45.0f + 0.5f) * bs),
            QVector3D((35.0f + 0.5f) * bs, 0.0f, (35.0f + 0.5f) * bs),
            QVector3D((45.0f + 0.5f) * bs, 0.0f, (35.0f + 0.5f) * bs),
            QVector3D((40.0f + 0.5f) * bs, 0.0f, (20.0f + 0.5f) * bs),
            QVector3D((18.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
            QVector3D((62.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
            QVector3D((56.0f + 0.5f) * bs, 0.0f, (18.0f + 0.5f) * bs),
            QVector3D((64.0f + 0.5f) * bs, 0.0f, (12.0f + 0.5f) * bs),
            QVector3D((18.0f + 0.5f) * bs, 0.0f, (52.0f + 0.5f) * bs),
            QVector3D((12.0f + 0.5f) * bs, 0.0f, (58.0f + 0.5f) * bs),
            QVector3D((60.0f + 0.5f) * bs, 0.0f, (52.0f + 0.5f) * bs),
            QVector3D((68.0f + 0.5f) * bs, 0.0f, (64.0f + 0.5f) * bs),
            QVector3D((24.0f + 0.5f) * bs, 0.0f, (18.0f + 0.5f) * bs)
        };
    } else {
        return {
            QVector3D((23.0f + 0.5f) * bs, 0.0f, (32.0f + 0.5f) * bs),
            QVector3D((24.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs),
            QVector3D((22.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs),
            QVector3D((30.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs),
            QVector3D((17.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs),
            QVector3D((24.0f + 0.5f) * bs, 0.0f, (16.0f + 0.5f) * bs),
            QVector3D((35.0f + 0.5f) * bs, 0.0f, (12.0f + 0.5f) * bs),
            QVector3D((12.0f + 0.5f) * bs, 0.0f, (32.0f + 0.5f) * bs)
        };
    }
}

QList<QVector3D> LevelData::getLevel1LoadingBayDroneSpawns(int variant)
{
    float bs = GameConfig::BLOCK_SIZE;
    if (variant == 2) {
        return {
            QVector3D((10.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
            QVector3D((22.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),
            QVector3D((10.0f + 0.5f) * bs, 0.0f, (16.0f + 0.5f) * bs),
            QVector3D((22.0f + 0.5f) * bs, 0.0f, (16.0f + 0.5f) * bs),
            QVector3D((16.0f + 0.5f) * bs, 0.0f, (21.0f + 0.5f) * bs)
        };
    } else {
        return {
            QVector3D((10.0f + 0.5f) * bs, 0.0f, (10.0f + 0.5f) * bs),
            QVector3D((15.0f + 0.5f) * bs, 0.0f, (12.0f + 0.5f) * bs),
            QVector3D((12.0f + 0.5f) * bs, 0.0f, (16.0f + 0.5f) * bs)
        };
    }
}

QList<PickupItemDef> LevelData::getLevel1Pickups(int variant)
{
    float bs = GameConfig::BLOCK_SIZE;
    if (variant == 2) {
        return {
            { QVector3D((15.0f + 0.5f) * bs, 25.0f, (12.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
            { QVector3D((60.0f + 0.5f) * bs, 25.0f, (10.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
            { QVector3D((15.0f + 0.5f) * bs, 25.0f, (65.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
            { QVector3D((65.0f + 0.5f) * bs, 25.0f, (65.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
            { QVector3D((40.0f + 0.5f) * bs, 25.0f, (38.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
            { QVector3D((40.0f + 0.5f) * bs, 25.0f, (10.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") }
        };
    } else {
        return {
            { QVector3D((12.0f + 0.5f) * bs, 25.0f, (12.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
            { QVector3D((35.0f + 0.5f) * bs, 25.0f, (10.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
            { QVector3D((12.0f + 0.5f) * bs, 25.0f, (35.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
            { QVector3D((24.0f + 0.5f) * bs, 25.0f, (24.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") }
        };
    }
}

'''

text = text[:idx_spawns] + new_l1_spawns + text[idx_l2_spawns:]

idx_doors = text.find('// ==================== DOOR & KEY DEFINITIONS PER LEVEL (DAY 3) ====================')
assert idx_doors != -1

new_doors_keys = '''// ==================== DOOR & KEY DEFINITIONS PER LEVEL (DAY 3) ====================

QList<DoorDef> LevelData::getLevelDoors(int level, int variant)
{
    if (level == 1) {
        if (variant == 2) {
            return {
                { 0, 16, 40, 0.0f, 3 /* MainExit */, -1, 4, 0b1111, false, QStringLiteral("FREIGHT ELEVATOR BULKHEAD") },
                { 1, 10, 69, 90.0f, 1 /* KeyLocked */, -1, 0, 0, false, QStringLiteral("ELECTRICAL VAULT BULKHEAD") },
                { 2, 69, 16, 0.0f, 1 /* KeyLocked */, -1, 0, 0, false, QStringLiteral("PASSWORD VAULT BULKHEAD") }
            };
        } else {
            return {
                { 0, 12, 24, 0.0f, 3 /* MainExit */, -1, 2, 0b0011, false, QStringLiteral("FREIGHT ELEVATOR BULKHEAD") },
                { 1, 11, 40, 90.0f, 1 /* KeyLocked */, -1, 0, 0, false, QStringLiteral("ELECTRICAL VAULT BULKHEAD") },
                { 2, 39, 12, 0.0f, 1 /* KeyLocked */, -1, 0, 0, false, QStringLiteral("PASSWORD VAULT BULKHEAD") }
            };
        }
    } else if (level == 2) {
        return {
            { 1, 61, 7, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("CACHE DOOR") },
            { 2, 36, 4, 0.0f, 1 /* KeyLocked */, 0, 0, 0, false, QStringLiteral("WEST ARSENAL GATE") },
            { 3, 28, 20, 90.0f, 2 /* AreaLocked */, -1, 2, 0b0011, false, QStringLiteral("PROVING GROUNDS GATE") },
            { 4, 14, 42, 90.0f, 2 /* AreaLocked */, -1, 3, 0, false, QStringLiteral("EXPLOSIVES DEPOT GATE") },
            { 5, 50, 32, 90.0f, 3 /* MainExit */, -1, 4, 0, false, QStringLiteral("DESCENT SHAFT BULKHEAD") }
        };
    } else if (level == 3) {
        return {
            { 1, 31, 20, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("SOUTH AIRLOCK") },
            { 2, 20, 12, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("WEST WING") },
            { 3, 20, 28, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("EAST WING") },
            { 4, 12, 20, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("NORTH WING") },
            { 5, 4, 20, 0.0f, 3 /* MainExit */, -1, 4, 0, true, QStringLiteral("CORE EXTRACTION") }
        };
    }
    return {};
}

QList<KeyDef> LevelData::getLevelKeys(int level, int variant)
{
    if (level == 1) {
        if (variant == 2) {
            return {
                { 1, 0, 8, 74, QStringLiteral("ELECTRICAL VAULT KEY 1") },
                { 1, 1, 12, 74, QStringLiteral("ELECTRICAL VAULT KEY 2") },
                { 1, 2, 74, 13, QStringLiteral("PASSWORD VAULT KEY 3") },
                { 1, 3, 74, 18, QStringLiteral("PASSWORD VAULT KEY 4") }
            };
        } else {
            return {
                { 1, 0, 11, 44, QStringLiteral("ELECTRICAL VAULT KEY 1") },
                { 1, 1, 43, 12, QStringLiteral("PASSWORD VAULT KEY 2") }
            };
        }
    } else if (level == 2) {
        return {
            { 2, 0, 44, 4, QStringLiteral("ARMORY KEY A") },
            { 2, 1, 20, 15, QStringLiteral("ARMORY KEY B") },
            { 2, 2, 26, 35, QStringLiteral("ARMORY KEY C") },
            { 2, 3, 14, 55, QStringLiteral("ARMORY KEY D") }
        };
    } else if (level == 3) {
        return {
            { 3, 0, 6, 20, QStringLiteral("CORE KEY A (CRYO)") },
            { 3, 1, 20, 35, QStringLiteral("CORE KEY B (TURBINE)") },
            { 3, 2, 30, 26, QStringLiteral("CORE KEY C (DIAGNOSTIC)") },
            { 3, 3, 20, 5, QStringLiteral("CORE KEY D (CONDENSER)") }
        };
    }
    return {};
}
'''

text = text[:idx_doors] + new_doors_keys

with open('scratch/LevelData_new.cpp', 'w', encoding='utf-8') as f:
    f.write(text)

print('Successfully generated scratch/LevelData_new.cpp')
