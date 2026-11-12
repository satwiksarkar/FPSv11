#include "LevelManager.h"
#include "GameConfig.h"
#include <QtMath>
#include <QDebug>

LevelManager::LevelManager(QObject *parent)
    : QObject(parent)
    , m_currentLevel(1)
    , m_maxLevels(3)
    , m_exitTriggered(false)
    , m_loadingBayTriggered(false)
    , m_heavyWeaponCollected(false)
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

void LevelManager::loadLevel(int levelIndex)
{
    m_exitTriggered = false;
    m_loadingBayTriggered = false;
    m_consumedAmmoTiles.clear();
    m_triggeredTraps.clear();

    if (levelIndex == 1) {
        m_heavyWeaponCollected = false;
        emit heavyWeaponCollectedChanged();
    }

    if (levelIndex > m_maxLevels) {
        qDebug() << "[LevelManager] All campaign levels completed! Triggering campaign victory.";
        m_currentLevel = m_maxLevels + 1;
        emit currentLevelChanged(m_currentLevel);
        emit storyChanged();
        emit campaignWon();
        return;
    }

    m_currentLevel = qBound(1, levelIndex, m_maxLevels);
    qDebug() << "[LevelManager] Loaded Level" << m_currentLevel << ":" << currentLevelName();

    // ==================== BFS REACHABILITY CHECK AT LOAD TIME ====================
    QString reachabilityLog;
    bool isReachable = LevelData::checkReachability(m_currentLevel, reachabilityLog);
    if (!isReachable) {
        qWarning() << "[LevelManager] CRITICAL WARNING: Exit tile is NOT reachable from spawn!" << reachabilityLog;
    } else {
        qDebug() << "[LevelManager] Reachability verified:" << reachabilityLog;
    }

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

bool LevelManager::isSolidTile(int row, int col) const
{
    int tile = getTile(row, col);
    return (tile == TileCode::Wall || tile == TileCode::Crate || tile == TileCode::CoreWall);
}

bool LevelManager::checkExitReached(const QVector3D &playerPos)
{
    if (m_exitTriggered) {
        return false;
    }

    int exitTileCode = LevelData::getExitTileCode(m_currentLevel);
    if (exitTileCode <= 0) {
        return false;
    }

    int tileAtPlayer = getTileAtWorldPos(playerPos.x(), playerPos.z());
    if (tileAtPlayer == exitTileCode) {
        m_exitTriggered = true;
        qDebug() << "[LevelManager] Player entered exit tile" << exitTileCode << "at" << playerPos;
        emit exitReached(m_currentLevel + 1);
        return true;
    }

    return false;
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

    // Level 1 Loading Bay is at rows 6 to 15, cols 17 to 26
    return (row >= 6 && row <= 15 && col >= 17 && col <= 26);
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
