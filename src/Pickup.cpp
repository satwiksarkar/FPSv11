#include "Pickup.h"
#include <cmath>

Pickup::Pickup(QObject *parent)
    : QObject(parent)
    , m_position(0.0f, 30.0f, 0.0f)
    , m_type(Inventory::ItemType::FoodPack)
    , m_isCollected(false)
    , m_rotationY(0.0f)
    , m_bobTimer(0.0f)
    , m_bobOffset(0.0f)
{
}

Pickup::Pickup(const QVector3D &position, Inventory::ItemType type, QObject *parent)
    : QObject(parent)
    , m_position(position)
    , m_type(type)
    , m_isCollected(false)
    , m_rotationY(0.0f)
    , m_bobTimer(0.0f)
    , m_bobOffset(0.0f)
{
}

QVector3D Pickup::position() const
{
    return m_position;
}

void Pickup::setPosition(const QVector3D &pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
        emit renderPositionChanged();
    }
}

QVector3D Pickup::renderPosition() const
{
    return QVector3D(m_position.x(), m_position.y() + m_bobOffset, m_position.z());
}

Inventory::ItemType Pickup::itemType() const
{
    return m_type;
}

void Pickup::setItemType(Inventory::ItemType type)
{
    if (m_type != type) {
        m_type = type;
        emit itemTypeChanged();
    }
}

QString Pickup::typeString() const
{
    return Inventory::itemTypeName(m_type);
}

int Pickup::healAmount() const
{
    return Inventory::itemHealAmount(m_type);
}

bool Pickup::isCollected() const
{
    return m_isCollected;
}

void Pickup::setCollected(bool collected)
{
    if (m_isCollected != collected) {
        m_isCollected = collected;
        emit collectedChanged(m_isCollected);
    }
}

float Pickup::rotationY() const
{
    return m_rotationY;
}

float Pickup::bobOffset() const
{
    return m_bobOffset;
}

void Pickup::update(float deltaTime)
{
    if (m_isCollected) return;

    // Smooth spinning at 80 degrees per second
    m_rotationY += 80.0f * deltaTime;
    if (m_rotationY >= 360.0f) {
        m_rotationY -= 360.0f;
    }
    emit rotationChanged();

    // Gentle vertical bobbing (+-8 units)
    m_bobTimer += deltaTime * 2.5f;
    m_bobOffset = std::sin(m_bobTimer) * 8.0f;
    emit bobOffsetChanged();
    emit renderPositionChanged();
}

bool Pickup::checkCollection(const QVector3D &playerPos, float radius)
{
    if (m_isCollected) return false;

    // Horizontal 2D distance check on XZ floor plane (ignores Y height difference)
    float dx = playerPos.x() - m_position.x();
    float dz = playerPos.z() - m_position.z();
    float distSq = dx * dx + dz * dz;
    float effectiveRadius = std::max(radius, 90.0f);
    if (distSq <= (effectiveRadius * effectiveRadius)) {
        setCollected(true);
        emit collected(m_type, healAmount());
        return true;
    }

    return false;
}

void Pickup::reset()
{
    m_isCollected = false;
    m_rotationY = 0.0f;
    m_bobTimer = 0.0f;
    m_bobOffset = 0.0f;
    emit collectedChanged(m_isCollected);
    emit rotationChanged();
    emit bobOffsetChanged();
    emit renderPositionChanged();
}

void Pickup::respawn(const QVector3D &pos, Inventory::ItemType type)
{
    m_position = pos;
    m_type = type;
    m_isCollected = false;
    m_rotationY = 0.0f;
    m_bobTimer = 0.0f;
    m_bobOffset = 0.0f;
    emit positionChanged();
    emit itemTypeChanged();
    emit collectedChanged(m_isCollected);
    emit rotationChanged();
    emit bobOffsetChanged();
    emit renderPositionChanged();
}
