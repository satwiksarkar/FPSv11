#ifndef GAMEWORLD_H
#define GAMEWORLD_H

#include <QObject>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>
#include "Door.h"
#include "CollisionSystem.h"

#include "LevelManager.h"

/**
 * @brief The GameWorld class coordinates the level, the door,
 * and the collision system for Project VANGUARD.
 */
class GameWorld : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(LevelManager* levelManager READ levelManager WRITE setLevelManager NOTIFY levelManagerChanged)
    Q_PROPERTY(Door* door READ door CONSTANT)
    Q_PROPERTY(CollisionSystem* collisionSystem READ collisionSystem CONSTANT)
    Q_PROPERTY(bool doorClosed READ isDoorClosed WRITE setDoorClosed NOTIFY doorStateChanged)
    Q_PROPERTY(QVector3D doorPosition READ doorPosition CONSTANT)
    Q_PROPERTY(QVector3D spawnPosition READ spawnPosition CONSTANT)

public:
    explicit GameWorld(QObject *parent = nullptr);

    LevelManager* levelManager() const;
    void setLevelManager(LevelManager *mgr);

    Door* door() const;
    CollisionSystem* collisionSystem() const;

    bool isDoorClosed() const;
    QVector3D doorPosition() const;
    QVector3D spawnPosition() const;

    Q_INVOKABLE void setDoorClosed(bool closed);
    Q_INVOKABLE void toggleDoor();
    Q_INVOKABLE void openDoor();
    Q_INVOKABLE void closeDoor();

    /**
     * @brief Rebuilds colliders from the active LevelManager grid.
     */
    Q_INVOKABLE void buildLevelColliders();

    /**
     * @brief Resolves player and entity movement using CollisionSystem.
     */
    Q_INVOKABLE QVector3D resolveCollision(const QVector3D &currentPos, const QVector3D &targetPos, float radius = 35.0f) const;

    /**
     * @brief Fast DDA raycast against active level tiles (walls, crates, core).
     */
    bool raycastDDA(const QVector3D &origin, const QVector3D &direction, float maxDist, float &outDist, QVector3D &outHitPos) const;

    Q_INVOKABLE void resetWorld();

signals:
    void levelManagerChanged();
    void doorStateChanged(bool isClosed);

private:
    void updateColliders();

    LevelManager *m_levelManager;
    Door *m_door;
    CollisionSystem *m_collisionSystem;
};

#endif // GAMEWORLD_H
