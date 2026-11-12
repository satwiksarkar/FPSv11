#include "CoolingVent.h"
#include <QDebug>
#include <QtMath>
#include <algorithm>

CoolingVent::CoolingVent(int index, const QVector3D &pos, QObject *parent)
    : QObject(parent)
    , m_ventIndex(index)
    , m_position(pos)
    , m_health(GameConfig::COOLING_VENT_HEALTH)
    , m_maxHealth(GameConfig::COOLING_VENT_HEALTH)
    , m_isDestroyed(false)
{
}

QVector3D CoolingVent::position() const
{
    return m_position;
}

void CoolingVent::setPosition(const QVector3D &pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
    }
}

int CoolingVent::health() const
{
    return m_health;
}

int CoolingVent::maxHealth() const
{
    return m_maxHealth;
}

bool CoolingVent::isDestroyed() const
{
    return m_isDestroyed;
}

int CoolingVent::ventIndex() const
{
    return m_ventIndex;
}

void CoolingVent::setVentIndex(int index)
{
    if (m_ventIndex != index) {
        m_ventIndex = index;
        emit ventIndexChanged();
    }
}

void CoolingVent::takeDamage(int amount)
{
    if (m_isDestroyed || amount <= 0) {
        return;
    }

    m_health = qMax(0, m_health - amount);
    emit healthChanged(m_health);
    emit damaged(amount, m_health);

    qDebug() << "[CoolingVent" << m_ventIndex << "] Took" << amount << "damage! HP:" << m_health << "/" << m_maxHealth;

    if (m_health <= 0 && !m_isDestroyed) {
        m_isDestroyed = true;
        emit isDestroyedChanged();
        emit destroyed();
        qDebug() << "[CoolingVent" << m_ventIndex << "] DESTROYED! Coolant ruptured.";
    }
}

void CoolingVent::reset()
{
    m_health = m_maxHealth;
    m_isDestroyed = false;
    emit healthChanged(m_health);
    emit isDestroyedChanged();
}

bool CoolingVent::checkRaycastHit(const QVector3D &rayOrigin, const QVector3D &rayDir, float &outDist) const
{
    if (m_isDestroyed) {
        return false;
    }

    // Cooling vent bounding box: ~90x180x90 units centered at m_position
    QVector3D boxMin(m_position.x() - 45.0f, 0.0f, m_position.z() - 45.0f);
    QVector3D boxMax(m_position.x() + 45.0f, 180.0f, m_position.z() + 45.0f);

    return intersectRayAABB(rayOrigin, rayDir, boxMin, boxMax, outDist);
}

bool CoolingVent::intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                                    const QVector3D &boxMin, const QVector3D &boxMax,
                                    float &outDist) const
{
    float tmin = 0.0f;
    float tmax = 10000.0f;

    // Test X slab
    if (std::abs(dir.x()) > 1e-6f) {
        float invD = 1.0f / dir.x();
        float t0 = (boxMin.x() - origin.x()) * invD;
        float t1 = (boxMax.x() - origin.x()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.x() < boxMin.x() || origin.x() > boxMax.x()) return false;
    }

    // Test Y slab
    if (std::abs(dir.y()) > 1e-6f) {
        float invD = 1.0f / dir.y();
        float t0 = (boxMin.y() - origin.y()) * invD;
        float t1 = (boxMax.y() - origin.y()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.y() < boxMin.y() || origin.y() > boxMax.y()) return false;
    }

    // Test Z slab
    if (std::abs(dir.z()) > 1e-6f) {
        float invD = 1.0f / dir.z();
        float t0 = (boxMin.z() - origin.z()) * invD;
        float t1 = (boxMax.z() - origin.z()) * invD;
        if (t0 > t1) std::swap(t0, t1);
        tmin = std::max(tmin, t0);
        tmax = std::min(tmax, t1);
        if (tmax < tmin) return false;
    } else {
        if (origin.z() < boxMin.z() || origin.z() > boxMax.z()) return false;
    }

    outDist = tmin;
    return true;
}
