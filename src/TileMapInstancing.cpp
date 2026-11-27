#include "TileMapInstancing.h"
#include "GameConfig.h"
#include <QDebug>

TileMapInstancing::TileMapInstancing(QQuick3DObject *parent)
    : QQuick3DInstancing(parent)
    , m_levelManager(nullptr)
    , m_tileType(1)
    , m_wallMaterialType(0)
    , m_blockHeight(3)
    , m_baseColor(QColor(QStringLiteral("#ffffff")))
    , m_cachedInstanceCount(0)
{
}

LevelManager* TileMapInstancing::levelManager() const
{
    return m_levelManager;
}

void TileMapInstancing::setLevelManager(LevelManager *mgr)
{
    if (m_levelManager != mgr) {
        if (m_levelManager) {
            disconnect(m_levelManager, nullptr, this, nullptr);
        }
        m_levelManager = mgr;
        if (m_levelManager) {
            connect(m_levelManager, &LevelManager::levelLoaded, this, [this]() {
                markDirty();
            });
            connect(m_levelManager, &LevelManager::ammoTileCollected, this, [this]() {
                if (m_tileType == 5) {
                    markDirty();
                }
            });
        }
        emit levelManagerChanged();
        markDirty();
    }
}

int TileMapInstancing::tileType() const
{
    return m_tileType;
}

void TileMapInstancing::setTileType(int type)
{
    if (m_tileType != type) {
        m_tileType = type;
        emit tileTypeChanged();
        markDirty();
    }
}

int TileMapInstancing::wallMaterialType() const
{
    return m_wallMaterialType;
}

void TileMapInstancing::setWallMaterialType(int type)
{
    if (m_wallMaterialType != type) {
        m_wallMaterialType = type;
        emit wallMaterialTypeChanged();
        markDirty();
    }
}

int TileMapInstancing::blockHeight() const
{
    return m_blockHeight;
}

void TileMapInstancing::setBlockHeight(int height)
{
    int clamped = qMax(1, height);
    if (m_blockHeight != clamped) {
        m_blockHeight = clamped;
        emit blockHeightChanged();
        markDirty();
    }
}

QColor TileMapInstancing::baseColor() const
{
    return m_baseColor;
}

void TileMapInstancing::setBaseColor(const QColor &color)
{
    if (m_baseColor != color) {
        m_baseColor = color;
        emit baseColorChanged();
        markDirty();
    }
}

int TileMapInstancing::instanceCount() const
{
    return m_cachedInstanceCount;
}

static bool isCorridorOrSteelWall(int level, int row, int col)
{
    if (level == 3) {
        return true; // Level 3 is fully armored steel
    }
    if (level == 1) {
        // Central Spine
        if (col >= 21 && col <= 26 && row >= 13 && row <= 39) return true;
        // Spawn airlock & vestibule
        if (col >= 20 && col <= 27 && row >= 39 && row <= 47) return true;
        // Exit elevator vestibule
        if (col >= 20 && col <= 27 && row >= 1 && row <= 6) return true;
        // West outer bypass
        if (col >= 4 && col <= 9 && row >= 17 && row <= 25) return true;
        // East outer bypass
        if (col >= 40 && col <= 45 && row >= 17 && row <= 25) return true;
        // Connecting door junctions
        if (row >= 29 && row <= 33 && ((col >= 14 && col <= 17) || (col >= 31 && col <= 34))) return true;
        if (row >= 9 && row <= 13 && ((col >= 14 && col <= 17) || (col >= 31 && col <= 34))) return true;
        return false;
    }
    if (level == 2) {
        // Main corridors of Level 2
        if (col <= 7 && row >= 34 && row <= 58) return true; // West corridor
        if (row <= 16 && col >= 34 && col <= 52) return true; // North corridor
        if (col >= 53 && row >= 12 && row <= 50) return true; // East security corridor
        if (row >= 48 && row <= 54 && col >= 32 && col <= 55) return true; // Descent approach corridor
        if (row >= 58 && col <= 16) return true; // Cache approach
        if (row >= 58 && col >= 58) return true; // Spawn airlock
        return false;
    }
    return false;
}

QByteArray TileMapInstancing::getInstanceBuffer(int *instanceCount)
{
    if (!m_levelManager) {
        if (instanceCount) *instanceCount = 0;
        return QByteArray();
    }

    int mapWidth = m_levelManager->mapWidth();
    int mapHeight = m_levelManager->mapHeight();
    float blockSize = m_levelManager->blockSize();
    int curLevel = m_levelManager->currentLevel();

    QVector<QQuick3DInstancing::InstanceTableEntry> entries;

    for (int row = 0; row < mapHeight; ++row) {
        for (int col = 0; col < mapWidth; ++col) {
            int t = m_levelManager->getTile(row, col);
            if (t == m_tileType) {
                if (m_tileType == 5 && m_levelManager->isAmmoTileConsumed(row, col)) {
                    continue; // Skip consumed ammo box
                }

                // Wall material separation if tileType == 1 (Solid Walls)
                if (m_tileType == 1 && m_wallMaterialType != 0) {
                    bool steel = isCorridorOrSteelWall(curLevel, row, col);
                    if (m_wallMaterialType == 1) { // Steel Wall
                        if (!steel) continue;
                    } else if (m_wallMaterialType == 2) { // Stone Wall (bolted, alternating)
                        if (steel) continue;
                        if ((col + row * 2) % 3 == 0) continue; // Alternate to plain variant every 2-3 tiles
                    } else if (m_wallMaterialType == 3) { // Stone Wall Alt (plain un-riveted)
                        if (steel) continue;
                        if ((col + row * 2) % 3 != 0) continue; // Plain variant on every 3rd tile
                    }
                }

                for (int yLevel = 0; yLevel < m_blockHeight; ++yLevel) {
                    float x = (col + 0.5f) * blockSize;
                    float y = (yLevel + 0.5f) * blockSize;
                    float z = (row + 0.5f) * blockSize;

                    // Subtle deterministic color variation (±6%) across instances
                    float tint = 0.94f + ((col * 19 + row * 31 + yLevel * 17) % 13) * 0.01f;
                    QColor c = QColor::fromRgbF(
                        qBound(0.0f, m_baseColor.redF() * tint, 1.0f),
                        qBound(0.0f, m_baseColor.greenF() * tint, 1.0f),
                        qBound(0.0f, m_baseColor.blueF() * tint, 1.0f),
                        1.0f
                    );

                    entries.append(calculateTableEntry(
                        QVector3D(x, y, z),
                        QVector3D(1.0f, 1.0f, 1.0f),
                        QVector3D(0.0f, 0.0f, 0.0f),
                        c
                    ));
                }
            }
        }
    }

    int count = entries.size();
    if (instanceCount) {
        *instanceCount = count;
    }
    m_cachedInstanceCount = count;

    if (GameConfig::DEBUG_LOG_TILE_COUNTS) {
        qDebug() << "[TileMapInstancing] Built" << count << "instanced blocks for TileType"
                 << m_tileType << "Height:" << m_blockHeight << "on Level" << m_levelManager->currentLevel();
    }

    QByteArray buffer;
    buffer.resize(count * sizeof(QQuick3DInstancing::InstanceTableEntry));
    memcpy(buffer.data(), entries.constData(), buffer.size());
    return buffer;
}
