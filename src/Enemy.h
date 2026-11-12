#ifndef ENEMY_H
#define ENEMY_H

#include "HealthSystem.h"
#include "GameConfig.h"
#include <QObject>
#include <QString>
#include <QVector3D>
#include <QList>
#include <QPair>
#include <QtQml/qqmlregistration.h>

class GameWorld;
class Player;
class GameManager;
class LevelManager;

/**
 * @brief The Enemy class implements Drone and Sentinel enemy archetypes.
 *
 * Drone (melee chaser): IDLE → CHASE → ATTACK → DEAD
 *   - BFS pathfinding on the tile grid, melee damage when close.
 *
 * Sentinel (ranged gunner): GUARD → DETECT → AIM → SHOOT → SEARCH → DEAD
 *   - Detection by distance + grid line of sight, aim delay, shoot cooldown,
 *     accuracy percentage, visible bullet tracer, search last seen position.
 *
 * Both types use HealthSystem. BFS paths are recomputed every ~0.4s (never per frame).
 */
class Enemy : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    // --------------- Enemy Types ---------------
    enum class EnemyType { Drone, Sentinel };
    Q_ENUM(EnemyType)

    // --------------- State Machines ---------------
    // Drone states
    enum class DroneState { Idle, Chase, Attack, Dead };
    Q_ENUM(DroneState)

    // Sentinel states
    enum class SentinelState { Guard, Detect, Aim, Shoot, Search, Dead };
    Q_ENUM(SentinelState)

    // Combined state for QML display
    enum class EnemyState { Idle, Chase, Attack, Guard, Detect, Aim, Shoot, Search, Dead };
    Q_ENUM(EnemyState)

    Q_PROPERTY(EnemyType enemyType READ enemyType CONSTANT)
    Q_PROPERTY(QVector3D position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(float rotationY READ rotationY NOTIFY rotationChanged)
    Q_PROPERTY(HealthSystem* healthSystem READ healthSystem CONSTANT)
    Q_PROPERTY(int health READ health NOTIFY healthChanged)
    Q_PROPERTY(int maxHealth READ maxHealth CONSTANT)
    Q_PROPERTY(bool isDead READ isDead NOTIFY healthChanged)
    Q_PROPERTY(bool isActive READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(EnemyState state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString stateString READ stateString NOTIFY stateChanged)
    Q_PROPERTY(bool isAttacking READ isAttacking NOTIFY stateChanged)
    Q_PROPERTY(bool isShooting READ isShooting NOTIFY isShootingChanged)
    Q_PROPERTY(bool canShoot READ canShoot WRITE setCanShoot NOTIFY canShootChanged)
    Q_PROPERTY(bool isVisible READ isVisible NOTIFY visibleChanged)
    Q_PROPERTY(int scoreValue READ scoreValue CONSTANT)

    explicit Enemy(EnemyType type = EnemyType::Drone, QObject *parent = nullptr);

    // Subsystems
    HealthSystem* healthSystem() const;

    // Type
    EnemyType enemyType() const;

    // Getters
    QVector3D position() const;
    void setPosition(const QVector3D &pos);

    float rotationY() const;
    int health() const;
    int maxHealth() const;
    bool isDead() const;
    bool isActive() const;
    void setActive(bool active);
    bool isVisible() const;

    EnemyState state() const;
    QString stateString() const;
    bool isAttacking() const;
    bool isShooting() const;
    bool canShoot() const;
    void setCanShoot(bool canShoot);
    int scoreValue() const;

    // World reference
    GameWorld *world() const;
    void setWorld(GameWorld *world);

    // AI frame update
    void update(float deltaTime, const QVector3D &playerPos,
                Player *player, GameManager *gameManager);

    // Hit detection (for player shooting this enemy)
    bool checkRaycastHit(const QVector3D &rayOrigin, const QVector3D &rayDir,
                         bool &outIsHeadshot, float &outDistance) const;

    // Combat
    void takeDamage(int amount, bool isHeadshot = false);
    void reset();
    void respawn(const QVector3D &spawnPos);

signals:
    void positionChanged(const QVector3D &newPos);
    void rotationChanged(float newRotY);
    void healthChanged(int newHealth);
    void stateChanged(EnemyState newState);
    void attackedPlayer(int damage);
    void shotFired(const QVector3D &from, const QVector3D &targetPos, bool didHit);
    void isShootingChanged(bool shooting);
    void canShootChanged(bool canShoot);
    void activeChanged(bool active);
    void visibleChanged();
    void died();

private:
    // State machine updates
    void updateDrone(float deltaTime, const QVector3D &playerPos, Player *player);
    void updateSentinel(float deltaTime, const QVector3D &playerPos, Player *player);

    // BFS pathfinding on tile grid
    void computeBFSPath(const QVector3D &targetPos);
    QVector3D getNextPathTarget() const;

    // Line of sight via DDA grid ray
    bool hasLineOfSight(const QVector3D &targetPos) const;

    // AABB intersection helper
    bool intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                          const QVector3D &boxMin, const QVector3D &boxMax,
                          float &outDist) const;

    // Facing
    void faceTarget(const QVector3D &targetPos);

    // Movement along BFS path with collision
    void moveAlongPath(float deltaTime, float speed);

    // --------------- Member Data ---------------
    EnemyType m_type;
    HealthSystem *m_healthSystem;
    GameWorld *m_world;
    bool m_isActive;

    QVector3D m_position;
    float m_rotationY;

    // Drone FSM
    DroneState m_droneState;

    // Sentinel FSM
    SentinelState m_sentinelState;
    QVector3D m_lastSeenPlayerPos;
    float m_aimTimer;          // Time spent aiming before shooting
    float m_searchTimer;       // Time spent searching at last seen position

    // Shared timers
    float m_attackTimer;       // Cooldown between attacks/shots
    float m_pathfindTimer;     // Timer for BFS refresh (~0.4s)

    // Muzzle flash
    bool m_isShooting;
    float m_muzzleFlashTimer;
    bool m_canShoot;

    // BFS path
    QList<QPair<int,int>> m_bfsPath;  // List of (row, col) tiles
    int m_currentPathIndex;

    // Constants for this specific enemy (set based on type)
    int m_maxHp;
    float m_moveSpeed;
    float m_attackRange;
    float m_attackCooldown;
    int m_attackDamage;
    float m_detectRange;
    float m_shootRange;       // Sentinel only
    float m_hitChance;        // Sentinel only
    float m_aimDuration;      // Sentinel: time to aim before firing
    float m_searchDuration;   // Sentinel: time to search at last seen pos
    int m_scoreValue;
};

#endif // ENEMY_H
