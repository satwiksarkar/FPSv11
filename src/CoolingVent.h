#ifndef COOLINGVENT_H
#define COOLINGVENT_H

#include <QObject>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>
#include "GameConfig.h"

/**
 * @brief The CoolingVent class represents one of four destructible cooling vents
 * protecting the VANGUARD Logic Core in Level 3.
 * 
 * Targetable by hitscan player weaponry (Sniper / Plasma Repeater).
 * Occluded by arena pillars and the central mainframe structure.
 */
class CoolingVent : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector3D position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(int health READ health NOTIFY healthChanged)
    Q_PROPERTY(int maxHealth READ maxHealth CONSTANT)
    Q_PROPERTY(bool isDestroyed READ isDestroyed NOTIFY isDestroyedChanged)
    Q_PROPERTY(int ventIndex READ ventIndex WRITE setVentIndex NOTIFY ventIndexChanged)

public:
    explicit CoolingVent(int index = 0, const QVector3D &pos = QVector3D(), QObject *parent = nullptr);

    QVector3D position() const;
    void setPosition(const QVector3D &pos);

    int health() const;
    int maxHealth() const;
    bool isDestroyed() const;

    int ventIndex() const;
    void setVentIndex(int index);

    Q_INVOKABLE void takeDamage(int amount);
    Q_INVOKABLE void reset();

    // Raycast hit detection against this vent's bounding box
    bool checkRaycastHit(const QVector3D &rayOrigin, const QVector3D &rayDir, float &outDist) const;

signals:
    void positionChanged();
    void healthChanged(int newHealth);
    void damaged(int damage, int remainingHealth);
    void destroyed();
    void isDestroyedChanged();
    void ventIndexChanged();

private:
    bool intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                          const QVector3D &boxMin, const QVector3D &boxMax,
                          float &outDist) const;

    int m_ventIndex;
    QVector3D m_position;
    int m_health;
    int m_maxHealth;
    bool m_isDestroyed;
};

#endif // COOLINGVENT_H
