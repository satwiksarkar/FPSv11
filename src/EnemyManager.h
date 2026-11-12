#ifndef ENEMYMANAGER_H
#define ENEMYMANAGER_H

#include "Enemy.h"
#include "GameConfig.h"
#include <QObject>
#include <QVector3D>
#include <QList>
#include <QtQml/qqmlregistration.h>

#include <QPointer>
#include "GameWorld.h"
#include "Player.h"
#include "GameManager.h"

/**
 * @brief The EnemyManager class manages an object pool of Enemy instances.
 *
 * Responsibilities:
 * - Pre-allocates a pool of MAX_ACTIVE_ENEMIES enemy objects (reused, never deleted mid-game).
 * - Spawns Drone and Sentinel enemies at given positions without exceeding the hard cap.
 * - Updates all active enemies each frame (skips when paused or StoryText).
 * - Provides hit detection across all active enemies for the player's weapon.
 * - Exposes enemy count and nearest enemy info to QML for HUD.
 */
class EnemyManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int activeCount READ activeCount NOTIFY activeCountChanged)
    Q_PROPERTY(int maxActive READ maxActive CONSTANT)
    Q_PROPERTY(int totalKills READ totalKills NOTIFY totalKillsChanged)

    // Nearest enemy info for HUD health bar
    Q_PROPERTY(int nearestEnemyHealth READ nearestEnemyHealth NOTIFY nearestEnemyChanged)
    Q_PROPERTY(int nearestEnemyMaxHealth READ nearestEnemyMaxHealth NOTIFY nearestEnemyChanged)
    Q_PROPERTY(bool nearestEnemyDead READ nearestEnemyDead NOTIFY nearestEnemyChanged)
    Q_PROPERTY(QString nearestEnemyState READ nearestEnemyState NOTIFY nearestEnemyChanged)
    Q_PROPERTY(QString nearestEnemyType READ nearestEnemyType NOTIFY nearestEnemyChanged)

public:
    explicit EnemyManager(QObject *parent = nullptr);

    // Pool access
    int activeCount() const;
    int maxActive() const;
    int totalKills() const;

    // Nearest enemy HUD info
    int nearestEnemyHealth() const;
    int nearestEnemyMaxHealth() const;
    bool nearestEnemyDead() const;
    QString nearestEnemyState() const;
    QString nearestEnemyType() const;

    // Lifecycle
    Q_INVOKABLE void setWorld(GameWorld *world);
    Q_INVOKABLE bool spawnDrone(const QVector3D &position);
    Q_INVOKABLE bool spawnSentinel(const QVector3D &position);
    Q_INVOKABLE void updateAll(float deltaTime, const QVector3D &playerPos,
                                Player *player, GameManager *gameManager);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void setTargetEnemy(Enemy *e);

    /**
     * @brief Checks all active enemies against a ray for hit detection.
     * @return The Enemy* that was hit (closest), or nullptr if none.
     */
    Enemy* checkRayHitAll(const QVector3D &rayOrigin, const QVector3D &rayDir,
                          bool &outIsHeadshot, float &outDistance);

    /**
     * @brief Returns the list of all enemy objects (for QML rendering).
     */
    Q_INVOKABLE QList<QObject*> getEnemyList() const;

    /**
     * @brief Returns enemy at index (for QML Repeater).
     */
    Q_INVOKABLE Enemy* enemyAt(int index) const;
    Q_INVOKABLE int poolSize() const;

signals:
    void activeCountChanged(int count);
    void totalKillsChanged(int kills);
    void nearestEnemyChanged();
    void enemyKilled(Enemy *enemy);
    void enemySpawned(Enemy *enemy);
    void enemyShotFired();
    void enemyBulletFired(const QVector3D &from, const QVector3D &targetPos, bool didHit);

private:
    Enemy* findInactiveEnemy(Enemy::EnemyType type);
    void updateNearestEnemy(const QVector3D &playerPos);

    QList<Enemy*> m_pool;
    GameWorld *m_world;
    int m_totalKills;

    // Cached nearest enemy info
    int m_nearestHealth;
    int m_nearestMaxHealth;
    bool m_nearestDead;
    QString m_nearestState;
    QString m_nearestType;

    // Target lock-on tracking for damaged bot HUD display
    QPointer<Enemy> m_targetEnemy;
    float m_targetTimer;
};

#endif // ENEMYMANAGER_H
