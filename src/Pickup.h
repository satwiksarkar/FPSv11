#ifndef PICKUP_H
#define PICKUP_H

#include <QObject>
#include <QVector3D>
#include <QString>
#include <QtQml/qqmlregistration.h>
#include "Inventory.h"

/**
 * @brief The Pickup class models a collectible voxel item in the 3D game world.
 * 
 * Manages item type (Food Pack, Bandage, Medkit), world position,
 * continuous rotation/bobbing animation, and proximity collection detection.
 */
class Pickup : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector3D position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(QVector3D renderPosition READ renderPosition NOTIFY renderPositionChanged)
    Q_PROPERTY(Inventory::ItemType itemType READ itemType WRITE setItemType NOTIFY itemTypeChanged)
    Q_PROPERTY(QString typeString READ typeString NOTIFY itemTypeChanged)
    Q_PROPERTY(int healAmount READ healAmount NOTIFY itemTypeChanged)
    Q_PROPERTY(bool isCollected READ isCollected WRITE setCollected NOTIFY collectedChanged)
    Q_PROPERTY(float rotationY READ rotationY NOTIFY rotationChanged)
    Q_PROPERTY(float bobOffset READ bobOffset NOTIFY bobOffsetChanged)

public:
    explicit Pickup(QObject *parent = nullptr);
    Pickup(const QVector3D &position, Inventory::ItemType type, QObject *parent = nullptr);

    QVector3D position() const;
    void setPosition(const QVector3D &pos);

    QVector3D renderPosition() const;

    Inventory::ItemType itemType() const;
    void setItemType(Inventory::ItemType type);

    QString typeString() const;
    int healAmount() const;

    bool isCollected() const;
    void setCollected(bool collected);

    float rotationY() const;
    float bobOffset() const;

    // Delta-time animation loop
    Q_INVOKABLE void update(float deltaTime);

    // Proximity check against player position
    Q_INVOKABLE bool checkCollection(const QVector3D &playerPos, float radius = 70.0f);

    // Lifecycle helpers
    Q_INVOKABLE void reset();
    Q_INVOKABLE void respawn(const QVector3D &pos, Inventory::ItemType type);

signals:
    void positionChanged();
    void renderPositionChanged();
    void itemTypeChanged();
    void collectedChanged(bool isCollected);
    void rotationChanged();
    void bobOffsetChanged();
    void collected(Inventory::ItemType type, int healAmount);

private:
    QVector3D m_position;
    Inventory::ItemType m_type;
    bool m_isCollected;
    float m_rotationY;
    float m_bobTimer;
    float m_bobOffset;
};

#endif // PICKUP_H
