#include "EnemyManager.h"
#include "Player.h"
#include "GameManager.h"
#include "GameWorld.h"
#include "GameConfig.h"
#include <QDebug>
#include <QtMath>
#include <QRandomGenerator>

// ==================== CONSTRUCTOR ====================

EnemyManager::EnemyManager(QObject *parent)
    : QObject(parent)
    , m_world(nullptr)
    , m_totalKills(0)
    , m_nearestHealth(0)
    , m_nearestMaxHealth(100)
    , m_nearestDead(true)
    , m_nearestState(QStringLiteral("IDLE"))
    , m_nearestType(QStringLiteral("NONE"))
    , m_targetEnemy(nullptr)
    , m_targetTimer(0.0f)
{
    // Pre-allocate enemy pool: Drones and Sentinels up to MAX_ACTIVE_ENEMIES cap
    int droneSlots = 16;
    int sentinelSlots = 14;

    for (int i = 0; i < droneSlots; ++i) {
        Enemy *e = new Enemy(Enemy::EnemyType::Drone, this);
        e->setActive(false);
        m_pool.append(e);

        connect(e, &Enemy::died, this, [this, e]() {
            m_totalKills++;
            emit totalKillsChanged(m_totalKills);
            emit enemyKilled(e);
            emit activeCountChanged(activeCount());
        });

        connect(e, &Enemy::shotFired, this, [this](const QVector3D &from, const QVector3D &targetPos, bool didHit) {
            emit enemyShotFired();
            emit enemyBulletFired(from, targetPos, didHit);
        });
    }

    for (int i = 0; i < sentinelSlots; ++i) {
        Enemy *e = new Enemy(Enemy::EnemyType::Sentinel, this);
        e->setActive(false);
        m_pool.append(e);

        connect(e, &Enemy::died, this, [this, e]() {
            m_totalKills++;
            emit totalKillsChanged(m_totalKills);
            emit enemyKilled(e);
            emit activeCountChanged(activeCount());
        });

        connect(e, &Enemy::shotFired, this, [this](const QVector3D &from, const QVector3D &targetPos, bool didHit) {
            emit enemyShotFired();
            emit enemyBulletFired(from, targetPos, didHit);
        });
    }

    qDebug() << "[EnemyManager] Pool created with" << m_pool.size() << "enemy slots"
             << "(Drones:" << droneSlots << " Sentinels:" << sentinelSlots << ")"
             << "Max active:" << GameConfig::MAX_ACTIVE_ENEMIES;
}

// ==================== PROPERTY GETTERS ====================

int EnemyManager::activeCount() const
{
    int count = 0;
    for (const Enemy *e : m_pool) {
        if (e->isActive() && !e->isDead()) {
            count++;
        }
    }
    return count;
}

int EnemyManager::maxActive() const
{
    return GameConfig::MAX_ACTIVE_ENEMIES;
}

int EnemyManager::totalKills() const
{
    return m_totalKills;
}

int EnemyManager::nearestEnemyHealth() const { return m_nearestHealth; }
int EnemyManager::nearestEnemyMaxHealth() const { return m_nearestMaxHealth; }
bool EnemyManager::nearestEnemyDead() const { return m_nearestDead; }
QString EnemyManager::nearestEnemyState() const { return m_nearestState; }
QString EnemyManager::nearestEnemyType() const { return m_nearestType; }

// ==================== WORLD SETUP ====================

void EnemyManager::setWorld(GameWorld *world)
{
    m_world = world;
    for (Enemy *e : m_pool) {
        e->setWorld(world);
    }
}

// ==================== SPAWN ====================

Enemy* EnemyManager::findInactiveEnemy(Enemy::EnemyType type)
{
    // First pass: find an inactive enemy of the requested type
    for (Enemy *e : m_pool) {
        if (e->enemyType() == type && !e->isActive()) {
            return e;
        }
    }
    // Second pass: find a dead enemy of the requested type that can be recycled
    for (Enemy *e : m_pool) {
        if (e->enemyType() == type && e->isDead()) {
            return e;
        }
    }
    return nullptr;
}

bool EnemyManager::spawnDrone(const QVector3D &position)
{
    if (activeCount() >= GameConfig::MAX_ACTIVE_ENEMIES) {
        qDebug() << "[EnemyManager] Cannot spawn Drone: MAX_ACTIVE_ENEMIES reached (" << activeCount() << ")";
        return false;
    }

    Enemy *e = findInactiveEnemy(Enemy::EnemyType::Drone);
    if (!e) {
        qDebug() << "[EnemyManager] No available Drone slot in pool.";
        return false;
    }

    // Varied drone machine types: roughly 50% are shooter gunships, 50% are rapid melee shock drones
    bool isShooter = (QRandomGenerator::global()->bounded(100) < 50);
    e->setCanShoot(isShooter);

    e->setWorld(m_world);
    e->respawn(position);
    emit enemySpawned(e);
    emit activeCountChanged(activeCount());
    return true;
}

bool EnemyManager::spawnSentinel(const QVector3D &position)
{
    if (activeCount() >= GameConfig::MAX_ACTIVE_ENEMIES) {
        qDebug() << "[EnemyManager] Cannot spawn Sentinel: MAX_ACTIVE_ENEMIES reached (" << activeCount() << ")";
        return false;
    }

    Enemy *e = findInactiveEnemy(Enemy::EnemyType::Sentinel);
    if (!e) {
        qDebug() << "[EnemyManager] No available Sentinel slot in pool.";
        return false;
    }

    e->setWorld(m_world);
    e->respawn(position);
    emit enemySpawned(e);
    emit activeCountChanged(activeCount());
    return true;
}

// ==================== UPDATE ALL ====================

void EnemyManager::updateAll(float deltaTime, const QVector3D &playerPos,
                              Player *player, GameManager *gameManager)
{
    // Skip updates when paused or in story text
    if (gameManager && (gameManager->isPaused() || gameManager->isStoryText())) return;

    if (m_targetTimer > 0.0f) {
        m_targetTimer -= deltaTime;
    }

    for (Enemy *e : m_pool) {
        if (e->isActive() && !e->isDead()) {
            e->update(deltaTime, playerPos, player, gameManager);
        }
    }

    // Update nearest enemy info for HUD
    updateNearestEnemy(playerPos);
}

// ==================== CLEAR ALL ====================

void EnemyManager::clearAll()
{
    for (Enemy *e : m_pool) {
        e->reset();
    }
    m_totalKills = 0;
    m_nearestDead = true;
    m_nearestHealth = 0;
    m_nearestState = QStringLiteral("IDLE");
    m_nearestType = QStringLiteral("NONE");
    m_targetEnemy = nullptr;
    m_targetTimer = 0.0f;

    emit activeCountChanged(0);
    emit totalKillsChanged(0);
    emit nearestEnemyChanged();
    qDebug() << "[EnemyManager] All enemies cleared.";
}

void EnemyManager::setTargetEnemy(Enemy *e)
{
    if (!e) return;
    m_targetEnemy = e;
    m_targetTimer = 4.0f;
    m_nearestHealth = e->health();
    m_nearestMaxHealth = e->maxHealth();
    m_nearestDead = e->isDead();
    m_nearestState = e->stateString();
    m_nearestType = (e->enemyType() == Enemy::EnemyType::Drone) ? QStringLiteral("DRONE") : QStringLiteral("SENTINEL");
    emit nearestEnemyChanged();
}

// ==================== HIT DETECTION ====================

Enemy* EnemyManager::checkRayHitAll(const QVector3D &rayOrigin, const QVector3D &rayDir,
                                     bool &outIsHeadshot, float &outDistance)
{
    Enemy *closest = nullptr;
    float closestDist = 1e9f;

    for (Enemy *e : m_pool) {
        if (!e->isActive() || e->isDead()) continue;

        bool isHead = false;
        float dist = 0.0f;
        if (e->checkRaycastHit(rayOrigin, rayDir, isHead, dist)) {
            if (dist < closestDist) {
                closestDist = dist;
                closest = e;
                outIsHeadshot = isHead;
                outDistance = dist;
            }
        }
    }

    return closest;
}

// ==================== QML ACCESS ====================

QList<QObject*> EnemyManager::getEnemyList() const
{
    QList<QObject*> list;
    for (Enemy *e : m_pool) {
        list.append(e);
    }
    return list;
}

Enemy* EnemyManager::enemyAt(int index) const
{
    if (index >= 0 && index < m_pool.size()) {
        return m_pool[index];
    }
    return nullptr;
}

int EnemyManager::poolSize() const
{
    return m_pool.size();
}

// ==================== NEAREST ENEMY FOR HUD ====================

void EnemyManager::updateNearestEnemy(const QVector3D &playerPos)
{
    bool changed = false;

    // 1. If we have a recently shot / hit enemy, prioritize showing ITS health on the HUD
    if (m_targetEnemy && m_targetTimer > 0.0f && m_targetEnemy->isActive()) {
        int h = m_targetEnemy->health();
        int mh = m_targetEnemy->maxHealth();
        bool dead = m_targetEnemy->isDead();
        QString st = m_targetEnemy->stateString();
        QString tp = (m_targetEnemy->enemyType() == Enemy::EnemyType::Drone) ? QStringLiteral("DRONE") : QStringLiteral("SENTINEL");

        if (m_nearestHealth != h || m_nearestMaxHealth != mh || m_nearestDead != dead
            || m_nearestState != st || m_nearestType != tp) {
            m_nearestHealth = h;
            m_nearestMaxHealth = mh;
            m_nearestDead = dead;
            m_nearestState = st;
            m_nearestType = tp;
            changed = true;
        }

        if (changed) {
            emit nearestEnemyChanged();
        }
        return;
    }

    // 2. Otherwise find the closest alive enemy
    Enemy *nearest = nullptr;
    float nearestDist = 1e9f;

    for (Enemy *e : m_pool) {
        if (!e->isActive() || e->isDead()) continue;

        float dx = e->position().x() - playerPos.x();
        float dz = e->position().z() - playerPos.z();
        float dist = qSqrt(dx * dx + dz * dz);
        if (dist < nearestDist) {
            nearestDist = dist;
            nearest = e;
        }
    }

    changed = false;
    if (nearest) {
        int h = nearest->health();
        int mh = nearest->maxHealth();
        bool dead = nearest->isDead();
        QString st = nearest->stateString();
        QString tp = (nearest->enemyType() == Enemy::EnemyType::Drone) ? QStringLiteral("DRONE") : QStringLiteral("SENTINEL");

        if (m_nearestHealth != h || m_nearestMaxHealth != mh || m_nearestDead != dead
            || m_nearestState != st || m_nearestType != tp) {
            m_nearestHealth = h;
            m_nearestMaxHealth = mh;
            m_nearestDead = dead;
            m_nearestState = st;
            m_nearestType = tp;
            changed = true;
        }
    } else {
        if (!m_nearestDead || m_nearestType != QStringLiteral("NONE")) {
            m_nearestHealth = 0;
            m_nearestMaxHealth = 100;
            m_nearestDead = true;
            m_nearestState = QStringLiteral("IDLE");
            m_nearestType = QStringLiteral("NONE");
            changed = true;
        }
    }

    if (changed) {
        emit nearestEnemyChanged();
    }
}
