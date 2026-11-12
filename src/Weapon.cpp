#include "Weapon.h"
#include <QDebug>
#include <QtMath>

Weapon::Weapon(const QString &name,
               int maxAmmo,
               int initialReserve,
               float fireCooldown,
               float reloadTime,
               QObject *parent)
    : QObject(parent)
    , m_name(name)
    , m_ammo(maxAmmo)
    , m_maxAmmo(maxAmmo)
    , m_reserveAmmo(initialReserve)
    , m_initialReserve(initialReserve)
    , m_fireCooldown(fireCooldown)
    , m_currentCooldown(0.0f)
    , m_reloadTime(reloadTime)
    , m_reloadTimer(0.0f)
    , m_isReloading(false)
{
    qDebug() << "[Weapon] Initialized:" << m_name << "Ammo:" << m_ammo << "/" << m_reserveAmmo;
}

int Weapon::ammo() const
{
    return m_ammo;
}

int Weapon::maxAmmo() const
{
    return m_maxAmmo;
}

void Weapon::setMaxAmmo(int maxAmmo)
{
    if (m_maxAmmo != maxAmmo && maxAmmo > 0) {
        m_maxAmmo = maxAmmo;
        if (m_ammo > m_maxAmmo) {
            m_ammo = m_maxAmmo;
            emit ammoChanged(m_ammo, m_reserveAmmo);
        }
        emit maxAmmoChanged(m_maxAmmo);
    }
}

void Weapon::setAmmo(int ammo)
{
    int clamped = qBound(0, ammo, m_maxAmmo);
    if (m_ammo != clamped) {
        m_ammo = clamped;
        emit ammoChanged(m_ammo, m_reserveAmmo);
    }
}

int Weapon::reserveAmmo() const
{
    return m_reserveAmmo;
}

bool Weapon::isReloading() const
{
    return m_isReloading;
}

bool Weapon::canFire() const
{
    return (!m_isReloading && m_currentCooldown <= 0.0f && m_ammo > 0);
}

float Weapon::cooldownProgress() const
{
    if (m_fireCooldown <= 0.0f) return 0.0f;
    return qBound(0.0f, m_currentCooldown / m_fireCooldown, 1.0f);
}

QString Weapon::weaponName() const
{
    return m_name;
}

bool Weapon::fire()
{
    if (!canFire()) {
        if (m_ammo == 0 && !m_isReloading) {
            emit outOfAmmo();
        }
        return false;
    }

    m_ammo--;
    m_currentCooldown = m_fireCooldown;

    qDebug() << "[Weapon]" << m_name << "fired! Remaining ammo:" << m_ammo;
    emit fired();
    emit ammoChanged(m_ammo, m_reserveAmmo);
    emit cooldownChanged();

    // Auto-reload if magazine emptied and reserve available
    if (m_ammo == 0 && m_reserveAmmo > 0) {
        reload();
    }

    return true;
}

void Weapon::reload()
{
    if (m_isReloading || m_ammo >= m_maxAmmo || m_reserveAmmo <= 0) {
        return;
    }

    m_isReloading = true;
    m_reloadTimer = m_reloadTime;
    qDebug() << "[Weapon]" << m_name << "reloading started (" << m_reloadTime << "s)...";
    emit reloadingChanged(m_isReloading);
}

void Weapon::update(float deltaTime)
{
    if (deltaTime <= 0.0f) return;

    // 1. Process fire cooldown
    if (m_currentCooldown > 0.0f) {
        m_currentCooldown -= deltaTime;
        if (m_currentCooldown < 0.0f) {
            m_currentCooldown = 0.0f;
        }
        emit cooldownChanged();
    }

    // 2. Process reload timer
    if (m_isReloading) {
        m_reloadTimer -= deltaTime;
        if (m_reloadTimer <= 0.0f) {
            m_reloadTimer = 0.0f;
            m_isReloading = false;

            int needed = m_maxAmmo - m_ammo;
            int toLoad = qMin(needed, m_reserveAmmo);
            m_ammo += toLoad;
            m_reserveAmmo -= toLoad;

            qDebug() << "[Weapon]" << m_name << "reloaded! New ammo:" << m_ammo << "/" << m_reserveAmmo;
            emit reloadingChanged(m_isReloading);
            emit reloaded();
            emit ammoChanged(m_ammo, m_reserveAmmo);
            emit cooldownChanged();
        }
    }
}

void Weapon::resetAmmo()
{
    m_ammo = m_maxAmmo;
    m_reserveAmmo = m_initialReserve;
    m_currentCooldown = 0.0f;
    m_isReloading = false;
    m_reloadTimer = 0.0f;

    emit ammoChanged(m_ammo, m_reserveAmmo);
    emit reloadingChanged(m_isReloading);
    emit cooldownChanged();
}

void Weapon::addReserveAmmo(int count)
{
    if (count > 0) {
        m_reserveAmmo += count;
        qDebug() << "[Weapon]" << m_name << "added" << count << "reserve rounds! Total reserve:" << m_reserveAmmo;
        emit ammoChanged(m_ammo, m_reserveAmmo);
    }
}

void Weapon::setReserveAmmo(int count)
{
    m_reserveAmmo = qMax(0, count);
    emit ammoChanged(m_ammo, m_reserveAmmo);
}
