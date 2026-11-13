#include "LevelManager.h"
#include "BossArena.h"
#include "GameConfig.h"
#include "CollisionSystem.h"
#include "EnemyManager.h"
#include "Enemy.h"
#include <QtMath>
#include <QDebug>
#include <algorithm>
#include <cmath>

LevelManager::LevelManager(QObject *parent)
    : QObject(parent)
    , m_currentLevel(1)
    , m_maxLevels(3)
    , m_exitTriggered(false)
    , m_exitDenyNotified(false)
    , m_loadingBayTriggered(false)
    , m_heavyWeaponCollected(false)
    , m_keyMasks{0, 0, 0, 0}
    , m_bossCompleted(false)
    , m_activeVentsRemaining(4)
{
    qDebug() << "[LevelManager] Initialized on Level" << m_currentLevel << ":" << currentLevelName();
}

int LevelManager::currentLevel() const
{
    return m_currentLevel;
}

int LevelManager::maxLevels() const
{
    return m_maxLevels;
}

QString LevelManager::currentLevelName() const
{
    return LevelData::getLevelName(m_currentLevel);
}

QString LevelManager::storyTitle() const
{
    return LevelData::getStoryTitle(m_currentLevel);
}

QString LevelManager::storyText() const
{
    return LevelData::getStoryText(m_currentLevel);
}

QVector3D LevelManager::spawnPosition() const
{
    return LevelData::getSpawnPoint(m_currentLevel);
}

QVector3D LevelManager::exitCenterPosition() const
{
    return LevelData::getExitCenterPosition(m_currentLevel);
}

int LevelManager::mapWidth() const
{
    return LevelData::getMapWidth(m_currentLevel);
}

int LevelManager::mapHeight() const
{
    return LevelData::getMapHeight(m_currentLevel);
}

float LevelManager::blockSize() const
{
    return GameConfig::BLOCK_SIZE;
}

bool LevelManager::isLoadingBayTriggered() const
{
    return m_loadingBayTriggered;
}

void LevelManager::loadLevel(int levelIndex, bool resetLevelKeys)
{
    m_exitTriggered = false;
    m_exitDenyNotified = false;
    m_loadingBayTriggered = false;
    m_consumedAmmoTiles.clear();
    m_triggeredTraps.clear();

    if (levelIndex == 1) {
        m_heavyWeaponCollected = false;
        emit heavyWeaponCollectedChanged();
    }

    if (levelIndex > m_maxLevels) {
        clearDoors();
        clearKeys();
        qDebug() << "[LevelManager] All campaign levels completed! Triggering campaign victory.";
        m_currentLevel = m_maxLevels + 1;
        emit currentLevelChanged(m_currentLevel);
        emit storyChanged();
        emit missionProgressChanged();
        emit campaignWon();
        return;
    }

    m_currentLevel = qBound(1, levelIndex, m_maxLevels);
    if (resetLevelKeys) {
        m_keyMasks[m_currentLevel] = 0;
    }

    if (m_currentLevel == 3) {
        m_bossCompleted = m_bossArena ? m_bossArena->isBossDefeated() : false;
        m_activeVentsRemaining = m_bossArena ? m_bossArena->activeVentsCount() : 4;
    } else {
        m_bossCompleted = false;
        m_activeVentsRemaining = 0;
    }

    rebuildDoorsForLevel(m_currentLevel);
    rebuildKeysForLevel(m_currentLevel);
    qDebug() << "[LevelManager] Loaded Level" << m_currentLevel << ":" << currentLevelName()
             << "| Access Keys:" << collectedKeysCount() << "/" << totalKeysRequired();

    // ==================== BFS REACHABILITY CHECK AT LOAD TIME ====================
    QString reachabilityLog;
    bool isReachable = LevelData::checkReachability(m_currentLevel, reachabilityLog);
    if (!isReachable) {
        qWarning() << "[LevelManager] CRITICAL WARNING: Exit tile is NOT reachable from spawn!" << reachabilityLog;
    } else {
        qDebug() << "[LevelManager] Reachability verified:" << reachabilityLog;
    }

    emit missionKeysChanged(m_currentLevel, collectedKeysCount(), collectedKeysMask());
    emit missionProgressChanged();
    emit currentLevelChanged(m_currentLevel);
    emit storyChanged();
    emit levelLoaded(m_currentLevel);
}

void LevelManager::advanceLevel()
{
    loadLevel(m_currentLevel + 1);
}

void LevelManager::resetToFirstLevel()
{
    loadLevel(1);
}

int LevelManager::getTile(int row, int col) const
{
    return LevelData::getTile(m_currentLevel, row, col);
}

int LevelManager::getTileAtWorldPos(float x, float z) const
{
    int col = qFloor(x / GameConfig::BLOCK_SIZE);
    int row = qFloor(z / GameConfig::BLOCK_SIZE);
    return getTile(row, col);
}

bool LevelManager::isStaticSolidTile(int row, int col) const
{
    int tile = getTile(row, col);
    return (tile == TileCode::Wall ||
            tile == TileCode::Crate ||
            tile == TileCode::CoreWall ||
            tile == TileCode::DoorPocket);
}

bool LevelManager::isSolidTile(int row, int col) const
{
    if (isStaticSolidTile(row, col)) {
        return true;
    }

    if (Door *door = doorAtTile(row, col)) {
        return door->isBlocking();
    }

    // Any TileCode::Door without an explicit Door instance defaults to solid/closed
    if (getTile(row, col) == TileCode::Door) {
        return true;
    }

    return false;
}

bool LevelManager::checkExitReached(const QVector3D &playerPos, bool playerAlive)
{
    if (m_exitTriggered || !playerAlive) {
        return false;
    }

    int exitTileCode = LevelData::getExitTileCode(m_currentLevel);
    if (exitTileCode <= 0) {
        return false;
    }

    int tileAtPlayer = getTileAtWorldPos(playerPos.x(), playerPos.z());
    if (tileAtPlayer != exitTileCode) {
        m_exitDenyNotified = false;
        return false;
    }

    // Defensive extraction gate: never permit level transition or victory if Day 2 requirements are incomplete
    if (!isExtractionAvailable()) {
        if (!m_exitDenyNotified) {
            m_exitDenyNotified = true;
            QString msg = (m_currentLevel == 3)
                ? QStringLiteral("[LOCKED] NEED 4 KEYS (%1/4) & OVERLOAD CORE (%2 VENTS LEFT)")
                      .arg(collectedKeysCount())
                      .arg(m_activeVentsRemaining)
                : QStringLiteral("[LOCKED] NEED ALL 4 ACCESS KEYS (%1/4)").arg(collectedKeysCount());
            emit doorInteractionFeedback(msg, QStringLiteral("#e74c3c"));
        }
        return false;
    }

    m_exitTriggered = true;
    qDebug() << "[LevelManager] Player entered exit tile" << exitTileCode << "at" << playerPos;
    emit exitReached(m_currentLevel + 1);
    return true;
}

bool LevelManager::consumeAmmoTile(float x, float z)
{
    float radius = 85.0f;
    for (float dx = -radius; dx <= radius; dx += 42.0f) {
        for (float dz = -radius; dz <= radius; dz += 42.0f) {
            int col = qFloor((x + dx) / GameConfig::BLOCK_SIZE);
            int row = qFloor((z + dz) / GameConfig::BLOCK_SIZE);
            if (row < 0 || row >= mapHeight() || col < 0 || col >= mapWidth()) continue;

            if (getTile(row, col) == TileCode::AmmoPickup) {
                int key = row * mapWidth() + col;
                if (!m_consumedAmmoTiles.contains(key)) {
                    m_consumedAmmoTiles.insert(key);
                    QVector3D tilePos((col + 0.5f) * GameConfig::BLOCK_SIZE, 0.0f, (row + 0.5f) * GameConfig::BLOCK_SIZE);
                    emit ammoTileCollected(tilePos);
                    qDebug() << "[LevelManager] Ammo pickup tile collected at (" << row << "," << col << ")";
                    return true;
                }
            }
        }
    }
    return false;
}

bool LevelManager::isAmmoTileConsumed(int row, int col) const
{
    int key = row * mapWidth() + col;
    return m_consumedAmmoTiles.contains(key);
}

bool LevelManager::isInLoadingBay(float x, float z) const
{
    if (m_currentLevel != 1) return false;

    int col = qFloor(x / GameConfig::BLOCK_SIZE);
    int row = qFloor(z / GameConfig::BLOCK_SIZE);

    // Level 1 Loading Bay is at rows 7 to 15, cols 17 to 26
    return (row >= 7 && row <= 15 && col >= 17 && col <= 26);
}

bool LevelManager::triggerLoadingBay()
{
    if (m_loadingBayTriggered) return false;
    m_loadingBayTriggered = true;
    emit loadingBayTriggeredChanged();
    qDebug() << "[LevelManager] Level 1 Loading Bay combat encounter triggered!";
    return true;
}

int LevelManager::corridorDroneSpawnCount() const
{
    if (m_currentLevel == 1) {
        return LevelData::getLevel1CorridorDroneSpawns().size();
    }
    return 1;
}

QVector3D LevelManager::corridorDroneSpawn(int index) const
{
    if (m_currentLevel == 1) {
        auto list = LevelData::getLevel1CorridorDroneSpawns();
        if (index >= 0 && index < list.size()) {
            return list[index];
        }
    }
    return QVector3D(850.0f, 0.0f, 550.0f);
}

int LevelManager::loadingBayDroneSpawnCount() const
{
    if (m_currentLevel == 1) {
        return LevelData::getLevel1LoadingBayDroneSpawns().size();
    }
    return 0;
}

QVector3D LevelManager::loadingBayDroneSpawn(int index) const
{
    if (m_currentLevel == 1) {
        auto list = LevelData::getLevel1LoadingBayDroneSpawns();
        if (index >= 0 && index < list.size()) {
            return list[index];
        }
    }
    return QVector3D(2150.0f, 0.0f, 1050.0f);
}

bool LevelManager::isHeavyWeaponCollected() const
{
    return m_heavyWeaponCollected;
}

QVector3D LevelManager::heavyWeaponSpawnPosition() const
{
    return LevelData::getLevel2HeavyWeaponSpawn();
}

bool LevelManager::consumeHeavyWeaponTile(float x, float z)
{
    if (m_currentLevel != 2 || m_heavyWeaponCollected) {
        return false;
    }

    int col = qFloor(x / GameConfig::BLOCK_SIZE);
    int row = qFloor(z / GameConfig::BLOCK_SIZE);

    for (int dr = -1; dr <= 1; ++dr) {
        for (int dc = -1; dc <= 1; ++dc) {
            int tile = getTile(row + dr, col + dc);
            if (tile == TileCode::HeavyWeaponPickup) {
                m_heavyWeaponCollected = true;
                emit heavyWeaponCollectedChanged();
                emit heavyWeaponCollected();
                qDebug() << "[LevelManager] Heavy Weapon (Plasma Repeater) collected at (" << (row + dr) << "," << (col + dc) << ")!";
                return true;
            }
        }
    }

    return false;
}

bool LevelManager::checkTriggerTrap(const QVector3D &playerPos, float playerYaw)
{
    if (m_currentLevel != 2) {
        return false;
    }

    int col = qFloor(playerPos.x() / GameConfig::BLOCK_SIZE);
    int row = qFloor(playerPos.z() / GameConfig::BLOCK_SIZE);

    int tile = getTile(row, col);
    if (tile != TileCode::TriggerTrap) {
        return false;
    }

    int key = row * mapWidth() + col;
    if (m_triggeredTraps.contains(key)) {
        return false;
    }

    m_triggeredTraps.insert(key);
    qDebug() << "[LevelManager] Trap triggered at tile (" << row << "," << col << ")! Searching spawn behind player...";

    // Behind player = opposite of camera forward vector
    float yawRad = qDegreesToRadians(playerYaw);
    QVector3D backVec(-qSin(yawRad), 0.0f, qCos(yawRad));

    const int testDists[5] = {10, 11, 12, 9, 8};
    QVector3D spawnPos;
    bool found = false;

    for (int d : testDists) {
        float testX = playerPos.x() + backVec.x() * (d * GameConfig::BLOCK_SIZE);
        float testZ = playerPos.z() + backVec.z() * (d * GameConfig::BLOCK_SIZE);
        int tCol = qFloor(testX / GameConfig::BLOCK_SIZE);
        int tRow = qFloor(testZ / GameConfig::BLOCK_SIZE);

        if (tRow >= 0 && tRow < mapHeight() && tCol >= 0 && tCol < mapWidth()) {
            if (!isSolidTile(tRow, tCol)) {
                spawnPos = QVector3D((tCol + 0.5f) * GameConfig::BLOCK_SIZE, 0.0f, (tRow + 0.5f) * GameConfig::BLOCK_SIZE);
                found = true;
                break;
            }
        }
    }

    if (!found) {
        float testX = playerPos.x() + backVec.x() * (8 * GameConfig::BLOCK_SIZE);
        float testZ = playerPos.z() + backVec.z() * (8 * GameConfig::BLOCK_SIZE);
        int baseCol = qFloor(testX / GameConfig::BLOCK_SIZE);
        int baseRow = qFloor(testZ / GameConfig::BLOCK_SIZE);

        for (int dr = -2; dr <= 2 && !found; ++dr) {
            for (int dc = -2; dc <= 2 && !found; ++dc) {
                int r = baseRow + dr;
                int c = baseCol + dc;
                if (r >= 0 && r < mapHeight() && c >= 0 && c < mapWidth()) {
                    if (!isSolidTile(r, c)) {
                        spawnPos = QVector3D((c + 0.5f) * GameConfig::BLOCK_SIZE, 0.0f, (r + 0.5f) * GameConfig::BLOCK_SIZE);
                        found = true;
                    }
                }
            }
        }
    }

    if (found) {
        // Alternate between Sentinel (1) and Drone (0)
        int enemyType = (m_triggeredTraps.size() % 2 == 1) ? 1 : 0;
        qDebug() << "[LevelManager] Trap ambusher spawned at" << spawnPos << "type:" << (enemyType == 1 ? "Sentinel" : "Drone");
        emit trapTriggered(spawnPos, enemyType);
        return true;
    }

    return false;
}

int LevelManager::sentinelSpawnCount() const
{
    if (m_currentLevel == 2) {
        return LevelData::getLevel2SentinelSpawns().size();
    }
    return 0;
}

QVector3D LevelManager::sentinelSpawn(int index) const
{
    if (m_currentLevel == 2) {
        auto list = LevelData::getLevel2SentinelSpawns();
        if (index >= 0 && index < list.size()) {
            return list[index];
        }
    }
    return QVector3D(0.0f, 0.0f, 0.0f);
}

int LevelManager::droneSpawnCount() const
{
    if (m_currentLevel == 2) {
        return LevelData::getLevel2DroneSpawns().size();
    }
    return 0;
}

QVector3D LevelManager::droneSpawn(int index) const
{
    if (m_currentLevel == 2) {
        auto list = LevelData::getLevel2DroneSpawns();
        if (index >= 0 && index < list.size()) {
            return list[index];
        }
    }
    return QVector3D(0.0f, 0.0f, 0.0f);
}

// ==================== DOOR SYSTEM (DAY 1) ====================

QVariantList LevelManager::doors() const
{
    QVariantList list;
    list.reserve(m_doors.size());
    for (Door *door : m_doors) {
        list.append(QVariant::fromValue(door));
    }
    return list;
}

Door* LevelManager::targetDoor() const
{
    return m_targetDoor.data();
}

QString LevelManager::interactionPrompt() const
{
    return m_interactionPrompt;
}

int LevelManager::doorCount() const
{
    return m_doors.size();
}

Door* LevelManager::doorAt(int index) const
{
    if (index >= 0 && index < m_doors.size()) {
        return m_doors[index];
    }
    return nullptr;
}

Door* LevelManager::doorAtTile(int row, int col) const
{
    if (row < 0 || row >= mapHeight() || col < 0 || col >= mapWidth()) {
        return nullptr;
    }
    int key = row * mapWidth() + col;
    return m_doorTileLookup.value(key, nullptr);
}

Door* LevelManager::addDoor(int row,
                            int col,
                            float axis,
                            int doorType,
                            int requiredKeyIndex,
                            int requiredKeyCount,
                            int requiredKeyMask,
                            bool requiresBossDefeated,
                            const QString &label)
{
    if (row < 0 || row >= mapHeight() || col < 0 || col >= mapWidth()) {
        qWarning() << "[LevelManager] Ignoring out-of-bounds door at (" << row << "," << col << ")";
        return nullptr;
    }

    int tileKey = row * mapWidth() + col;
    if (m_doorTileLookup.contains(tileKey)) {
        return m_doorTileLookup.value(tileKey);
    }

    Door *door = new Door(this);
    int id = m_doors.size() + 1;
    Door::DoorType typeEnum = static_cast<Door::DoorType>(qBound(0, doorType, 3));
    door->configure(id,
                    row,
                    col,
                    axis,
                    typeEnum,
                    requiredKeyIndex,
                    requiredKeyCount,
                    requiredKeyMask,
                    requiresBossDefeated,
                    label);

    connect(door, &Door::doorAnimationStarted, this, [this](bool opening) {
        Q_UNUSED(opening);
        emit doorTriggered();
    });

    connect(door, &Door::doorObstructed, this, [this](bool midCloseReversal) {
        if (midCloseReversal) {
            emit doorInteractionFeedback(QStringLiteral("DOOR OBSTRUCTED — REOPENING"), QStringLiteral("#e67e22"));
        }
    });

    m_doors.append(door);
    m_doorTileLookup.insert(tileKey, door);
    emit doorsChanged();
    return door;
}

void LevelManager::clearDoors()
{
    if (!m_targetDoor.isNull()) {
        m_targetDoor.clear();
        emit targetDoorChanged();
    }
    if (!m_interactionPrompt.isEmpty()) {
        m_interactionPrompt.clear();
        emit interactionPromptChanged();
    }

    m_doorTileLookup.clear();
    if (!m_doors.isEmpty()) {
        QList<Door*> oldDoors = m_doors;
        m_doors.clear();
        for (Door *door : oldDoors) {
            if (door) {
                door->deleteLater();
            }
        }
        emit doorsChanged();
    }
}

void LevelManager::rebuildDoorsForLevel(int level)
{
    clearDoors();

    const QList<DoorDef> defs = LevelData::getLevelDoors(level);
    for (const DoorDef &def : defs) {
        Door *door = addDoor(def.row,
                             def.col,
                             def.axis,
                             def.doorType,
                             def.requiredKeyIndex,
                             def.requiredKeyCount,
                             def.requiredKeyMask,
                             def.requiresBossDefeated,
                             def.label);
        if (door) {
            Q_UNUSED(door);
        }
    }
}

bool LevelManager::isDoorTileObstructed(const Door *door,
                                        const QVector3D &playerPos,
                                        EnemyManager *enemyManager) const
{
    if (!door || door->row() < 0 || door->col() < 0) {
        return false;
    }

    const float bs = GameConfig::BLOCK_SIZE;
    const float bMinX = door->col() * bs;
    const float bMaxX = (door->col() + 1) * bs;
    const float bMinZ = door->row() * bs;
    const float bMaxZ = (door->row() + 1) * bs;

    // Entity radius (35.0) + small buffer (4.0) keeps entities clear of the closing door leaf plane
    const float checkRadius = 39.0f;
    const float checkRadiusSq = checkRadius * checkRadius;

    auto overlapsDoor = [&](const QVector3D &pos) -> bool {
        float cX = std::clamp(pos.x(), bMinX, bMaxX);
        float cZ = std::clamp(pos.z(), bMinZ, bMaxZ);
        float dx = pos.x() - cX;
        float dz = pos.z() - cZ;
        return (dx * dx + dz * dz) < checkRadiusSq;
    };

    if (overlapsDoor(playerPos)) {
        return true;
    }

    if (enemyManager) {
        int count = enemyManager->poolSize();
        for (int i = 0; i < count; ++i) {
            Enemy *enemy = enemyManager->enemyAt(i);
            if (enemy && enemy->isActive() && !enemy->isDead()) {
                if (overlapsDoor(enemy->position())) {
                    return true;
                }
            }
        }
    }

    return false;
}

bool LevelManager::isRayOccludedBefore(const QVector3D &origin,
                                       const QVector3D &normDir,
                                       float targetDist,
                                       CollisionSystem *collisionSystem) const
{
    Q_UNUSED(collisionSystem);
    if (normDir.isNull() || targetDist <= 0.5f) {
        return false;
    }

    const float maxCheckDist = targetDist - 0.5f;
    const float bs = GameConfig::BLOCK_SIZE;
    const int mapW = mapWidth();
    const int mapH = mapHeight();
    const float wallHeight = (m_currentLevel == 3) ? (GameConfig::WALL_HEIGHT * 2.0f) : GameConfig::WALL_HEIGHT;

    int col = qFloor(origin.x() / bs);
    int row = qFloor(origin.z() / bs);

    const int stepX = (normDir.x() >= 0.0f) ? 1 : -1;
    const int stepZ = (normDir.z() >= 0.0f) ? 1 : -1;

    const float dx = normDir.x();
    const float dz = normDir.z();
    const float tDeltaX = (std::abs(dx) > 1e-6f) ? std::abs(bs / dx) : 1e9f;
    const float tDeltaZ = (std::abs(dz) > 1e-6f) ? std::abs(bs / dz) : 1e9f;

    const float nextBoundaryX = (stepX > 0) ? (col + 1) * bs : col * bs;
    const float nextBoundaryZ = (stepZ > 0) ? (row + 1) * bs : row * bs;
    float tMaxX = (std::abs(dx) > 1e-6f) ? (nextBoundaryX - origin.x()) / dx : 1e9f;
    float tMaxZ = (std::abs(dz) > 1e-6f) ? (nextBoundaryZ - origin.z()) / dz : 1e9f;

    auto cellOccludesInSegment = [&](int r, int c, float tEnter, float tExit) -> bool {
        if (r < 0 || r >= mapH || c < 0 || c >= mapW) {
            return false;
        }
        int tile = getTile(r, c);
        if (tile != TileCode::Wall && tile != TileCode::Crate &&
            tile != TileCode::CoreWall && tile != TileCode::DoorPocket) {
            return false;
        }
        float yEnter = origin.y() + normDir.y() * tEnter;
        float yExit = origin.y() + normDir.y() * tExit;
        float minY = std::min(yEnter, yExit);
        float maxY = std::max(yEnter, yExit);
        float heightLimit = (tile == TileCode::Crate) ? GameConfig::CRATE_HEIGHT : wallHeight;
        // Ray segment intersects vertical volume [0, heightLimit]
        return (minY <= heightLimit && maxY >= 0.0f);
    };

    float t = 0.0f;
    float firstExit = std::min({tMaxX, tMaxZ, maxCheckDist});
    if (cellOccludesInSegment(row, col, t, firstExit)) {
        return true;
    }

    while (true) {
        if (tMaxX < tMaxZ) {
            t = tMaxX;
            tMaxX += tDeltaX;
            col += stepX;
        } else {
            t = tMaxZ;
            tMaxZ += tDeltaZ;
            row += stepZ;
        }

        if (t >= maxCheckDist || col < 0 || col >= mapW || row < 0 || row >= mapH) {
            break;
        }

        float tExit = std::min({tMaxX, tMaxZ, maxCheckDist});
        if (cellOccludesInSegment(row, col, t, tExit)) {
            return true;
        }
    }

    return false;
}

Door* LevelManager::findTargetDoor(const QVector3D &cameraPos,
                                   const QVector3D &lookDir,
                                   CollisionSystem *collisionSystem) const
{
    if (m_doors.isEmpty()) {
        return nullptr;
    }

    QVector3D normDir = lookDir.normalized();
    if (normDir.isNull()) {
        return nullptr;
    }

    const float maxInteractionDist = 175.0f;
    const float bs = GameConfig::BLOCK_SIZE;

    Door *bestDoor = nullptr;
    float bestDist = maxInteractionDist + 1.0f;

    for (Door *door : m_doors) {
        if (!door || door->row() < 0 || door->col() < 0) {
            continue;
        }

        QVector3D bMin(door->col() * bs, 0.0f, door->row() * bs);
        QVector3D bMax((door->col() + 1) * bs, GameConfig::WALL_HEIGHT, (door->row() + 1) * bs);

        // Slab ray-vs-AABB intersection against full doorway aperture
        float tMin = 0.0f;
        float tMax = maxInteractionDist;
        bool miss = false;

        for (int axisIdx = 0; axisIdx < 3; ++axisIdx) {
            float origComp = (axisIdx == 0) ? cameraPos.x() : ((axisIdx == 1) ? cameraPos.y() : cameraPos.z());
            float dirComp  = (axisIdx == 0) ? normDir.x()   : ((axisIdx == 1) ? normDir.y()   : normDir.z());
            float minB     = (axisIdx == 0) ? bMin.x()      : ((axisIdx == 1) ? bMin.y()      : bMin.z());
            float maxB     = (axisIdx == 0) ? bMax.x()      : ((axisIdx == 1) ? bMax.y()      : bMax.z());

            if (std::abs(dirComp) < 1e-6f) {
                if (origComp < minB || origComp > maxB) {
                    miss = true;
                    break;
                }
            } else {
                float invD = 1.0f / dirComp;
                float t1 = (minB - origComp) * invD;
                float t2 = (maxB - origComp) * invD;
                if (t1 > t2) std::swap(t1, t2);
                tMin = std::max(tMin, t1);
                tMax = std::min(tMax, t2);
                if (tMin > tMax) {
                    miss = true;
                    break;
                }
            }
        }

        if (miss || tMax < 0.0f) {
            continue;
        }

        float hitDist = std::max(0.0f, tMin);
        if (hitDist > maxInteractionDist || hitDist >= bestDist) {
            continue;
        }

        if (isRayOccludedBefore(cameraPos, normDir, hitDist, collisionSystem)) {
            continue;
        }

        bestDist = hitDist;
        bestDoor = door;
    }

    return bestDoor;
}

bool LevelManager::evaluateDoorAccess(const Door *door, QString &outDenyReason) const
{
    outDenyReason.clear();
    if (!door) {
        return false;
    }

    const int count = collectedKeysCount();
    const int mask = collectedKeysMask();

    switch (door->doorType()) {
    case Door::DoorType::Standard:
        return true;

    case Door::DoorType::KeyLocked: {
        const int reqIdx = door->requiredKeyIndex();
        const int reqMask = door->requiredKeyMask();
        const int reqCount = door->requiredKeyCount();

        if (reqIdx >= 0 && reqIdx < 4 && !hasKey(reqIdx)) {
            outDenyReason = QStringLiteral("[LOCKED] NEED ACCESS KEY %1 (%2/4)").arg(reqIdx + 1).arg(count);
            return false;
        }
        if (reqMask != 0 && (mask & reqMask) != reqMask) {
            outDenyReason = QStringLiteral("[LOCKED] MISSING REQUIRED ACCESS KEY (%1/4)").arg(count);
            return false;
        }
        if (reqCount > 0 && count < reqCount) {
            outDenyReason = QStringLiteral("[LOCKED] NEED %1 ACCESS KEYS (%2/%1)").arg(reqCount).arg(count);
            return false;
        }
        return true;
    }

    case Door::DoorType::AreaLocked: {
        const int reqMask = door->requiredKeyMask();
        const int reqCount = (door->requiredKeyCount() > 0) ? door->requiredKeyCount() : ((reqMask != 0) ? popcount4(reqMask) : 4);
        if (reqMask != 0 && (mask & reqMask) != reqMask) {
            outDenyReason = QStringLiteral("[LOCKED] NEED %1 ACCESS KEYS (%2/%1)").arg(reqCount).arg(count);
            return false;
        }
        if (count < reqCount) {
            outDenyReason = QStringLiteral("[LOCKED] NEED %1 ACCESS KEYS (%2/%1)").arg(reqCount).arg(count);
            return false;
        }
        return true;
    }

    case Door::DoorType::MainExit: {
        const int reqKeys = (door->requiredKeyCount() > 0) ? door->requiredKeyCount() : 4;
        const int reqMask = door->requiredKeyMask();
        const bool keysSatisfied = (count >= reqKeys) && (reqMask == 0 || (mask & reqMask) == reqMask);
        const bool bossRequired = door->requiresBossDefeated() || (m_currentLevel == 3);
        const bool bossSatisfied = !bossRequired || (m_bossCompleted && m_activeVentsRemaining == 0);

        if (!keysSatisfied && !bossSatisfied) {
            outDenyReason = QStringLiteral("[LOCKED] NEED %1 ACCESS KEYS (%2/%1) & DESTROY VENTS (%3/4 REMAINING)")
                                .arg(reqKeys)
                                .arg(count)
                                .arg(m_activeVentsRemaining);
            return false;
        }
        if (!keysSatisfied) {
            outDenyReason = QStringLiteral("[LOCKED] NEED %1 ACCESS KEYS (%2/%1)").arg(reqKeys).arg(count);
            return false;
        }
        if (!bossSatisfied) {
            outDenyReason = QStringLiteral("[LOCKED] DESTROY COOLING VENTS (%1/4 REMAINING)").arg(m_activeVentsRemaining);
            return false;
        }
        return true;
    }
    }

    return false;
}

QString LevelManager::buildDoorPrompt(const Door *door,
                                      const QVector3D &playerPos,
                                      EnemyManager *enemyManager) const
{
    if (!door) {
        return QString();
    }

    switch (door->doorState()) {
    case Door::DoorState::Locked: {
        QString denyReason;
        if (!evaluateDoorAccess(door, denyReason)) {
            return denyReason;
        }
        if (door->doorType() == Door::DoorType::MainExit) {
            return (door->requiresBossDefeated() || m_currentLevel == 3)
                ? QStringLiteral("EXTRACTION AVAILABLE — PRESS E")
                : QStringLiteral("[E] UNLOCK EXIT DOOR");
        }
        return QStringLiteral("[E] UNLOCK DOOR");
    }
    case Door::DoorState::Closed:
        return (door->doorType() == Door::DoorType::MainExit)
            ? QStringLiteral("[E] OPEN EXIT DOOR")
            : QStringLiteral("[E] OPEN DOOR");
    case Door::DoorState::Open:
        return isDoorTileObstructed(door, playerPos, enemyManager)
            ? QStringLiteral("DOOR OBSTRUCTED")
            : QStringLiteral("[E] CLOSE DOOR");
    case Door::DoorState::Opening:
    case Door::DoorState::Closing:
        return QString();
    }
    return QString();
}

void LevelManager::updateInteractionPrompt(const QVector3D &playerPos, EnemyManager *enemyManager)
{
    QString nextPrompt = buildDoorPrompt(m_targetDoor.data(), playerPos, enemyManager);
    if (m_interactionPrompt != nextPrompt) {
        m_interactionPrompt = nextPrompt;
        emit interactionPromptChanged();
    }
}

void LevelManager::updateDoors(float deltaTime,
                               const QVector3D &playerPos,
                               const QVector3D &cameraPos,
                               const QVector3D &lookDir,
                               CollisionSystem *collisionSystem,
                               EnemyManager *enemyManager,
                               bool playerAlive)
{
    for (Door *door : m_doors) {
        if (door) {
            bool checkEntityOverlap = (door->doorState() == Door::DoorState::Closing ||
                                       door->doorState() == Door::DoorState::Opening);
            bool obstructed = checkEntityOverlap
                ? isDoorTileObstructed(door, playerPos, enemyManager)
                : false;
            door->update(deltaTime, obstructed);
        }
    }

    Door *found = playerAlive ? findTargetDoor(cameraPos, lookDir, collisionSystem) : nullptr;
    if (m_targetDoor.data() != found) {
        m_targetDoor = found;
        emit targetDoorChanged();
    }

    updateInteractionPrompt(playerPos, enemyManager);
}

bool LevelManager::interactWithTargetDoor(const QVector3D &playerPos,
                                          EnemyManager *enemyManager,
                                          bool playerAlive)
{
    if (!playerAlive) {
        return false;
    }

    Door *door = m_targetDoor.data();
    if (!door) {
        return false;
    }

    // Prevent mid-animation conflicting inputs
    if (door->doorState() == Door::DoorState::Opening ||
        door->doorState() == Door::DoorState::Closing) {
        return false;
    }

    if (door->doorState() == Door::DoorState::Locked) {
        QString denyReason;
        bool accessGranted = evaluateDoorAccess(door, denyReason);
        if (!accessGranted) {
            bool ok = door->interact(false, denyReason, false);
            Q_UNUSED(ok);
            emit doorInteractionFeedback(denyReason, QStringLiteral("#e74c3c"));
            updateInteractionPrompt(playerPos, enemyManager);
            return false;
        }
        bool opened = door->interact(true, QString(), false);
        if (opened) {
            QString unlockedMsg = (door->doorType() == Door::DoorType::MainExit)
                ? QStringLiteral("EXIT UNLOCKED — PROCEED TO EXTRACTION")
                : QStringLiteral("ACCESS GRANTED — DOOR UNLOCKED");
            emit doorInteractionFeedback(unlockedMsg, QStringLiteral("#2ecc71"));
        }
        updateInteractionPrompt(playerPos, enemyManager);
        return opened;
    }

    if (door->doorState() == Door::DoorState::Open) {
        bool obstructed = isDoorTileObstructed(door, playerPos, enemyManager);
        if (obstructed) {
            door->interact(true, QString(), true);
            emit doorInteractionFeedback(QStringLiteral("DOOR OBSTRUCTED — CLEAR DOORWAY"), QStringLiteral("#e67e22"));
            updateInteractionPrompt(playerPos, enemyManager);
            return false;
        }
        bool closing = door->interact(true, QString(), false);
        updateInteractionPrompt(playerPos, enemyManager);
        return closing;
    }

    // Closed -> Opening
    bool opening = door->interact(true, QString(), false);
    updateInteractionPrompt(playerPos, enemyManager);
    return opening;
}

// ==================== MISSION KEY PROGRESSION SYSTEM (DAY 2) ====================

int LevelManager::popcount4(int mask) const
{
    int clamped = mask & 0xF;
    int count = 0;
    for (int bit = 0; bit < 4; ++bit) {
        if ((clamped & (1 << bit)) != 0) {
            ++count;
        }
    }
    return count;
}

int LevelManager::collectedKeysMaskForLevel(int level) const
{
    int idx = qBound(1, level, m_maxLevels);
    return m_keyMasks[static_cast<size_t>(idx)] & 0xF;
}

int LevelManager::collectedKeysCountForLevel(int level) const
{
    return popcount4(collectedKeysMaskForLevel(level));
}

int LevelManager::collectedKeysMask() const
{
    if (m_currentLevel < 1 || m_currentLevel > m_maxLevels) {
        return 0;
    }
    return collectedKeysMaskForLevel(m_currentLevel);
}

int LevelManager::collectedKeysCount() const
{
    if (m_currentLevel < 1 || m_currentLevel > m_maxLevels) {
        return 0;
    }
    return collectedKeysCountForLevel(m_currentLevel);
}

int LevelManager::totalKeysRequired() const
{
    return 4;
}

QVariantList LevelManager::levelKeys() const
{
    QVariantList list;
    list.reserve(m_levelKeys.size());
    for (AccessKeyPickup *key : m_levelKeys) {
        list.append(QVariant::fromValue(key));
    }
    return list;
}

BossArena* LevelManager::bossArena() const
{
    return m_bossArena.data();
}

void LevelManager::setBossArena(BossArena *arena)
{
    if (m_bossArena.data() == arena) {
        return;
    }

    if (m_ventsConn) {
        disconnect(m_ventsConn);
    }
    if (m_bossConn) {
        disconnect(m_bossConn);
    }

    m_bossArena = arena;
    if (arena) {
        m_ventsConn = connect(arena, &BossArena::ventsCountChanged, this, [this](int activeCount) {
            bool defeated = m_bossArena ? m_bossArena->isBossDefeated() : m_bossCompleted;
            setBossProgress(activeCount, defeated);
        });
        m_bossConn = connect(arena, &BossArena::bossDefeatedChanged, this, [this](bool defeated) {
            int activeCount = m_bossArena ? m_bossArena->activeVentsCount() : m_activeVentsRemaining;
            setBossProgress(activeCount, defeated);
        });
        setBossProgress(arena->activeVentsCount(), arena->isBossDefeated());
    }

    emit bossArenaChanged();
}

bool LevelManager::isBossCompleted() const
{
    return m_bossCompleted;
}

int LevelManager::activeVentsRemaining() const
{
    return m_activeVentsRemaining;
}

bool LevelManager::isExtractionAvailable() const
{
    if (!hasAllKeys()) {
        return false;
    }
    if (m_currentLevel == 3) {
        return m_bossCompleted && (m_activeVentsRemaining == 0);
    }
    return true;
}

void LevelManager::setBossProgress(int activeVentsRemaining, bool bossCompleted)
{
    int clampedVents = qBound(0, activeVentsRemaining, 4);
    if (m_activeVentsRemaining == clampedVents && m_bossCompleted == bossCompleted) {
        return;
    }
    m_activeVentsRemaining = clampedVents;
    m_bossCompleted = bossCompleted;

    // Immediately refresh HUD locked door prompt if targeting an extraction/exit door
    if (m_targetDoor && m_targetDoor->doorState() == Door::DoorState::Locked) {
        updateInteractionPrompt(QVector3D(), nullptr);
    }
    emit missionProgressChanged();
}

bool LevelManager::hasKey(int keyIndex, int level) const
{
    if (keyIndex < 0 || keyIndex >= 4) {
        return false;
    }
    int targetLevel = (level > 0) ? level : m_currentLevel;
    if (targetLevel < 1 || targetLevel > m_maxLevels) {
        return false;
    }
    return (collectedKeysMaskForLevel(targetLevel) & (1 << keyIndex)) != 0;
}

bool LevelManager::hasAllKeys(int level) const
{
    int targetLevel = (level > 0) ? level : m_currentLevel;
    if (targetLevel < 1 || targetLevel > m_maxLevels) {
        return false;
    }
    return collectedKeysCountForLevel(targetLevel) >= 4;
}

bool LevelManager::collectKey(int keyIndex, bool playerAlive)
{
    if (!playerAlive || m_currentLevel < 1 || m_currentLevel > m_maxLevels) {
        return false;
    }
    if (keyIndex < 0 || keyIndex >= 4) {
        return false;
    }

    int &mask = m_keyMasks[static_cast<size_t>(m_currentLevel)];
    const int bit = (1 << keyIndex);
    if ((mask & bit) != 0) {
        // Idempotent guard: already collected on this level
        return false;
    }

    mask |= bit;
    syncKeysFromMask();

    QString label = QStringLiteral("ACCESS KEY %1").arg(keyIndex + 1);
    for (const AccessKeyPickup *pickup : m_levelKeys) {
        if (pickup && pickup->keyIndex() == keyIndex && !pickup->keyName().isEmpty()) {
            label = pickup->keyName();
            break;
        }
    }

    const int count = popcount4(mask);
    qDebug() << "[LevelManager] Collected" << label << "on Level" << m_currentLevel
             << "-> Progress:" << count << "/ 4 (mask=" << mask << ")";

    if (m_targetDoor && m_targetDoor->doorState() == Door::DoorState::Locked) {
        updateInteractionPrompt(QVector3D(), nullptr);
    }

    emit keyCollected(keyIndex, label, count, 4);
    emit missionKeysChanged(m_currentLevel, count, mask);
    emit missionProgressChanged();
    return true;
}

void LevelManager::resetCurrentLevelKeys()
{
    resetMissionKeys(m_currentLevel);
}

void LevelManager::resetMissionKeys(int level)
{
    if (level <= 0) {
        resetAllCampaignKeys();
        return;
    }
    if (level > m_maxLevels) {
        return;
    }

    m_keyMasks[static_cast<size_t>(level)] = 0;
    if (level == m_currentLevel) {
        syncKeysFromMask();
        if (m_targetDoor && m_targetDoor->doorState() == Door::DoorState::Locked) {
            updateInteractionPrompt(QVector3D(), nullptr);
        }
        emit missionKeysChanged(m_currentLevel, 0, 0);
        emit missionProgressChanged();
    }
}

void LevelManager::resetAllCampaignKeys()
{
    m_keyMasks.fill(0);
    syncKeysFromMask();
    if (m_targetDoor && m_targetDoor->doorState() == Door::DoorState::Locked) {
        updateInteractionPrompt(QVector3D(), nullptr);
    }
    emit missionKeysChanged(m_currentLevel, collectedKeysCount(), collectedKeysMask());
    emit missionProgressChanged();
}

AccessKeyPickup* LevelManager::addKey(int row, int col, int keyIndex, const QString &name)
{
    if (row < 0 || row >= mapHeight() || col < 0 || col >= mapWidth()) {
        qWarning() << "[LevelManager] Ignoring out-of-bounds key at (" << row << "," << col << ")";
        return nullptr;
    }
    if (keyIndex < 0 || keyIndex >= 4) {
        qWarning() << "[LevelManager] Ignoring invalid keyIndex:" << keyIndex;
        return nullptr;
    }

    const float bs = GameConfig::BLOCK_SIZE;
    QVector3D pos((col + 0.5f) * bs, 35.0f, (row + 0.5f) * bs);

    AccessKeyPickup *pickup = new AccessKeyPickup(this);
    pickup->configure(m_currentLevel, keyIndex, pos, name);
    pickup->setCollected(hasKey(keyIndex));
    m_levelKeys.append(pickup);

    emit levelKeysChanged();
    return pickup;
}

void LevelManager::clearKeys()
{
    if (!m_levelKeys.isEmpty()) {
        QList<AccessKeyPickup*> oldKeys = m_levelKeys;
        m_levelKeys.clear();
        for (AccessKeyPickup *k : oldKeys) {
            if (k) {
                k->deleteLater();
            }
        }
        emit levelKeysChanged();
    }
}

void LevelManager::rebuildKeysForLevel(int level)
{
    clearKeys();

    const QList<KeyDef> defs = LevelData::getLevelKeys(level);
    for (const KeyDef &def : defs) {
        addKey(def.row, def.col, def.keyIndex, def.name);
    }
    syncKeysFromMask();
}

void LevelManager::syncKeysFromMask()
{
    for (AccessKeyPickup *pickup : m_levelKeys) {
        if (pickup) {
            pickup->setCollected(hasKey(pickup->keyIndex()));
        }
    }
}

void LevelManager::updateKeys(float deltaTime, const QVector3D &playerPos, bool playerAlive)
{
    for (AccessKeyPickup *pickup : m_levelKeys) {
        if (!pickup) {
            continue;
        }
        pickup->update(deltaTime);
        if (playerAlive && pickup->isPlayerInRange(playerPos, playerAlive)) {
            collectKey(pickup->keyIndex(), playerAlive);
        }
    }
}
