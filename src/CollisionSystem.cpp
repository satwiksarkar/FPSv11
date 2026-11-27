#include "CollisionSystem.h"
#include "LevelManager.h"
#include "PuzzleManager.h"
#include "GameConfig.h"
#include <QtMath>
#include <algorithm>
#include <cmath>
#include <QDebug>

static QList<AABB> getLevelObstacles(const LevelManager *lm)
{
    QList<AABB> obs;
    if (!lm || lm->currentLevel() != 1) return obs;

    // 1. Key 1 Armored Wall Vault Enclosure
    // West Back Wall: position (520, 110, 3150), scale (0.2, 2.2, 2.2) -> X: [510, 530], Z: [3040, 3260]
    obs.append({ QVector3D(510.0f, 0.0f, 3040.0f), QVector3D(530.0f, 220.0f, 3260.0f), QStringLiteral("VaultWest") });
    // North Vault Wall: position (635, 110, 3050), scale (2.1, 2.2, 0.2) -> X: [530, 740], Z: [3040, 3060]
    obs.append({ QVector3D(530.0f, 0.0f, 3040.0f), QVector3D(740.0f, 220.0f, 3060.0f), QStringLiteral("VaultNorth") });
    // South Vault Wall: position (635, 110, 3250), scale (2.1, 2.2, 0.2) -> X: [530, 740], Z: [3240, 3260]
    obs.append({ QVector3D(530.0f, 0.0f, 3240.0f), QVector3D(740.0f, 220.0f, 3260.0f), QStringLiteral("VaultSouth") });

    // Front Sliding Vault Door at X=740
    bool riddleSolved = false;
    if (lm->puzzleManager()) {
        riddleSolved = lm->puzzleManager()->isRiddleSolved();
    }
    if (!riddleSolved) {
        // Closed door blocks entrance Z: 3060..3240
        obs.append({ QVector3D(725.0f, 0.0f, 3060.0f), QVector3D(755.0f, 220.0f, 3240.0f), QStringLiteral("VaultDoorClosed") });
    } else {
        // Open door slid south to Z: 3270..3450
        obs.append({ QVector3D(725.0f, 0.0f, 3270.0f), QVector3D(755.0f, 220.0f, 3450.0f), QStringLiteral("VaultDoorOpen") });
    }

    // 2. Key 2 Shooting Gallery Waist-High Barricades (Height: 0..120)
    // Row 1 (Z=2850)
    obs.append({ QVector3D(3470.0f, 0.0f, 2830.0f), QVector3D(3630.0f, 120.0f, 2870.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(3770.0f, 0.0f, 2830.0f), QVector3D(3930.0f, 120.0f, 2870.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(4080.0f, 0.0f, 2830.0f), QVector3D(4220.0f, 120.0f, 2870.0f), QStringLiteral("Barricade") });
    // Row 2 (Z=3150)
    obs.append({ QVector3D(3370.0f, 0.0f, 3130.0f), QVector3D(3530.0f, 120.0f, 3170.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(3670.0f, 0.0f, 3130.0f), QVector3D(3830.0f, 120.0f, 3170.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(3970.0f, 0.0f, 3130.0f), QVector3D(4130.0f, 120.0f, 3170.0f), QStringLiteral("Barricade") });
    // Row 3 (Z=3450)
    obs.append({ QVector3D(3470.0f, 0.0f, 3430.0f), QVector3D(3630.0f, 120.0f, 3470.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(3770.0f, 0.0f, 3430.0f), QVector3D(3930.0f, 120.0f, 3470.0f), QStringLiteral("Barricade") });
    obs.append({ QVector3D(4080.0f, 0.0f, 3430.0f), QVector3D(4220.0f, 120.0f, 3470.0f), QStringLiteral("Barricade") });

    // 3. Storage Room Industrial Cargo Shipping Containers
    // Red Tall Container: position (1950, 150, 850), scale (1.8, 3.0, 1.2) -> X: [1860, 2040], Y: [0, 300], Z: [790, 910]
    obs.append({ QVector3D(1860.0f, 0.0f, 790.0f), QVector3D(2040.0f, 300.0f, 910.0f), QStringLiteral("StorageRedContainer") });
    // Blue Tall Container: position (2750, 150, 850), scale (1.8, 3.0, 1.2) -> X: [2660, 2840], Y: [0, 300], Z: [790, 910]
    obs.append({ QVector3D(2660.0f, 0.0f, 790.0f), QVector3D(2840.0f, 300.0f, 910.0f), QStringLiteral("StorageBlueContainer") });
    // Orange Medium Container: position (2150, 100, 1150), scale (1.2, 2.0, 1.2) -> X: [2090, 2210], Y: [0, 200], Z: [1090, 1210]
    obs.append({ QVector3D(2090.0f, 0.0f, 1090.0f), QVector3D(2210.0f, 200.0f, 1210.0f), QStringLiteral("StorageOrangeContainer") });
    // Green Medium Container: position (2550, 100, 1150), scale (1.2, 2.0, 1.2) -> X: [2490, 2610], Y: [0, 200], Z: [1090, 1210]
    obs.append({ QVector3D(2490.0f, 0.0f, 1090.0f), QVector3D(2610.0f, 200.0f, 1210.0f), QStringLiteral("StorageGreenContainer") });

    return obs;
}

CollisionSystem::CollisionSystem(QObject *parent)
    : QObject(parent)
{
}

void CollisionSystem::addBox(const QVector3D &min, const QVector3D &max, const QString &tag)
{
    m_colliders.append(AABB{min, max, tag});
}

void CollisionSystem::clear()
{
    m_colliders.clear();
}

int CollisionSystem::count() const
{
    return m_colliders.size();
}

void CollisionSystem::buildFromLevel(LevelManager *levelManager)
{
    clear();
    m_levelManager = levelManager;
    if (!levelManager) return;

    int mapWidth = levelManager->mapWidth();
    int mapHeight = levelManager->mapHeight();
    float blockSize = levelManager->blockSize();

    for (int row = 0; row < mapHeight; ++row) {
        for (int col = 0; col < mapWidth; ++col) {
            int tile = levelManager->getTile(row, col);
            if (tile == TileCode::Wall || tile == TileCode::CoreWall) {
                float minX = col * blockSize;
                float minZ = row * blockSize;
                float maxX = (col + 1) * blockSize;
                float maxZ = (row + 1) * blockSize;
                addBox(QVector3D(minX, 0.0f, minZ), QVector3D(maxX, GameConfig::WALL_HEIGHT, maxZ), QStringLiteral("Wall"));
            } else if (tile == TileCode::Crate) {
                float minX = col * blockSize;
                float minZ = row * blockSize;
                float maxX = (col + 1) * blockSize;
                float maxZ = (row + 1) * blockSize;
                addBox(QVector3D(minX, 0.0f, minZ), QVector3D(maxX, GameConfig::CRATE_HEIGHT, maxZ), QStringLiteral("Crate"));
            }
        }
    }

    if (GameConfig::DEBUG_LOG_TILE_COUNTS) {
        qDebug() << "[CollisionSystem] Built" << m_colliders.size() << "colliders for Level"
                 << levelManager->currentLevel() << "Grid:" << mapWidth << "x" << mapHeight;
    }
}

QVector3D CollisionSystem::resolveMovement(const QVector3D &currentPos, const QVector3D &targetPos, float radius) const
{
    QVector3D pos = currentPos;
    QVector3D delta = targetPos - currentPos;
    float dist = std::sqrt(delta.x() * delta.x() + delta.z() * delta.z());

    int steps = std::max(1, static_cast<int>(std::ceil(dist / (radius * 0.5f))));
    QVector3D stepDelta = delta / static_cast<float>(steps);

    if (m_levelManager) {
        float blockSize = m_levelManager->blockSize();
        int mapW = m_levelManager->mapWidth();
        int mapH = m_levelManager->mapHeight();
        QList<AABB> levelObstacles = getLevelObstacles(m_levelManager);

        for (int step = 0; step < steps; ++step) {
            // 1. Resolve X axis movement independently (allows smooth sliding along Z walls)
            float nextX = pos.x() + stepDelta.x();
            float currentZ = pos.z();

            int minCol = std::max(0, static_cast<int>(std::floor((nextX - radius - 5.0f) / blockSize)));
            int maxCol = std::min(mapW - 1, static_cast<int>(std::floor((nextX + radius + 5.0f) / blockSize)));
            int minRow = std::max(0, static_cast<int>(std::floor((currentZ - radius - 5.0f) / blockSize)));
            int maxRow = std::min(mapH - 1, static_cast<int>(std::floor((currentZ + radius + 5.0f) / blockSize)));

            for (int r = minRow; r <= maxRow; ++r) {
                for (int c = minCol; c <= maxCol; ++c) {
                    if (m_levelManager->isSolidTile(r, c)) {
                        float bMinX = c * blockSize;
                        float bMaxX = (c + 1) * blockSize;
                        float bMinZ = r * blockSize;
                        float bMaxZ = (r + 1) * blockSize;

                        float cX = std::clamp(nextX, bMinX, bMaxX);
                        float cZ = std::clamp(currentZ, bMinZ, bMaxZ);
                        float dx = nextX - cX;
                        float dz = currentZ - cZ;
                        float distSq = dx * dx + dz * dz;
                        if (distSq < radius * radius) {
                            if (distSq > 1e-6f) {
                                float d = std::sqrt(distSq);
                                float pen = radius - d;
                                nextX += (dx / d) * pen;
                            } else {
                                nextX = (stepDelta.x() >= 0.0f) ? (bMinX - radius - 0.1f) : (bMaxX + radius + 0.1f);
                            }
                        }
                    }
                }
            }

            for (const auto &box : levelObstacles) {
                if (targetPos.y() < box.max.y() && (targetPos.y() + 180.0f) > box.min.y()) {
                    float cX = std::clamp(nextX, box.min.x(), box.max.x());
                    float cZ = std::clamp(currentZ, box.min.z(), box.max.z());
                    float dx = nextX - cX;
                    float dz = currentZ - cZ;
                    float distSq = dx * dx + dz * dz;
                    if (distSq < radius * radius) {
                        if (distSq > 1e-6f) {
                            float d = std::sqrt(distSq);
                            float pen = radius - d;
                            nextX += (dx / d) * pen;
                        } else {
                            nextX = (stepDelta.x() >= 0.0f) ? (box.min.x() - radius - 0.1f) : (box.max.x() + radius + 0.1f);
                        }
                    }
                }
            }
            pos.setX(nextX);

            // 2. Resolve Z axis movement independently (allows smooth sliding along X walls)
            float currentX = pos.x();
            float nextZ = pos.z() + stepDelta.z();

            minCol = std::max(0, static_cast<int>(std::floor((currentX - radius - 5.0f) / blockSize)));
            maxCol = std::min(mapW - 1, static_cast<int>(std::floor((currentX + radius + 5.0f) / blockSize)));
            minRow = std::max(0, static_cast<int>(std::floor((nextZ - radius - 5.0f) / blockSize)));
            maxRow = std::min(mapH - 1, static_cast<int>(std::floor((nextZ + radius + 5.0f) / blockSize)));

            for (int r = minRow; r <= maxRow; ++r) {
                for (int c = minCol; c <= maxCol; ++c) {
                    if (m_levelManager->isSolidTile(r, c)) {
                        float bMinX = c * blockSize;
                        float bMaxX = (c + 1) * blockSize;
                        float bMinZ = r * blockSize;
                        float bMaxZ = (r + 1) * blockSize;

                        float cX = std::clamp(currentX, bMinX, bMaxX);
                        float cZ = std::clamp(nextZ, bMinZ, bMaxZ);
                        float dx = currentX - cX;
                        float dz = nextZ - cZ;
                        float distSq = dx * dx + dz * dz;
                        if (distSq < radius * radius) {
                            if (distSq > 1e-6f) {
                                float d = std::sqrt(distSq);
                                float pen = radius - d;
                                nextZ += (dz / d) * pen;
                            } else {
                                nextZ = (stepDelta.z() >= 0.0f) ? (bMinZ - radius - 0.1f) : (bMaxZ + radius + 0.1f);
                            }
                        }
                    }
                }
            }

            for (const auto &box : levelObstacles) {
                if (targetPos.y() < box.max.y() && (targetPos.y() + 180.0f) > box.min.y()) {
                    float cX = std::clamp(currentX, box.min.x(), box.max.x());
                    float cZ = std::clamp(nextZ, box.min.z(), box.max.z());
                    float dx = currentX - cX;
                    float dz = nextZ - cZ;
                    float distSq = dx * dx + dz * dz;
                    if (distSq < radius * radius) {
                        if (distSq > 1e-6f) {
                            float d = std::sqrt(distSq);
                            float pen = radius - d;
                            nextZ += (dz / d) * pen;
                        } else {
                            nextZ = (stepDelta.z() >= 0.0f) ? (box.min.z() - radius - 0.1f) : (box.max.z() + radius + 0.1f);
                        }
                    }
                }
            }
            pos.setZ(nextZ);
        }

        // Enforce map boundary clamping so player can never slip through perimeter walls
        float minBound = radius + 2.0f;
        float maxXBound = (mapW * blockSize) - radius - 2.0f;
        float maxZBound = (mapH * blockSize) - radius - 2.0f;
        pos.setX(qBound(minBound, pos.x(), maxXBound));
        pos.setZ(qBound(minBound, pos.z(), maxZBound));
        pos.setY(targetPos.y());
        return pos;
    }

    // Fallback if no LevelManager: iterate registered colliders
    for (int step = 0; step < steps; ++step) {
        float nextX = pos.x() + stepDelta.x();
        float currentZ = pos.z();
        for (const auto &box : m_colliders) {
            float cX = std::clamp(nextX, box.min.x(), box.max.x());
            float cZ = std::clamp(currentZ, box.min.z(), box.max.z());
            float dx = nextX - cX;
            float dz = currentZ - cZ;
            float distSq = dx * dx + dz * dz;
            if (distSq < radius * radius) {
                if (distSq > 1e-6f) {
                    float d = std::sqrt(distSq);
                    float pen = radius - d;
                    nextX += (dx / d) * pen;
                } else {
                    nextX = (stepDelta.x() >= 0.0f) ? (box.min.x() - radius - 0.1f) : (box.max.x() + radius + 0.1f);
                }
            }
        }
        pos.setX(nextX);

        float currentX = pos.x();
        float nextZ = pos.z() + stepDelta.z();
        for (const auto &box : m_colliders) {
            float cX = std::clamp(currentX, box.min.x(), box.max.x());
            float cZ = std::clamp(nextZ, box.min.z(), box.max.z());
            float dx = currentX - cX;
            float dz = nextZ - cZ;
            float distSq = dx * dx + dz * dz;
            if (distSq < radius * radius) {
                if (distSq > 1e-6f) {
                    float d = std::sqrt(distSq);
                    float pen = radius - d;
                    nextZ += (dz / d) * pen;
                } else {
                    nextZ = (stepDelta.z() >= 0.0f) ? (box.min.z() - radius - 0.1f) : (box.max.z() + radius + 0.1f);
                }
            }
        }
        pos.setZ(nextZ);
    }

    pos.setY(targetPos.y());
    return pos;
}

bool CollisionSystem::raycastDDA(LevelManager *levelManager,
                                const QVector3D &origin,
                                const QVector3D &direction,
                                float maxDist,
                                float &outDist,
                                QVector3D &outHitPos,
                                int &outHitTile,
                                bool includeDoors) const
{
    if (!levelManager) {
        return false;
    }

    QVector3D dir = direction.normalized();
    if (dir.isNull()) {
        return false;
    }

    float blockSize = levelManager->blockSize();
    int mapW = levelManager->mapWidth();
    int mapH = levelManager->mapHeight();

    auto isBlockingCell = [&](int r, int c) -> bool {
        return includeDoors ? levelManager->isSolidTile(r, c)
                            : levelManager->isStaticSolidTile(r, c);
    };

    // Starting tile coordinate
    int col = qFloor(origin.x() / blockSize);
    int row = qFloor(origin.z() / blockSize);

    // If starting inside a solid tile
    if (col >= 0 && col < mapW && row >= 0 && row < mapH && isBlockingCell(row, col)) {
        outDist = 0.0f;
        outHitPos = origin;
        outHitTile = levelManager->getTile(row, col);
        return true;
    }

    // Direction signs
    int stepX = (dir.x() >= 0.0f) ? 1 : -1;
    int stepZ = (dir.z() >= 0.0f) ? 1 : -1;

    // Distance the ray travels to cross one grid cell in X and Z
    float dx = dir.x();
    float dz = dir.z();
    float tDeltaX = (std::abs(dx) > 1e-6f) ? std::abs(blockSize / dx) : 1e9f;
    float tDeltaZ = (std::abs(dz) > 1e-6f) ? std::abs(blockSize / dz) : 1e9f;

    // Initial ray distance to the first boundary intersection
    float nextBoundaryX = (stepX > 0) ? (col + 1) * blockSize : col * blockSize;
    float nextBoundaryZ = (stepZ > 0) ? (row + 1) * blockSize : row * blockSize;
    float tMaxX = (std::abs(dx) > 1e-6f) ? (nextBoundaryX - origin.x()) / dx : 1e9f;
    float tMaxZ = (std::abs(dz) > 1e-6f) ? (nextBoundaryZ - origin.z()) / dz : 1e9f;

    float t = 0.0f;
    while (t < maxDist) {
        if (tMaxX < tMaxZ) {
            t = tMaxX;
            tMaxX += tDeltaX;
            col += stepX;
        } else {
            t = tMaxZ;
            tMaxZ += tDeltaZ;
            row += stepZ;
        }

        if (t > maxDist) {
            break;
        }

        if (col < 0 || col >= mapW || row < 0 || row >= mapH) {
            break;
        }

        if (isBlockingCell(row, col)) {
            outDist = t;
            outHitPos = origin + dir * t;
            outHitTile = levelManager->getTile(row, col);
            return true;
        }
    }

    return false;
}

bool CollisionSystem::intersectRayBox(const QVector3D &origin, const QVector3D &dir, const QVector3D &bMin, const QVector3D &bMax, float &outDist) const
{
    float tmin = 0.0f;
    float tmax = 10000.0f;

    if (std::abs(dir.x()) > 1e-6f) {
        float invD = 1.0f / dir.x();
        float t0 = (bMin.x() - origin.x()) * invD;
        float t1 = (bMax.x() - origin.x()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.x() < bMin.x() || origin.x() > bMax.x()) return false;
    }

    if (std::abs(dir.y()) > 1e-6f) {
        float invD = 1.0f / dir.y();
        float t0 = (bMin.y() - origin.y()) * invD;
        float t1 = (bMax.y() - origin.y()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.y() < bMin.y() || origin.y() > bMax.y()) return false;
    }

    if (std::abs(dir.z()) > 1e-6f) {
        float invD = 1.0f / dir.z();
        float t0 = (bMin.z() - origin.z()) * invD;
        float t1 = (bMax.z() - origin.z()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.z() < bMin.z() || origin.z() > bMax.z()) return false;
    }

    outDist = tmin;
    return true;
}

bool CollisionSystem::raycast(const QVector3D &origin, const QVector3D &direction, float maxDist, float &outDist, QString &outTag) const
{
    float nearestDist = maxDist;
    bool hitAny = false;

    if (m_levelManager) {
        QVector3D hitPos;
        int hitTile = 0;
        float ddaDist = maxDist;
        if (raycastDDA(m_levelManager, origin, direction, maxDist, ddaDist, hitPos, hitTile)) {
            nearestDist = ddaDist;
            outTag = (hitTile == TileCode::Crate) ? QStringLiteral("Crate") : QStringLiteral("Wall");
            hitAny = true;
        }

        // Also test rays against custom Level obstacles (vault walls, closed door, barricades)
        QList<AABB> levelObstacles = getLevelObstacles(m_levelManager);
        for (const auto &box : levelObstacles) {
            float d = 0.0f;
            if (intersectRayBox(origin, direction, box.min, box.max, d)) {
                if (d < nearestDist && d > 0.0f) {
                    nearestDist = d;
                    outTag = box.tag;
                    hitAny = true;
                }
            }
        }

        if (hitAny) {
            outDist = nearestDist;
            return true;
        }
        return false;
    }

    for (const auto &box : m_colliders) {
        // If ray origin is inside a solid collider, the ray is immediately blocked at distance 0
        if (origin.x() >= box.min.x() && origin.x() <= box.max.x() &&
            origin.y() >= box.min.y() && origin.y() <= box.max.y() &&
            origin.z() >= box.min.z() && origin.z() <= box.max.z()) {
            outDist = 0.0f;
            outTag = box.tag;
            return true;
        }

        float d = 0.0f;
        if (intersectRayBox(origin, direction, box.min, box.max, d)) {
            if (d < nearestDist && d > 0.0f) {
                nearestDist = d;
                outTag = box.tag;
                hitAny = true;
            }
        }
    }

    if (hitAny) {
        outDist = nearestDist;
        return true;
    }
    return false;
}
