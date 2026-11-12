#ifndef LEVELMANAGER_H
#define LEVELMANAGER_H

#include <QObject>
#include <QString>
#include <QVector3D>
#include <QList>
#include <QHash>
#include <QPointer>
#include <QSet>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>
#include "LevelData.h"
#include "Door.h"

class CollisionSystem;
class EnemyManager;

/**
 * @brief The LevelManager class manages current campaign progress, active tile maps,
 * story briefing transitions, spawn coordinates, BFS reachability validation,
 * exit/pickup triggers, and the level door system for Project VANGUARD.
 */
class LevelManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int currentLevel READ currentLevel NOTIFY currentLevelChanged)
    Q_PROPERTY(int maxLevels READ maxLevels CONSTANT)
    Q_PROPERTY(QString currentLevelName READ currentLevelName NOTIFY currentLevelChanged)
    Q_PROPERTY(QString storyTitle READ storyTitle NOTIFY storyChanged)
    Q_PROPERTY(QString storyText READ storyText NOTIFY storyChanged)
    Q_PROPERTY(QVector3D spawnPosition READ spawnPosition NOTIFY levelLoaded)
    Q_PROPERTY(QVector3D exitCenterPosition READ exitCenterPosition NOTIFY levelLoaded)
    Q_PROPERTY(int mapWidth READ mapWidth NOTIFY levelLoaded)
    Q_PROPERTY(int mapHeight READ mapHeight NOTIFY levelLoaded)
    Q_PROPERTY(float blockSize READ blockSize CONSTANT)
    Q_PROPERTY(bool loadingBayTriggered READ isLoadingBayTriggered NOTIFY loadingBayTriggeredChanged)
    Q_PROPERTY(bool heavyWeaponCollected READ isHeavyWeaponCollected NOTIFY heavyWeaponCollectedChanged)
    Q_PROPERTY(QVector3D heavyWeaponSpawnPosition READ heavyWeaponSpawnPosition CONSTANT)

    // Door system properties (Day 1)
    Q_PROPERTY(QVariantList doors READ doors NOTIFY doorsChanged)
    Q_PROPERTY(Door* targetDoor READ targetDoor NOTIFY targetDoorChanged)
    Q_PROPERTY(QString interactionPrompt READ interactionPrompt NOTIFY interactionPromptChanged)

public:
    explicit LevelManager(QObject *parent = nullptr);

    int currentLevel() const;
    int maxLevels() const;
    QString currentLevelName() const;
    QString storyTitle() const;
    QString storyText() const;
    QVector3D spawnPosition() const;
    QVector3D exitCenterPosition() const;
    int mapWidth() const;
    int mapHeight() const;
    float blockSize() const;
    bool isLoadingBayTriggered() const;
    bool isHeavyWeaponCollected() const;
    QVector3D heavyWeaponSpawnPosition() const;

    // Door system getters
    QVariantList doors() const;
    Door* targetDoor() const;
    QString interactionPrompt() const;

    // Level progression actions
    Q_INVOKABLE void loadLevel(int levelIndex);
    Q_INVOKABLE void advanceLevel();
    Q_INVOKABLE void resetToFirstLevel();

    // Tile grid queries
    Q_INVOKABLE int getTile(int row, int col) const;
    Q_INVOKABLE int getTileAtWorldPos(float x, float z) const;
    Q_INVOKABLE bool isStaticSolidTile(int row, int col) const;
    Q_INVOKABLE bool isSolidTile(int row, int col) const;

    // Door system API
    Q_INVOKABLE int doorCount() const;
    Q_INVOKABLE Door* doorAt(int index) const;
    Q_INVOKABLE Door* doorAtTile(int row, int col) const;
    Q_INVOKABLE Door* addDoor(int row,
                              int col,
                              float axis = 0.0f,
                              int doorType = 0,
                              int requiredKeyIndex = -1,
                              int requiredKeyCount = 0,
                              int requiredKeyMask = 0,
                              bool requiresBossDefeated = false,
                              const QString &label = QString());
    Q_INVOKABLE void clearDoors();

    Q_INVOKABLE void updateDoors(float deltaTime,
                                 const QVector3D &playerPos,
                                 const QVector3D &cameraPos,
                                 const QVector3D &lookDir,
                                 CollisionSystem *collisionSystem = nullptr,
                                 EnemyManager *enemyManager = nullptr);
    Q_INVOKABLE bool interactWithTargetDoor(const QVector3D &playerPos,
                                            EnemyManager *enemyManager = nullptr);

    // Exit tile trigger detection called each frame
    Q_INVOKABLE bool checkExitReached(const QVector3D &playerPos);

    // Dynamic ammo tile consumption (returns true if newly collected)
    Q_INVOKABLE bool consumeAmmoTile(float x, float z);

    // Heavy weapon pickup consumption
    Q_INVOKABLE bool consumeHeavyWeaponTile(float x, float z);

    // Trigger trap detection (Stage V6)
    Q_INVOKABLE bool checkTriggerTrap(const QVector3D &playerPos, float playerYaw);

    // Encounter queries
    Q_INVOKABLE bool isInLoadingBay(float x, float z) const;
    Q_INVOKABLE bool triggerLoadingBay();

    // Spawn point queries for QML level initialization
    Q_INVOKABLE int corridorDroneSpawnCount() const;
    Q_INVOKABLE QVector3D corridorDroneSpawn(int index) const;
    Q_INVOKABLE int loadingBayDroneSpawnCount() const;
    Q_INVOKABLE QVector3D loadingBayDroneSpawn(int index) const;
    Q_INVOKABLE int sentinelSpawnCount() const;
    Q_INVOKABLE QVector3D sentinelSpawn(int index) const;
    Q_INVOKABLE int droneSpawnCount() const;
    Q_INVOKABLE QVector3D droneSpawn(int index) const;
    Q_INVOKABLE bool isAmmoTileConsumed(int row, int col) const;

signals:
    void currentLevelChanged(int newLevel);
    void storyChanged();
    void levelLoaded(int level);
    void exitReached(int nextLevel);
    void campaignWon();
    void loadingBayTriggeredChanged();
    void ammoTileCollected(const QVector3D &pos);
    void heavyWeaponCollectedChanged();
    void heavyWeaponCollected();
    void trapTriggered(const QVector3D &spawnPos, int enemyType);

    // Door signals
    void doorsChanged();
    void targetDoorChanged();
    void interactionPromptChanged();
    void doorTriggered();
    void doorInteractionFeedback(const QString &message, const QString &colorHex);

private:
    void rebuildDoorsForLevel(int level);
    bool isDoorTileObstructed(const Door *door, const QVector3D &playerPos, EnemyManager *enemyManager) const;
    bool isRayOccludedBefore(const QVector3D &origin,
                             const QVector3D &normDir,
                             float targetDist,
                             CollisionSystem *collisionSystem) const;
    Door* findTargetDoor(const QVector3D &cameraPos,
                         const QVector3D &lookDir,
                         CollisionSystem *collisionSystem) const;
    void updateInteractionPrompt(const QVector3D &playerPos, EnemyManager *enemyManager);
    QString buildDoorPrompt(const Door *door, const QVector3D &playerPos, EnemyManager *enemyManager) const;

    int m_currentLevel;
    int m_maxLevels;
    bool m_exitTriggered;
    bool m_loadingBayTriggered;
    bool m_heavyWeaponCollected;
    QSet<int> m_consumedAmmoTiles;
    QSet<int> m_triggeredTraps;

    QList<Door*> m_doors;
    QHash<int, Door*> m_doorTileLookup;
    QPointer<Door> m_targetDoor;
    QString m_interactionPrompt;
};

#endif // LEVELMANAGER_H
