#include "GameWorld.h"
#include "LevelManager.h"
#include <QDebug>

GameWorld::GameWorld(QObject *parent)
    : QObject(parent)
    , m_levelManager(nullptr)
    , m_door(new Door(this))
    , m_collisionSystem(new CollisionSystem(this))
{
    connect(m_door, &Door::openChanged, this, [this](bool isOpen) {
        emit doorStateChanged(!isOpen);
    });
}

LevelManager* GameWorld::levelManager() const
{
    return m_levelManager;
}

void GameWorld::setLevelManager(LevelManager *mgr)
{
    if (m_levelManager != mgr) {
        if (m_levelManager) {
            disconnect(m_levelManager, nullptr, this, nullptr);
        }
        m_levelManager = mgr;
        if (m_levelManager) {
            connect(m_levelManager, &LevelManager::levelLoaded, this, &GameWorld::buildLevelColliders);
            buildLevelColliders();
        }
        emit levelManagerChanged();
    }
}

Door* GameWorld::door() const
{
    return m_door;
}

CollisionSystem* GameWorld::collisionSystem() const
{
    return m_collisionSystem;
}

bool GameWorld::isDoorClosed() const
{
    return !m_door->isOpen();
}

void GameWorld::setDoorClosed(bool closed)
{
    m_door->setOpen(!closed);
}

void GameWorld::toggleDoor()
{
    m_door->toggle();
}

void GameWorld::openDoor()
{
    m_door->open();
}

void GameWorld::closeDoor()
{
    m_door->close();
}

QVector3D GameWorld::doorPosition() const
{
    return m_door->position();
}

QVector3D GameWorld::spawnPosition() const
{
    if (m_levelManager) {
        return m_levelManager->spawnPosition();
    }
    return QVector3D(250.0f, 0.0f, 1350.0f);
}

void GameWorld::buildLevelColliders()
{
    if (m_levelManager) {
        m_collisionSystem->buildFromLevel(m_levelManager);
    } else {
        updateColliders();
    }
}

void GameWorld::updateColliders()
{
    m_collisionSystem->clear();
    // Default fallback boundary
    m_collisionSystem->addBox(QVector3D(-20.0f, 0.0f, -20.0f), QVector3D(1620.0f, 300.0f, 0.0f), QStringLiteral("Wall_North"));
    m_collisionSystem->addBox(QVector3D(-20.0f, 0.0f, 1600.0f), QVector3D(1620.0f, 300.0f, 1620.0f), QStringLiteral("Wall_South"));
    m_collisionSystem->addBox(QVector3D(-20.0f, 0.0f, -20.0f), QVector3D(0.0f, 300.0f, 1620.0f), QStringLiteral("Wall_West"));
    m_collisionSystem->addBox(QVector3D(1600.0f, 0.0f, -20.0f), QVector3D(1620.0f, 300.0f, 1620.0f), QStringLiteral("Wall_East"));
}

QVector3D GameWorld::resolveCollision(const QVector3D &currentPos, const QVector3D &targetPos, float radius) const
{
    return m_collisionSystem->resolveMovement(currentPos, targetPos, radius);
}

bool GameWorld::raycastDDA(const QVector3D &origin, const QVector3D &direction, float maxDist, float &outDist, QVector3D &outHitPos) const
{
    if (m_collisionSystem && m_levelManager) {
        int hitTile = 0;
        return m_collisionSystem->raycastDDA(m_levelManager, origin, direction, maxDist, outDist, outHitPos, hitTile);
    }
    QString hitTag;
    if (m_collisionSystem && m_collisionSystem->raycast(origin, direction, maxDist, outDist, hitTag)) {
        outHitPos = origin + direction.normalized() * outDist;
        return true;
    }
    return false;
}

void GameWorld::resetWorld()
{
    m_door->reset();
    buildLevelColliders();
    qDebug() << "[GameWorld] Reset world state and colliders.";
}
