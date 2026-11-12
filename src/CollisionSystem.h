#ifndef COLLISIONSYSTEM_H
#define COLLISIONSYSTEM_H

#include <QObject>
#include <QVector3D>
#include <QList>
#include <QString>
#include <QtQml/qqmlregistration.h>

class LevelManager;

struct AABB {
    QVector3D min;
    QVector3D max;
    QString tag;

    bool contains2D(float x, float z, float radius = 0.0f) const {
        return (x + radius >= min.x() && x - radius <= max.x() &&
                z + radius >= min.z() && z - radius <= max.z());
    }
};

/**
 * @brief The CollisionSystem class manages tile collisions and DDA grid raycasts.
 * 
 * Provides:
 * 1. Axis-independent sliding collision resolution for player and enemies.
 * 2. High-performance 2D grid DDA raycasting for line-of-sight and bullet obstruction.
 */
class CollisionSystem : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit CollisionSystem(QObject *parent = nullptr);

    Q_INVOKABLE void addBox(const QVector3D &min, const QVector3D &max, const QString &tag = QString());
    Q_INVOKABLE void clear();
    Q_INVOKABLE int count() const;

    /**
     * @brief Populates colliders for all solid tiles in the given level map.
     */
    void buildFromLevel(LevelManager *levelManager);

    /**
     * @brief Resolves movement with circle-vs-box sliding pushback.
     */
    Q_INVOKABLE QVector3D resolveMovement(const QVector3D &currentPos, const QVector3D &targetPos, float radius = 35.0f) const;

    /**
     * @brief Fast Digital Differential Analyzer (DDA) grid raycaster.
     * Steps tile-by-tile through the grid to test line-of-sight and shot occlusion.
     * @param includeDoors When true (default), closed/blocking doors occlude the ray.
     *                     When false, only permanent static geometry (walls/crates/core/pockets) occludes.
     */
    bool raycastDDA(LevelManager *levelManager,
                    const QVector3D &origin,
                    const QVector3D &direction,
                    float maxDist,
                    float &outDist,
                    QVector3D &outHitPos,
                    int &outHitTile,
                    bool includeDoors = true) const;

    /**
     * @brief Tests a ray against registered AABB boxes.
     */
    bool raycast(const QVector3D &origin, const QVector3D &direction, float maxDist, float &outDist, QString &outTag) const;

private:
    bool intersectRayBox(const QVector3D &origin, const QVector3D &dir, const QVector3D &bMin, const QVector3D &bMax, float &outDist) const;

    QList<AABB> m_colliders;
    LevelManager *m_levelManager = nullptr;
};

#endif // COLLISIONSYSTEM_H
