#include "BossArena.h"
#include "GameConfig.h"
#include <QDebug>

BossArena::BossArena(QObject *parent)
    : QObject(parent)
    , m_isBossDefeated(false)
    , m_spawnTimer(0.0f)
    , m_spawnIndex(0)
{
    initVents();
}

void BossArena::initVents()
{
    // Vent positions surrounding the 4x4 central core (rows 18-21, cols 18-21)
    // Outside each corner: (17,17), (22,17), (17,22), (22,22)
    float bs = GameConfig::BLOCK_SIZE;
    const QVector3D ventPositions[4] = {
        QVector3D((17.0f + 0.5f) * bs, 0.0f, (17.0f + 0.5f) * bs), // Top-Left (1750, 0, 1750)
        QVector3D((22.0f + 0.5f) * bs, 0.0f, (17.0f + 0.5f) * bs), // Top-Right (2250, 0, 1750)
        QVector3D((17.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs), // Bottom-Left (1750, 0, 2250)
        QVector3D((22.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs)  // Bottom-Right (2250, 0, 2250)
    };

    for (int i = 0; i < 4; ++i) {
        CoolingVent *vent = new CoolingVent(i, ventPositions[i], this);
        connect(vent, &CoolingVent::healthChanged, this, [this]() {
            emit ventHpChanged();
        });
        connect(vent, &CoolingVent::destroyed, this, [this, i]() {
            updateVentCount();
            emit ventDestroyed(i);
            emit ventHpChanged();
        });
        m_vents.append(vent);
    }
}

int BossArena::activeVentsCount() const
{
    int count = 0;
    for (const CoolingVent *v : m_vents) {
        if (!v->isDestroyed()) {
            count++;
        }
    }
    return count;
}

int BossArena::totalVents() const
{
    return 4;
}

bool BossArena::isBossDefeated() const
{
    return m_isBossDefeated;
}

QVector3D BossArena::coreCenterPosition() const
{
    return QVector3D(2000.0f, 200.0f, 2000.0f);
}

int BossArena::totalVentHp() const
{
    int total = 0;
    for (const CoolingVent *v : m_vents) {
        if (v && !v->isDestroyed()) {
            total += v->health();
        }
    }
    return total;
}

int BossArena::maxTotalVentHp() const
{
    int total = 0;
    for (const CoolingVent *v : m_vents) {
        if (v) total += v->maxHealth();
    }
    return total > 0 ? total : 600;
}

CoolingVent* BossArena::ventAt(int index) const
{
    if (index >= 0 && index < m_vents.size()) {
        return m_vents[index];
    }
    return nullptr;
}

int BossArena::ventCount() const
{
    return m_vents.size();
}

int BossArena::ventHealth(int index) const
{
    if (index >= 0 && index < m_vents.size() && m_vents[index]) {
        return m_vents[index]->health();
    }
    return 0;
}

int BossArena::ventMaxHealth(int index) const
{
    if (index >= 0 && index < m_vents.size() && m_vents[index]) {
        return m_vents[index]->maxHealth();
    }
    return 150;
}

bool BossArena::isVentDestroyed(int index) const
{
    if (index >= 0 && index < m_vents.size() && m_vents[index]) {
        return m_vents[index]->isDestroyed();
    }
    return true;
}

void BossArena::reset()
{
    m_isBossDefeated = false;
    m_spawnTimer = 0.0f;
    m_spawnIndex = 0;

    for (CoolingVent *vent : m_vents) {
        vent->reset();
    }

    emit ventsCountChanged(activeVentsCount());
    emit ventHpChanged();
    emit bossDefeatedChanged(false);
    qDebug() << "[BossArena] Reset completed. All 4 Cooling Vents online.";
}

void BossArena::updateVentCount()
{
    int count = activeVentsCount();
    emit ventsCountChanged(count);
    qDebug() << "[BossArena] Active cooling vents:" << count << "/ 4";

    if (count == 0 && !m_isBossDefeated) {
        m_isBossDefeated = true;
        emit bossDefeatedChanged(true);
        emit bossDefeated();
        qDebug() << "[BossArena] ALL COOLING VENTS DESTROYED! VANGUARD core collapsed.";
    }
}

void BossArena::update(float deltaTime, EnemyManager *enemyManager, LevelManager *levelManager)
{
    if (!levelManager || levelManager->currentLevel() != 3 || m_isBossDefeated) {
        return;
    }

    // Drone reinforcement spawner: spawns standard Drone from perimeter every 5.0 seconds
    m_spawnTimer += deltaTime;
    if (m_spawnTimer >= GameConfig::LEVEL3_SPAWN_INTERVAL) {
        m_spawnTimer = 0.0f;

        if (enemyManager && enemyManager->activeCount() < GameConfig::MAX_ACTIVE_ENEMIES) {
            float bs = GameConfig::BLOCK_SIZE;
            const QVector3D perimeterSpawns[4] = {
                QVector3D((19.0f + 0.5f) * bs, 0.0f, (2.0f + 0.5f) * bs),  // North (1950, 0, 250)
                QVector3D((37.0f + 0.5f) * bs, 0.0f, (19.0f + 0.5f) * bs), // East (3750, 0, 1950)
                QVector3D((32.0f + 0.5f) * bs, 0.0f, (6.0f + 0.5f) * bs),  // North-East (3250, 0, 650) - away from south player spawn
                QVector3D((2.0f + 0.5f) * bs,  0.0f, (19.0f + 0.5f) * bs)  // West (250, 0, 1950)
            };

            QVector3D chosenSpawn = perimeterSpawns[m_spawnIndex % 4];
            m_spawnIndex++;

            bool spawned = enemyManager->spawnDrone(chosenSpawn);
            if (spawned) {
                qDebug() << "[BossArena] Spawned perimeter Drone at" << chosenSpawn
                         << "Active enemies:" << enemyManager->activeCount();
            }
        }
    }
}

CoolingVent* BossArena::checkRayHitVents(const QVector3D &rayOrigin, const QVector3D &rayDir, float &outDist)
{
    CoolingVent *closestVent = nullptr;
    float closestDist = 1e9f;

    for (CoolingVent *vent : m_vents) {
        if (!vent || vent->isDestroyed()) continue;

        float dist = 1e9f;
        if (vent->checkRaycastHit(rayOrigin, rayDir, dist)) {
            if (dist < closestDist) {
                closestDist = dist;
                closestVent = vent;
            }
        }
    }

    if (closestVent) {
        outDist = closestDist;
        return closestVent;
    }

    return nullptr;
}
