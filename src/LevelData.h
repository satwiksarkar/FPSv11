#ifndef LEVELDATA_H
#define LEVELDATA_H

#include <QString>
#include <QVector3D>
#include <QList>
#include <QPair>

namespace TileCode {
    constexpr int Empty = 0;              // empty floor
    constexpr int Wall = 1;               // solid wall (outer boundary / reinforced steel / pillars)
    constexpr int Crate = 2;              // stacked metal shipping crate (solid obstacle)
    constexpr int PlayerSpawn = 3;        // player spawn tile (one per level)
    constexpr int Level1Exit = 4;         // Level 1 exit tile (extraction elevator)
    constexpr int AmmoPickup = 5;         // ammo pickup tile
    constexpr int Level2Exit = 6;         // Level 2 exit tile (descent shaft)
    constexpr int HeavyWeaponPickup = 7;  // heavy weapon pickup tile (one in Level 2)
    constexpr int TriggerTrap = 8;        // invisible trigger tile (Level 2 crossfire trap; floor)
    constexpr int CoreWall = 9;           // VANGUARD core wall tile (Level 3, solid, armored)
    constexpr int Door = 10;              // interactive door aperture (solid when closed)
    constexpr int Level3Exit = 11;        // Level 3 exit tile (extraction pad)
    constexpr int DoorPocket = 12;        // recessed sliding door pocket housing (solid)
}

struct DoorDef {
    int id = 0;
    int row = 0;
    int col = 0;
    float axis = 0.0f;           // 0.0 = N-S passage (wall along X), 90.0 = E-W passage (wall along Z)
    int doorType = 0;            // matches Door::DoorType
    int requiredKeyIndex = -1;   // 0..3 for KeyLocked, -1 otherwise
    int requiredKeyCount = 0;    // minimum keys required for AreaLocked/MainExit
    int requiredKeyMask = 0;     // optional specific key bitmask
    bool requiresBossDefeated = false;
    QString label;
};

struct PickupItemDef {
    QVector3D position;
    int itemType; // 0=FoodPack, 1=Bandage, 2=Medkit
    QString name;
};

/**
 * @brief LevelData manages all map definitions, story briefings, entity spawn positions,
 * and BFS reachability checks for Project VANGUARD.
 */
class LevelData
{
public:
    static constexpr int LEVEL1_SIZE = 32;
    static constexpr int LEVEL2_SIZE = 64;
    static constexpr int LEVEL3_SIZE = 40;
    static constexpr int TEST_MAP_SIZE = 16;

    static QString getStoryTitle(int level);
    static QString getStoryText(int level);
    static QString getLevelName(int level);

    static int getMapWidth(int level);
    static int getMapHeight(int level);
    static int getTile(int level, int row, int col);
    static QVector3D getSpawnPoint(int level);
    static QVector3D getExitCenterPosition(int level);
    static int getExitTileCode(int level);

    // BFS reachability verification from spawn to exit / boss vents
    static bool checkReachability(int level, QString &outLog);

    // Level 1 entity spawns
    static QList<QVector3D> getLevel1CorridorDroneSpawns();
    static QList<QVector3D> getLevel1LoadingBayDroneSpawns();
    static QList<PickupItemDef> getLevel1Pickups();

    // Level 2 entity spawns & cache
    static QList<QVector3D> getLevel2SentinelSpawns();
    static QList<QVector3D> getLevel2DroneSpawns();
    static QList<PickupItemDef> getLevel2Pickups();
    static QVector3D getLevel2HeavyWeaponSpawn();

    // Level 3 entity spawns & pickups
    static QList<QVector3D> getLevel3VentPositions();
    static QList<QVector3D> getLevel3PerimeterDroneSpawns();
    static QList<PickupItemDef> getLevel3Pickups();
    static QVector3D getLevel3CoreCenter();

    // Door definitions per level (populated in Day 3 map redesign)
    static QList<DoorDef> getLevelDoors(int level);

    // Map arrays
    static const int level1[LEVEL1_SIZE][LEVEL1_SIZE];
    static const int level2[LEVEL2_SIZE][LEVEL2_SIZE];
    static const int level3[LEVEL3_SIZE][LEVEL3_SIZE];
    static const int testLevel1[TEST_MAP_SIZE][TEST_MAP_SIZE];
    static const int testLevel2[TEST_MAP_SIZE][TEST_MAP_SIZE];
};

#endif // LEVELDATA_H
