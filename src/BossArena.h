#ifndef BOSSARENA_H
#define BOSSARENA_H

#include <QObject>
#include <QVector3D>
#include <QList>
#include <QtQml/qqmlregistration.h>
#include "CoolingVent.h"
#include "EnemyManager.h"
#include "LevelManager.h"

/**
 * @brief The BossArena class manages the VANGUARD Mainframe logic, four Cooling Vents,
 * continuous perimeter Drone reinforcement waves, and campaign victory detection.
 */
class BossArena : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int activeVentsCount READ activeVentsCount NOTIFY ventsCountChanged)
    Q_PROPERTY(int totalVents READ totalVents CONSTANT)
    Q_PROPERTY(bool isBossDefeated READ isBossDefeated NOTIFY bossDefeatedChanged)
    Q_PROPERTY(QVector3D coreCenterPosition READ coreCenterPosition CONSTANT)
    Q_PROPERTY(int totalVentHp READ totalVentHp NOTIFY ventHpChanged)
    Q_PROPERTY(int maxTotalVentHp READ maxTotalVentHp CONSTANT)

public:
    explicit BossArena(QObject *parent = nullptr);

    int activeVentsCount() const;
    int totalVents() const;
    bool isBossDefeated() const;
    QVector3D coreCenterPosition() const;
    int totalVentHp() const;
    int maxTotalVentHp() const;

    Q_INVOKABLE CoolingVent* ventAt(int index) const;
    Q_INVOKABLE int ventCount() const;
    Q_INVOKABLE int ventHealth(int index) const;
    Q_INVOKABLE int ventMaxHealth(int index) const;
    Q_INVOKABLE bool isVentDestroyed(int index) const;

    Q_INVOKABLE void reset();

    // Frame update for Level 3 Drone spawner timer and victory checks
    Q_INVOKABLE void update(float deltaTime, EnemyManager *enemyManager, LevelManager *levelManager);

    // Hit test against active cooling vents
    CoolingVent* checkRayHitVents(const QVector3D &rayOrigin, const QVector3D &rayDir, float &outDist);

signals:
    void ventsCountChanged(int activeCount);
    void ventDestroyed(int ventIndex);
    void ventHpChanged();
    void bossDefeatedChanged(bool defeated);
    void bossDefeated();

private:
    void initVents();
    void updateVentCount();

    QList<CoolingVent*> m_vents;
    bool m_isBossDefeated;
    float m_spawnTimer;
    int m_spawnIndex;
};

#endif // BOSSARENA_H
