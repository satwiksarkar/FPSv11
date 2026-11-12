#ifndef HEALTHSYSTEM_H
#define HEALTHSYSTEM_H

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include "GameConfig.h"

/**
 * @brief The HealthSystem class encapsulates entity vitality, damage, healing, and death.
 * 
 * Shared between Player and Enemy via composition (OOP principle).
 * Ensures health values remain clamped within [0, maxHealth] and emits reactive signals.
 */
class HealthSystem : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int health READ health WRITE setHealth NOTIFY healthChanged)
    Q_PROPERTY(int maxHealth READ maxHealth WRITE setMaxHealth NOTIFY maxHealthChanged)
    Q_PROPERTY(bool isDead READ isDead NOTIFY healthChanged)
    Q_PROPERTY(float healthPercentage READ healthPercentage NOTIFY healthChanged)

public:
    explicit HealthSystem(int maxHealth = GameConfig::MAX_PLAYER_HEALTH, QObject *parent = nullptr);

    int health() const;
    int maxHealth() const;
    bool isDead() const;
    float healthPercentage() const;

    void setHealth(int value);
    void setMaxHealth(int value);

    Q_INVOKABLE void takeDamage(int amount);
    Q_INVOKABLE void heal(int amount);
    Q_INVOKABLE void reset();

signals:
    void healthChanged(int currentHealth);
    void maxHealthChanged(int maxHealth);
    void damageTaken(int amount);
    void healed(int amount);
    void died();

private:
    int m_health;
    int m_maxHealth;
};

#endif // HEALTHSYSTEM_H
