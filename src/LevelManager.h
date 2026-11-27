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
#include <array>
#include "LevelData.h"
#include "Door.h"
#include "AccessKeyPickup.h"
#include "PuzzleManager.h"

class BossArena;
class CollisionSystem;
class EnemyManager;
class Player;

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

    // Mission Key & Extraction Progression properties (Day 2)
    Q_PROPERTY(int collectedKeysCount READ collectedKeysCount NOTIFY missionKeysChanged)
    Q_PROPERTY(int totalKeysRequired READ totalKeysRequired CONSTANT)
    Q_PROPERTY(int collectedKeysMask READ collectedKeysMask NOTIFY missionKeysChanged)
    Q_PROPERTY(QVariantList levelKeys READ levelKeys NOTIFY levelKeysChanged)
    Q_PROPERTY(BossArena* bossArena READ bossArena WRITE setBossArena NOTIFY bossArenaChanged)
    Q_PROPERTY(bool bossCompleted READ isBossCompleted NOTIFY missionProgressChanged)
    Q_PROPERTY(int activeVentsRemaining READ activeVentsRemaining NOTIFY missionProgressChanged)
    Q_PROPERTY(bool extractionAvailable READ isExtractionAvailable NOTIFY missionProgressChanged)
    Q_PROPERTY(PuzzleManager* puzzleManager READ puzzleManager WRITE setPuzzleManager NOTIFY puzzleManagerChanged)

    // Player Count & Level 1 Variant properties
    Q_PROPERTY(int playerCount READ playerCount WRITE setPlayerCount NOTIFY playerCountChanged)
    Q_PROPERTY(int level1Variant READ level1Variant NOTIFY level1VariantChanged)

    // Gas Emergency properties
    Q_PROPERTY(bool gasLeakActive READ isGasLeakActive NOTIFY gasEmergencyChanged)
    Q_PROPERTY(float gasLeakTimeRemaining READ gasLeakTimeRemaining NOTIFY gasEmergencyChanged)
    Q_PROPERTY(int gasLeakRepairStage READ gasLeakRepairStage NOTIFY gasEmergencyChanged)
    Q_PROPERTY(QString gasLeakRoomName READ gasLeakRoomName NOTIFY gasEmergencyChanged)
    Q_PROPERTY(QVector3D gasStationPosition READ gasStationPosition NOTIFY gasEmergencyChanged)

    // Level 1: Shootable Power Relays & Laser Cage (Key 2: Shooting Gallery)
    Q_PROPERTY(bool laserCageActive READ isLaserCageActive NOTIFY laserCageChanged)
    Q_PROPERTY(int relaysRemaining READ relaysRemaining NOTIFY relaysChanged)
    Q_PROPERTY(QVariantList powerRelays READ powerRelays NOTIFY relaysChanged)

    // Level 1: 4-Digit Environmental Code (Exit Elevator)
    Q_PROPERTY(int k1Digit READ k1Digit CONSTANT)
    Q_PROPERTY(int k2Digit READ k2Digit CONSTANT)
    Q_PROPERTY(int k3Digit READ k3Digit CONSTANT)
    Q_PROPERTY(int k4Digit READ k4Digit CONSTANT)
    Q_PROPERTY(QString overrideCode READ overrideCode CONSTANT)
    Q_PROPERTY(bool overrideCodeSolved READ isOverrideCodeSolved NOTIFY overrideCodeSolvedChanged)
    Q_PROPERTY(bool keypadVisible READ isKeypadVisible WRITE setKeypadVisible NOTIFY keypadVisibleChanged)

    // Level 1: Sprint-Triggered Sensors & Storage Ambush
    Q_PROPERTY(QVariantList sprintSensors READ sprintSensors NOTIFY sprintSensorsChanged)
    Q_PROPERTY(bool storageAmbushTriggered READ isStorageAmbushTriggered NOTIFY storageAmbushTriggeredChanged)

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

    // Mission Key & Extraction getters (Day 2)
    int collectedKeysCount() const;
    int collectedKeysCountForLevel(int level) const;
    int totalKeysRequired() const;
    int collectedKeysMask() const;
    int collectedKeysMaskForLevel(int level) const;
    QVariantList levelKeys() const;
    BossArena* bossArena() const;
    void setBossArena(BossArena *arena);
    PuzzleManager* puzzleManager() const;
    void setPuzzleManager(PuzzleManager *pm);
    bool isBossCompleted() const;
    int activeVentsRemaining() const;
    bool isExtractionAvailable() const;

    // Player Count & Variant API
    int playerCount() const;
    void setPlayerCount(int count);
    int level1Variant() const;

    // Gas Emergency API
    bool isGasLeakActive() const;
    float gasLeakTimeRemaining() const;
    int gasLeakRepairStage() const;
    QString gasLeakRoomName() const;
    QVector3D gasStationPosition() const;

    Q_INVOKABLE void interactGasStation(const QVector3D &playerPos);
    Q_INVOKABLE void updateGasEmergency(float deltaTime, Player *player = nullptr);
    Q_INVOKABLE void triggerGasLeakEmergency();
    Q_INVOKABLE void purgeGasEmergency();
    Q_INVOKABLE void resetGasEmergency();

    // Level progression actions
    Q_INVOKABLE void loadLevel(int levelIndex, bool resetLevelKeys = true);
    Q_INVOKABLE void advanceLevel();
    Q_INVOKABLE void resetToFirstLevel();

    // Level 1: Multi-height queries
    Q_INVOKABLE float getFloorHeight(int row, int col) const;
    Q_INVOKABLE float getCeilingHeight(int row, int col) const;
    Q_INVOKABLE float getFloorHeightAtWorldPos(float x, float z) const;
    Q_INVOKABLE float getCeilingHeightAtWorldPos(float x, float z) const;

    // Level 1: Shootable Power Relays & Laser Cage (Key 2: Shooting Gallery)
    bool isLaserCageActive() const;
    int relaysRemaining() const;
    QVariantList powerRelays() const;
    int checkRayHitRelays(const QVector3D &origin, const QVector3D &dir, float &outHitDist);
    Q_INVOKABLE bool destroyRelay(int index);

    // Level 1: 4-Digit Environmental Code & Keypad Overlay (Exit Elevator)
    int k1Digit() const;
    int k2Digit() const;
    int k3Digit() const;
    int k4Digit() const;
    QString overrideCode() const;
    bool isOverrideCodeSolved() const;
    bool isKeypadVisible() const;
    void setKeypadVisible(bool visible);
    Q_INVOKABLE bool submitOverrideCode(const QString &code);
    Q_INVOKABLE void openExitKeypad();
    Q_INVOKABLE void closeExitKeypad();

    // Level 1: Sprint-Triggered Corridor Sensors & Storage Ambush
    QVariantList sprintSensors() const;
    bool isStorageAmbushTriggered() const;
    Q_INVOKABLE void updateSensors(float deltaTime, const QVector3D &playerPos, bool isSprinting, EnemyManager *enemyMgr = nullptr);
    Q_INVOKABLE void checkStorageAmbush(const QVector3D &playerPos, EnemyManager *enemyMgr = nullptr);
    Q_INVOKABLE void spawnLevel1DynamicEnemies(EnemyManager *enemyManager);

    // Mission key progression API (Day 2 - authoritative 4-bit mask per level)
    Q_INVOKABLE bool hasKey(int keyIndex, int level = -1) const;
    Q_INVOKABLE bool hasAllKeys(int level = -1) const;
    Q_INVOKABLE bool collectKey(int keyIndex, bool playerAlive = true);
    Q_INVOKABLE void resetCurrentLevelKeys();
    Q_INVOKABLE void resetMissionKeys(int level);
    Q_INVOKABLE void resetAllCampaignKeys();
    Q_INVOKABLE AccessKeyPickup* addKey(int row, int col, int keyIndex, const QString &name = QString());
    Q_INVOKABLE void clearKeys();
    Q_INVOKABLE void updateKeys(float deltaTime, const QVector3D &playerPos, bool playerAlive = true);
    Q_INVOKABLE void syncKeysFromMask();
    Q_INVOKABLE void setBossProgress(int activeVentsRemaining, bool bossCompleted);

    // Tile grid queries
    Q_INVOKABLE int getTile(int row, int col) const;
    Q_INVOKABLE int getTileAtWorldPos(float x, float z) const;
    Q_INVOKABLE bool isStaticSolidTile(int row, int col) const;
    Q_INVOKABLE bool isSolidTile(int row, int col) const;
    Q_INVOKABLE QByteArray getMapData() const;

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
                                 EnemyManager *enemyManager = nullptr,
                                 bool playerAlive = true);
    Q_INVOKABLE bool interactWithTargetDoor(const QVector3D &playerPos,
                                            EnemyManager *enemyManager = nullptr,
                                            bool playerAlive = true);

    bool evaluateDoorAccess(const Door *door, QString &outDenyReason) const;

    // Exit tile trigger detection called each frame
    Q_INVOKABLE bool checkExitReached(const QVector3D &playerPos, bool playerAlive = true);

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

    // Mission Key & Extraction signals (Day 2)
    void missionKeysChanged(int level, int collectedCount, int keyMask);
    void keyCollected(int keyIndex, const QString &keyName, int collectedCount, int totalRequired);
    void levelKeysChanged();
    void bossArenaChanged();
    void puzzleManagerChanged();
    void missionProgressChanged();
    void playerCountChanged(int count);
    void level1VariantChanged(int variant);
    void gasEmergencyChanged();
    void gasEmergencyTriggered();
    void gasEmergencyResolved();
    void gasEmergencyFatal();

    // Level 1 signals
    void laserCageChanged();
    void relaysChanged();
    void overrideCodeSolvedChanged();
    void keypadVisibleChanged();
    void sprintSensorsChanged();
    void sensorTripped(int sensorIndex, const QVector3D &pos);
    void storageAmbushTriggeredChanged();
    void storageAmbushTriggered();

private:
    void rebuildDoorsForLevel(int level);
    void rebuildKeysForLevel(int level);
    int popcount4(int mask) const;
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
    bool m_exitDenyNotified;
    bool m_loadingBayTriggered;
    bool m_heavyWeaponCollected;
    QSet<int> m_consumedAmmoTiles;
    QSet<int> m_triggeredTraps;

    int m_playerCount;
    int m_level1Variant;

    // Gas Emergency
    float m_levelTime;
    float m_gasLeakTriggerTime;
    bool m_gasLeakActive;
    bool m_gasLeakResolved;
    float m_gasLeakTimeRemaining;
    int m_gasLeakRepairStage;
    QVector3D m_gasStationPos;
    QString m_gasLeakRoomName;

    QList<Door*> m_doors;
    QHash<int, Door*> m_doorTileLookup;
    QPointer<Door> m_targetDoor;
    QString m_interactionPrompt;

    std::array<int, 4> m_keyMasks;
    QList<AccessKeyPickup*> m_levelKeys;
    QPointer<BossArena> m_bossArena;
    QPointer<PuzzleManager> m_puzzleManager;
    QMetaObject::Connection m_ventsConn;
    QMetaObject::Connection m_bossConn;
    bool m_bossCompleted;
    int m_activeVentsRemaining;

    // Level 1: Power Relays & Laser Cage
    struct RelayTarget {
        QVector3D position;
        bool destroyed = false;
        float radius = 60.0f;
    };
    QList<RelayTarget> m_powerRelays;
    bool m_laserCageActive;

    // Level 1: 4-Digit Environmental Code
    int m_k1Digit;
    int m_k2Digit;
    int m_k3Digit;
    int m_k4Digit;
    QString m_overrideCode;
    bool m_overrideCodeSolved;
    bool m_keypadVisible;

    // Level 1: Sprint Sensors & Storage Ambush
    struct SensorItem {
        QVector3D position;
        float z = 0.0f;
        float cooldown = 0.0f;
        bool tripped = false;
    };
    QList<SensorItem> m_sprintSensors;
    bool m_storageAmbushTriggered;
};

#endif // LEVELMANAGER_H
