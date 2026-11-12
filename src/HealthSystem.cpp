#include "HealthSystem.h"
#include <algorithm>

HealthSystem::HealthSystem(int maxHealth, QObject *parent)
    : QObject(parent)
    , m_health(maxHealth)
    , m_maxHealth(maxHealth)
{
}

int HealthSystem::health() const
{
    return m_health;
}

int HealthSystem::maxHealth() const
{
    return m_maxHealth;
}

bool HealthSystem::isDead() const
{
    return m_health <= 0;
}

float HealthSystem::healthPercentage() const
{
    if (m_maxHealth <= 0) return 0.0f;
    return static_cast<float>(m_health) / static_cast<float>(m_maxHealth);
}

void HealthSystem::setHealth(int value)
{
    int clamped = std::clamp(value, 0, m_maxHealth);
    if (m_health != clamped) {
        m_health = clamped;
        emit healthChanged(m_health);
        if (m_health == 0) {
            emit died();
        }
    }
}

void HealthSystem::setMaxHealth(int value)
{
    if (value > 0 && m_maxHealth != value) {
        m_maxHealth = value;
        emit maxHealthChanged(m_maxHealth);
        if (m_health > m_maxHealth) {
            setHealth(m_maxHealth);
        }
    }
}

void HealthSystem::takeDamage(int amount)
{
    if (amount <= 0 || isDead()) return;

    m_health = std::max(0, m_health - amount);
    emit damageTaken(amount);
    emit healthChanged(m_health);

    if (m_health == 0) {
        emit died();
    }
}

void HealthSystem::heal(int amount)
{
    if (amount <= 0 || isDead() || m_health >= m_maxHealth) return;

    int oldHealth = m_health;
    m_health = std::min(m_maxHealth, m_health + amount);
    int actualHealed = m_health - oldHealth;

    if (actualHealed > 0) {
        emit healed(actualHealed);
        emit healthChanged(m_health);
    }
}

void HealthSystem::reset()
{
    m_health = m_maxHealth;
    emit healthChanged(m_health);
}
