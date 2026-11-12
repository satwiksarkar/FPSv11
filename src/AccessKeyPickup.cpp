#include "AccessKeyPickup.h"
#include <algorithm>
#include <cmath>

AccessKeyPickup::AccessKeyPickup(QObject *parent)
    : QObject(parent)
    , m_levelIndex(1)
    , m_keyIndex(0)
    , m_keyName(QStringLiteral("ACCESS KEY 1"))
    , m_position(0.0f, 35.0f, 0.0f)
    , m_collected(false)
    , m_rotationY(0.0f)
    , m_bobTimer(0.0f)
    , m_bobOffset(0.0f)
{
}

void AccessKeyPickup::configure(int levelIndex,
                                int keyIndex,
                                const QVector3D &position,
                                const QString &keyName)
{
    m_levelIndex = qBound(1, levelIndex, 3);
    m_keyIndex = qBound(0, keyIndex, 3);
    m_keyName = keyName.trimmed().isEmpty()
        ? QStringLiteral("ACCESS KEY %1").arg(m_keyIndex + 1)
        : keyName;
    m_position = position;
    m_rotationY = static_cast<float>(m_keyIndex * 45);
    m_bobTimer = static_cast<float>(m_keyIndex) * 0.8f;
    m_bobOffset = std::sin(m_bobTimer) * 7.0f;

    emit configChanged();
    emit positionChanged();
    emit bobOffsetChanged();
    emit rotationChanged();
    emit renderPositionChanged();
}

int AccessKeyPickup::keyIndex() const
{
    return m_keyIndex;
}

int AccessKeyPickup::levelIndex() const
{
    return m_levelIndex;
}

QString AccessKeyPickup::keyName() const
{
    return m_keyName;
}

QVector3D AccessKeyPickup::position() const
{
    return m_position;
}

void AccessKeyPickup::setPosition(const QVector3D &pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
        emit renderPositionChanged();
    }
}

QVector3D AccessKeyPickup::renderPosition() const
{
    return QVector3D(m_position.x(), m_position.y() + m_bobOffset, m_position.z());
}

bool AccessKeyPickup::isCollected() const
{
    return m_collected;
}

void AccessKeyPickup::setCollected(bool collected)
{
    if (m_collected != collected) {
        m_collected = collected;
        emit collectedChanged(m_collected);
    }
}

float AccessKeyPickup::rotationY() const
{
    return m_rotationY;
}

float AccessKeyPickup::bobOffset() const
{
    return m_bobOffset;
}

void AccessKeyPickup::update(float deltaTime)
{
    if (m_collected || deltaTime <= 0.0f) {
        return;
    }

    m_rotationY += 95.0f * deltaTime;
    if (m_rotationY >= 360.0f) {
        m_rotationY -= 360.0f;
    }
    emit rotationChanged();

    m_bobTimer += deltaTime * 2.8f;
    m_bobOffset = std::sin(m_bobTimer) * 7.5f;
    emit bobOffsetChanged();
    emit renderPositionChanged();
}

bool AccessKeyPickup::isPlayerInRange(const QVector3D &playerPos,
                                      bool playerAlive,
                                      float radius) const
{
    if (m_collected || !playerAlive) {
        return false;
    }

    const float dx = playerPos.x() - m_position.x();
    const float dz = playerPos.z() - m_position.z();
    const float effectiveRadius = std::max(radius, 75.0f);
    return (dx * dx + dz * dz) <= (effectiveRadius * effectiveRadius);
}

bool AccessKeyPickup::checkCollection(const QVector3D &playerPos,
                                      bool playerAlive,
                                      float radius)
{
    if (!isPlayerInRange(playerPos, playerAlive, radius)) {
        return false;
    }

    setCollected(true);
    emit collectedTriggered(m_keyIndex);
    return true;
}

void AccessKeyPickup::reset()
{
    setCollected(false);
    m_bobOffset = std::sin(m_bobTimer) * 7.5f;
    emit bobOffsetChanged();
    emit renderPositionChanged();
}

