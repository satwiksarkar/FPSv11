#include "HeavyWeapon.h"
#include "GameConfig.h"
#include "GameWorld.h"
#include "Enemy.h"
#include "EnemyManager.h"
#include "BossArena.h"
#include "CoolingVent.h"
#include <QtMath>
#include <QDebug>

HeavyWeapon::HeavyWeapon(QObject *parent)
    : Weapon(QStringLiteral("Plasma Repeater"),
             GameConfig::HEAVY_MAGAZINE_SIZE,
             GameConfig::HEAVY_RESERVE_AMMO,
             GameConfig::HEAVY_FIRE_COOLDOWN,
             GameConfig::HEAVY_RELOAD_TIME,
             parent)
    , m_isAiming(false)
    , m_defaultFov(60.0f)
    , m_zoomedFov(50.0f)
    , m_currentFov(60.0f)
    , m_fovTransitionSpeed(14.0f)
{
}

bool HeavyWeapon::isAiming() const
{
    return m_isAiming;
}

void HeavyWeapon::setAiming(bool aiming)
{
    if (m_isAiming != aiming) {
        m_isAiming = aiming;
        emit aimingChanged(m_isAiming);
    }
}

void HeavyWeapon::toggleAim()
{
    setAiming(!m_isAiming);
}

float HeavyWeapon::currentFov() const
{
    return m_currentFov;
}

float HeavyWeapon::defaultFov() const
{
    return m_defaultFov;
}

float HeavyWeapon::zoomedFov() const
{
    return m_zoomedFov;
}

void HeavyWeapon::update(float deltaTime)
{
    Weapon::update(deltaTime);

    // Smooth FOV interpolation for plasma zoom
    float targetFov = m_isAiming ? m_zoomedFov : m_defaultFov;
    if (qAbs(m_currentFov - targetFov) > 0.05f) {
        m_currentFov += (targetFov - m_currentFov) * qMin(1.0f, m_fovTransitionSpeed * deltaTime);
        emit fovChanged(m_currentFov);
    }
}

HeavyWeapon::HitType HeavyWeapon::shootAll(const QVector3D &origin, const QVector3D &direction,
                                           GameWorld *world, EnemyManager *enemyManager,
                                           BossArena *bossArena)
{
    if (!fire()) {
        return HitType::Miss;
    }

    QVector3D normDir = direction.normalized();

    // 1. Raycast against tile grid (walls, crates, pillars, core walls) via DDA
    float wallDist = 99999.0f;
    QVector3D wallHitPos;
    bool hitWall = false;
    if (world) {
        hitWall = world->raycastDDA(origin, normDir, 6000.0f, wallDist, wallHitPos);
    }

    // 2. Raycast against all active enemies via EnemyManager
    float enemyDist = 99999.0f;
    bool isHeadshot = false;
    Enemy *hitEnemy = nullptr;
    if (enemyManager) {
        hitEnemy = enemyManager->checkRayHitAll(origin, normDir, isHeadshot, enemyDist);
    }

    // 3. Raycast against active Cooling Vents via BossArena
    float ventDist = 99999.0f;
    CoolingVent *hitVent = nullptr;
    if (bossArena) {
        hitVent = bossArena->checkRayHitVents(origin, normDir, ventDist);
    }

    // Determine closest target
    float closestDist = wallDist;
    int closestType = hitWall ? 0 : -1; // 0 = Wall, 1 = Enemy, 2 = Vent

    if (hitEnemy && enemyDist < closestDist) {
        closestDist = enemyDist;
        closestType = 1;
    }

    if (hitVent && ventDist < closestDist) {
        closestDist = ventDist;
        closestType = 2;
    }

    // Case 0: Wall or Pillar blocked shot
    if (closestType == 0) {
        emit targetHit(wallHitPos, HitType::Wall);
        emit shotFired(wallHitPos, HitType::Wall);
        return HitType::Wall;
    }

    // Case 1: Enemy hit before obstacle
    if (closestType == 1) {
        int dmg = GameConfig::HEAVY_WEAPON_DAMAGE;
        hitEnemy->takeDamage(dmg, isHeadshot);
        if (enemyManager) {
            enemyManager->setTargetEnemy(hitEnemy);
        }

        QVector3D hitPoint = origin + normDir * enemyDist;
        HitType hType = isHeadshot ? HitType::EnemyHead : HitType::EnemyBody;
        emit targetHit(hitPoint, hType);
        emit shotFired(hitPoint, hType);
        emit enemyHit(hitEnemy, isHeadshot, dmg);
        qDebug() << "[HeavyWeapon] Enemy hit! Damage:" << dmg << (isHeadshot ? "HEADSHOT" : "BODY");
        return hType;
    }

    // Case 2: Cooling Vent hit before obstacle
    if (closestType == 2) {
        int dmg = GameConfig::HEAVY_WEAPON_DAMAGE; // 25 HP
        hitVent->takeDamage(dmg);

        QVector3D hitPoint = origin + normDir * ventDist;
        emit targetHit(hitPoint, HitType::CoolingVent);
        emit shotFired(hitPoint, HitType::CoolingVent);
        emit ventHit(hitVent, dmg);
        qDebug() << "[HeavyWeapon] Cooling vent" << hitVent->ventIndex() << "hit! Damage:" << dmg << "HP:" << hitVent->health();
        return HitType::CoolingVent;
    }

    QVector3D maxRangePoint = origin + normDir * 4000.0f;
    emit shotFired(maxRangePoint, HitType::Miss);
    return HitType::Miss;
}
