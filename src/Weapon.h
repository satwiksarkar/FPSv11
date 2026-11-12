#ifndef WEAPON_H
#define WEAPON_H

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

/**
 * @brief The Weapon class is the base class for all weapons in the game.
 * 
 * Manages ammunition (magazine and reserve), fire cooldown, reload timers,
 * delta-time updates, and Qt signals for firing and reloading.
 */
class Weapon : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int ammo READ ammo NOTIFY ammoChanged)
    Q_PROPERTY(int maxAmmo READ maxAmmo WRITE setMaxAmmo NOTIFY maxAmmoChanged)
    Q_PROPERTY(int reserveAmmo READ reserveAmmo NOTIFY ammoChanged)
    Q_PROPERTY(bool isReloading READ isReloading NOTIFY reloadingChanged)
    Q_PROPERTY(bool canFire READ canFire NOTIFY cooldownChanged)
    Q_PROPERTY(float cooldownProgress READ cooldownProgress NOTIFY cooldownChanged)
    Q_PROPERTY(QString weaponName READ weaponName CONSTANT)

public:
    explicit Weapon(const QString &name = QStringLiteral("Weapon"),
                    int maxAmmo = 5,
                    int initialReserve = 20,
                    float fireCooldown = 1.0f,
                    float reloadTime = 2.0f,
                    QObject *parent = nullptr);

    // Getters
    int ammo() const;
    int maxAmmo() const;
    int reserveAmmo() const;
    bool isReloading() const;
    bool canFire() const;
    float cooldownProgress() const;
    QString weaponName() const;

    // Actions
    Q_INVOKABLE virtual bool fire();
    Q_INVOKABLE virtual void reload();
    Q_INVOKABLE virtual void update(float deltaTime);
    Q_INVOKABLE virtual void resetAmmo();
    Q_INVOKABLE void addReserveAmmo(int count);
    Q_INVOKABLE void setMaxAmmo(int maxAmmo);
    Q_INVOKABLE void setAmmo(int ammo);
    Q_INVOKABLE void setReserveAmmo(int count);

signals:
    void fired();
    void reloaded();
    void ammoChanged(int currentAmmo, int reserve);
    void maxAmmoChanged(int newMaxAmmo);
    void reloadingChanged(bool isReloading);
    void cooldownChanged();
    void outOfAmmo();

protected:
    QString m_name;
    int m_ammo;
    int m_maxAmmo;
    int m_reserveAmmo;
    int m_initialReserve;

    float m_fireCooldown;
    float m_currentCooldown;

    float m_reloadTime;
    float m_reloadTimer;
    bool m_isReloading;
};

#endif // WEAPON_H
