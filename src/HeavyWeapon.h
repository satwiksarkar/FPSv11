#ifndef HEAVYWEAPON_H
#define HEAVYWEAPON_H

#include "Weapon.h"
#include <QVector3D>
#include "GameWorld.h"
#include "Enemy.h"
#include "EnemyManager.h"
#include <QtQml/qqmlregistration.h>

class BossArena;
class CoolingVent;

/**
 * @brief The HeavyWeapon class implements the rapid-fire Plasma Repeater.
 * 
 * Inherits from Weapon, featuring high fire-rate (0.15s cooldown), 30-round magazine,
 * moderate zoom, and plasma bolt hitscan raycasting against enemies, cooling vents, and geometry.
 */
class HeavyWeapon : public Weapon
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isAiming READ isAiming WRITE setAiming NOTIFY aimingChanged)
    Q_PROPERTY(float currentFov READ currentFov NOTIFY fovChanged)
    Q_PROPERTY(float defaultFov READ defaultFov CONSTANT)
    Q_PROPERTY(float zoomedFov READ zoomedFov CONSTANT)

public:
    enum class HitType {
        Miss,
        Wall,
        EnemyBody,
        EnemyHead,
        CoolingVent
    };
    Q_ENUM(HitType)

    explicit HeavyWeapon(QObject *parent = nullptr);

    bool isAiming() const;
    Q_INVOKABLE void setAiming(bool aiming);
    Q_INVOKABLE void toggleAim();

    float currentFov() const;
    float defaultFov() const;
    float zoomedFov() const;

    void update(float deltaTime) override;

    /**
     * @brief Rapid-fire hitscan plasma shot against all active enemies and cooling vents.
     */
    Q_INVOKABLE HitType shootAll(const QVector3D &origin, const QVector3D &direction,
                                 GameWorld *world, EnemyManager *enemyManager,
                                 BossArena *bossArena = nullptr);

signals:
    void aimingChanged(bool isAiming);
    void fovChanged(float currentFov);
    void targetHit(const QVector3D &hitPoint, HitType hitType);
    void shotFired(const QVector3D &hitPoint, HitType hitType);
    void enemyHit(Enemy *enemy, bool isHeadshot, int damage);
    void ventHit(CoolingVent *vent, int damage);

private:
    bool m_isAiming;
    float m_defaultFov;
    float m_zoomedFov;
    float m_currentFov;
    float m_fovTransitionSpeed;
};

#endif // HEAVYWEAPON_H
