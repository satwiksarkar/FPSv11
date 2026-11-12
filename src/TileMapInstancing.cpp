#include "TileMapInstancing.h"
#include "GameConfig.h"
#include <QDebug>

TileMapInstancing::TileMapInstancing(QQuick3DObject *parent)
    : QQuick3DInstancing(parent)
    , m_levelManager(nullptr)
    , m_tileType(1)
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

QByteArray TileMapInstancing::getInstanceBuffer(int *instanceCount)
{
    if (!m_levelManager) {
        if (instanceCount) *instanceCount = 0;
        return QByteArray();
    }

    int mapWidth = m_levelManager->mapWidth();
    int mapHeight = m_levelManager->mapHeight();
    float blockSize = m_levelManager->blockSize();

    QVector<QQuick3DInstancing::InstanceTableEntry> entries;

    for (int row = 0; row < mapHeight; ++row) {
        for (int col = 0; col < mapWidth; ++col) {
            int t = m_levelManager->getTile(row, col);
            if (t == m_tileType) {
                if (m_tileType == 5 && m_levelManager->isAmmoTileConsumed(row, col)) {
                    continue; // Skip consumed ammo box
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
