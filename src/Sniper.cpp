#include "Sniper.h"
#include "GameConfig.h"
#include "GameWorld.h"
#include "Enemy.h"
#include "EnemyManager.h"
#include "BossArena.h"
#include "CoolingVent.h"
#include <QtMath>
#include <QDebug>

Sniper::Sniper(QObject *parent)
    : Weapon(QStringLiteral("Voxel Sniper Rifle"),
             GameConfig::SNIPER_MAGAZINE_SIZE,
             GameConfig::SNIPER_RESERVE_AMMO,
             GameConfig::SNIPER_FIRE_COOLDOWN,
             GameConfig::SNIPER_RELOAD_TIME,
             parent)
    , m_isAiming(false)
    , m_currentFov(60.0f)
    , m_defaultFov(60.0f)
    , m_scopedFov(18.0f)
{
    qDebug() << "[Sniper] Bolt-action sniper initialized. Default FOV:" << m_defaultFov << "Scoped FOV:" << m_scopedFov;
}

bool Sniper::isAiming() const
{
    return m_isAiming;
}

void Sniper::setAiming(bool aiming)
{
    if (m_isAiming != aiming) {
        m_isAiming = aiming;
        emit aimingChanged(m_isAiming);
    }
}

void Sniper::toggleAim()
{
    setAiming(!m_isAiming);
}

float Sniper::currentFov() const
{
    return m_currentFov;
}

float Sniper::defaultFov() const
{
    return m_defaultFov;
}

float Sniper::scopedFov() const
{
    return m_scopedFov;
}

void Sniper::update(float deltaTime)
{
    Weapon::update(deltaTime);

    if (deltaTime <= 0.0f) return;

    // Smooth FOV zoom transition
    float targetFov = m_isAiming ? m_scopedFov : m_defaultFov;
    if (qAbs(m_currentFov - targetFov) > 0.1f) {
        m_currentFov += (targetFov - m_currentFov) * 14.0f * deltaTime;
        emit fovChanged(m_currentFov);
    }
}

bool Sniper::intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                              const QVector3D &boxMin, const QVector3D &boxMax,
                              float &outDistance) const
{
    float tmin = 0.0f;
    float tmax = 10000.0f;

    // Test X slab
    if (qAbs(dir.x()) > 1e-6f) {
        float invD = 1.0f / dir.x();
        float t0 = (boxMin.x() - origin.x()) * invD;
        float t1 = (boxMax.x() - origin.x()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = qMax(tmin, t0);
        tmax = qMin(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.x() < boxMin.x() || origin.x() > boxMax.x()) return false;
    }

    // Test Y slab
    if (qAbs(dir.y()) > 1e-6f) {
        float invD = 1.0f / dir.y();
        float t0 = (boxMin.y() - origin.y()) * invD;
        float t1 = (boxMax.y() - origin.y()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = qMax(tmin, t0);
        tmax = qMin(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.y() < boxMin.y() || origin.y() > boxMax.y()) return false;
    }

    // Test Z slab
    if (qAbs(dir.z()) > 1e-6f) {
        float invD = 1.0f / dir.z();
        float t0 = (boxMin.z() - origin.z()) * invD;
        float t1 = (boxMax.z() - origin.z()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = qMax(tmin, t0);
        tmax = qMin(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.z() < boxMin.z() || origin.z() > boxMax.z()) return false;
    }

    outDistance = tmin;
    return true;
}

// ==================== SHOOT ALL (via EnemyManager & BossArena) ====================

Sniper::HitType Sniper::shootAll(const QVector3D &origin, const QVector3D &direction,
                                  GameWorld *world, EnemyManager *enemyManager,
                                  BossArena *bossArena)
{
    if (!fire()) {
        return HitType::Miss;
    }

    QVector3D normDir = direction.normalized();

    // 1. DDA raycast against walls / crates / pillars / core walls
    float wallHitDist = 1e9f;
    QVector3D wallHitPoint;
    bool hitWall = false;
    if (world) {
        hitWall = world->raycastDDA(origin, normDir, 5000.0f, wallHitDist, wallHitPoint);
    }

    // 2. Raycast against ALL active enemies via EnemyManager
    bool isHeadshot = false;
    float enemyHitDist = 1e9f;
    Enemy *hitEnemy = nullptr;
    if (enemyManager) {
        hitEnemy = enemyManager->checkRayHitAll(origin, normDir, isHeadshot, enemyHitDist);
    }

    // 3. Raycast against active Cooling Vents via BossArena
    float ventHitDist = 1e9f;
    CoolingVent *hitVent = nullptr;
    if (bossArena) {
        hitVent = bossArena->checkRayHitVents(origin, normDir, ventHitDist);
    }

    // Determine closest target
    float closestDist = wallHitDist;
    int closestType = hitWall ? 0 : -1; // 0 = Wall, 1 = Enemy, 2 = Vent

    if (hitEnemy && enemyHitDist < closestDist) {
        closestDist = enemyHitDist;
        closestType = 1;
    }

    if (hitVent && ventHitDist < closestDist) {
        closestDist = ventHitDist;
        closestType = 2;
    }

    // Case 0: Wall or Pillar blocked the shot
    if (closestType == 0) {
        qDebug() << "[Sniper] Shot hit WALL/PILLAR at distance:" << wallHitDist;
        emit shotFired(wallHitPoint, HitType::Miss);
        return HitType::Miss;
    }

    // Case 1: Enemy hit before any obstacle
    if (closestType == 1) {
        int damage = isHeadshot ? GameConfig::PLAYER_HEADSHOT_DAMAGE : GameConfig::PLAYER_BODYSHOT_DAMAGE;
        hitEnemy->takeDamage(damage, isHeadshot);
        if (enemyManager) {
            enemyManager->setTargetEnemy(hitEnemy);
        }

        HitType hitType = isHeadshot ? HitType::EnemyHead : HitType::EnemyBody;
        QVector3D hitPoint = origin + normDir * enemyHitDist;

        qDebug() << "[Sniper] Shot hit"
                 << (hitEnemy->enemyType() == Enemy::EnemyType::Drone ? "DRONE" : "SENTINEL")
                 << (isHeadshot ? "HEADSHOT!" : "BODY HIT")
                 << "Distance:" << enemyHitDist << "Damage:" << damage;

        emit targetHit(hitPoint, hitType);
        emit shotFired(hitPoint, hitType);
        emit enemyHit(hitEnemy, isHeadshot, damage);
        return hitType;
    }

    // Case 2: Cooling Vent hit before any obstacle
    if (closestType == 2) {
        int damage = GameConfig::PLAYER_BODYSHOT_DAMAGE; // 40 HP per sniper round
        hitVent->takeDamage(damage);

        QVector3D hitPoint = origin + normDir * ventHitDist;
        qDebug() << "[Sniper] Shot hit COOLING VENT" << hitVent->ventIndex()
                 << "Distance:" << ventHitDist << "Damage:" << damage
                 << "Remaining HP:" << hitVent->health();

        emit targetHit(hitPoint, HitType::CoolingVent);
        emit shotFired(hitPoint, HitType::CoolingVent);
        emit ventHit(hitVent, damage);
        return HitType::CoolingVent;
    }

    // Miss (open space)
    QVector3D traceEnd = origin + normDir * 2000.0f;
    emit shotFired(traceEnd, HitType::Miss);
    return HitType::Miss;
}

// ==================== LEGACY SINGLE-ENEMY SHOOT ====================

Sniper::HitType Sniper::shoot(const QVector3D &origin, const QVector3D &direction, GameWorld *world, Enemy *enemy)
{
    if (!fire()) {
        return HitType::Miss;
    }

    QVector3D normDir = direction.normalized();

    // 1. DDA raycast test against walls/crates in the active level
    float wallHitDist = 1e9f;
    QVector3D wallHitPoint;
    bool hitWall = false;
    if (world) {
        hitWall = world->raycastDDA(origin, normDir, 3000.0f, wallHitDist, wallHitPoint);
    }

    // 2. Raycast test against single Enemy
    bool isHeadshot = false;
    float enemyHitDist = 1e9f;
    bool hitEnemyFlag = false;
    if (enemy && !enemy->isDead()) {
        if (enemy->checkRaycastHit(origin, normDir, isHeadshot, enemyHitDist)) {
            hitEnemyFlag = true;
        }
    }

    // Wall hit before enemy: bullet is blocked by the solid wall!
    if (hitWall && (!hitEnemyFlag || wallHitDist < enemyHitDist)) {
        qDebug() << "[Sniper] Shot hit WALL at distance:" << wallHitDist << "HitPoint:" << wallHitPoint;
        emit shotFired(wallHitPoint, HitType::Miss);
        return HitType::Miss;
    }

    // Enemy hit before any wall: damage enemy!
    if (hitEnemyFlag && (!hitWall || enemyHitDist < wallHitDist)) {
        int damage = isHeadshot ? GameConfig::PLAYER_HEADSHOT_DAMAGE : GameConfig::PLAYER_BODYSHOT_DAMAGE;
        enemy->takeDamage(damage, isHeadshot);

        HitType hitType = isHeadshot ? HitType::EnemyHead : HitType::EnemyBody;
        QVector3D hitPoint = origin + normDir * enemyHitDist;

        qDebug() << "[Sniper] Shot hit ENEMY!" << (isHeadshot ? "HEADSHOT!" : "BODY HIT")
                 << "Distance:" << enemyHitDist << "Damage:" << damage;

        emit targetHit(hitPoint, hitType);
        emit shotFired(hitPoint, hitType);
        return hitType;
    }

    // Default shot (miss into open space)
    QVector3D traceEnd = origin + normDir * 2000.0f;
    emit shotFired(traceEnd, HitType::Miss);
    return HitType::Miss;
}
