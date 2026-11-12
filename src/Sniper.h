#ifndef SNIPER_H
#define SNIPER_H

#include "Weapon.h"
#include <QVector3D>
#include "GameWorld.h"
#include "Enemy.h"

#include "EnemyManager.h"

class BossArena;
class CoolingVent;

/**
 * @brief The Sniper class implements the bolt-action sniper rifle.
 * 
 * Inherits from Weapon, adding scope zoom mechanics (FOV narrowing),
 * raycasting hit detection for targets and the start room door,
 * and distinct damage values for headshots, bodyshots, and cooling vents.
 */
class Sniper : public Weapon
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isAiming READ isAiming WRITE setAiming NOTIFY aimingChanged)
    Q_PROPERTY(float currentFov READ currentFov NOTIFY fovChanged)
    Q_PROPERTY(float defaultFov READ defaultFov CONSTANT)
    Q_PROPERTY(float scopedFov READ scopedFov CONSTANT)

public:
    enum class HitType {
        Miss,
        Door,
        EnemyBody,
        EnemyHead,
        CoolingVent
    };
    Q_ENUM(HitType)

    explicit Sniper(QObject *parent = nullptr);

    bool isAiming() const;
    Q_INVOKABLE void setAiming(bool aiming);
    Q_INVOKABLE void toggleAim();

    float currentFov() const;
    float defaultFov() const;
    float scopedFov() const;

    void update(float deltaTime) override;

    /**
     * @brief Performs a sniper shot against walls, enemies, and cooling vents.
     * @param origin Camera/eye position.
     * @param direction Forward aim vector.
     * @param world GameWorld pointer for wall collision.
     * @param enemyManager EnemyManager pointer for multi-enemy hit detection.
     * @param bossArena BossArena pointer for cooling vent hit detection.
     */
    Q_INVOKABLE HitType shootAll(const QVector3D &origin, const QVector3D &direction,
                                  GameWorld *world, EnemyManager *enemyManager,
                                  BossArena *bossArena = nullptr);

    /**
     * @brief Legacy single-enemy shoot (kept for backward compatibility).
     */
    Q_INVOKABLE HitType shoot(const QVector3D &origin, const QVector3D &direction,
                               GameWorld *world, Enemy *enemy = nullptr);

signals:
    void aimingChanged(bool isAiming);
    void fovChanged(float newFov);
    void doorHit();
    void targetHit(const QVector3D &hitPoint, HitType hitType);
    void shotFired(const QVector3D &hitPoint, HitType hitType);
    void enemyHit(Enemy *enemy, bool isHeadshot, int damage);
    void ventHit(CoolingVent *vent, int damage);

private:
    bool intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                          const QVector3D &boxMin, const QVector3D &boxMax,
                          float &outDistance) const;

    bool m_isAiming;
    float m_currentFov;
    float m_defaultFov;
    float m_scopedFov;
};

#endif // SNIPER_H
