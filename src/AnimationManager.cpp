#include "AnimationManager.h"
#include <cmath>
#include <algorithm>
#include <vector>
#include <QtMath>
#include <QRandomGenerator>

AnimationManager::AnimationManager(QObject *parent)
    : QObject(parent)
{
    m_tracers.resize(GameConfig::MAX_ACTIVE_TRACERS);
    m_sparks.resize(GameConfig::MAX_ACTIVE_SPARKS);
    m_debris.resize(GameConfig::MAX_ACTIVE_DEBRIS);
}

QVariantList AnimationManager::tracers() const
{
    return m_cachedTracers;
}

QVariantList AnimationManager::sparks() const
{
    return m_cachedSparks;
}

QVariantList AnimationManager::ventBursts() const
{
    return m_cachedDebris;
}

void AnimationManager::clearAll()
{
    for (auto &t : m_tracers) t.active = false;
    for (auto &s : m_sparks) s.active = false;
    for (auto &d : m_debris) d.active = false;
    m_damageFlash = 0.0f;
    m_healFlash = 0.0f;
    rebuildTracerList();
    rebuildSparkList();
    rebuildDebrisList();
    emit damageFlashChanged(m_damageFlash);
    emit healFlashChanged(m_healFlash);
}

void AnimationManager::triggerDamageFlash()
{
    if (!GameConfig::ENABLE_EFFECTS_DAMAGE_FLASH) return;
    m_damageFlash = 1.0f;
    emit damageFlashChanged(m_damageFlash);
}

void AnimationManager::triggerHealFlash()
{
    if (!GameConfig::ENABLE_EFFECTS_HEAL) return;
    m_healFlash = 1.0f;
    emit healFlashChanged(m_healFlash);
}

void AnimationManager::spawnTracer(const QVector3D &start, const QVector3D &end, int weaponType)
{
    if (!GameConfig::ENABLE_EFFECTS_TRACERS) return;

    for (auto &t : m_tracers) {
        if (!t.active) {
            t.start = start;
            t.end = end;
            t.progress = 0.0f;
            t.lifetime = 0.0f;
            t.maxLifetime = (weaponType == 1) ? 0.08f : 0.12f;
            if (weaponType == 1) {
                t.colorHex = QStringLiteral("#00e5ff"); // Cyan for Heavy Weapon
            } else if (weaponType == 2) {
                t.colorHex = QStringLiteral("#e74c3c"); // Red for Sentinel
            } else {
                t.colorHex = QStringLiteral("#f39c12"); // Orange for Sniper
            }
            t.active = true;
            break;
        }
    }
}

void AnimationManager::spawnSparks(const QVector3D &hitPos, const QVector3D &normal, int sparkType)
{
    if (!GameConfig::ENABLE_EFFECTS_HIT_SPARKS) return;

    int count = (sparkType == 1) ? 3 : 4; // Fast, lightweight, zero frame drops
    auto *rng = QRandomGenerator::global();

    for (int i = 0; i < count; ++i) {
        for (auto &s : m_sparks) {
            if (!s.active) {
                s.pos = hitPos + normal * 2.0f;
                float rx = (rng->generateDouble() * 2.0f - 1.0f) * 120.0f;
                float ry = 80.0f + rng->generateDouble() * 140.0f;
                float rz = (rng->generateDouble() * 2.0f - 1.0f) * 120.0f;
                s.vel = normal * 100.0f + QVector3D(rx, ry, rz);
                s.lifetime = 0.0f;
                s.maxLifetime = 0.25f + rng->generateDouble() * 0.20f;
                s.size = 3.0f + rng->generateDouble() * 2.0f;
                if (sparkType == 1) {
                    s.colorHex = QStringLiteral("#e74c3c"); // Red flesh/circuit sparks
                } else if (sparkType == 2) {
                    s.colorHex = QStringLiteral("#00e5ff"); // Cyan coolant sparks
                } else {
                    s.colorHex = QStringLiteral("#f1c40f"); // Yellow-gold wall spark
                }
                s.active = true;
                break;
            }
        }
    }
}

void AnimationManager::spawnVentBurst(const QVector3D &ventPos)
{
    if (!GameConfig::ENABLE_EFFECTS_VENT_BURST) return;

    auto *rng = QRandomGenerator::global();
    int count = 16;

    for (int i = 0; i < count; ++i) {
        for (auto &d : m_debris) {
            if (!d.active) {
                d.pos = ventPos + QVector3D(
                    (rng->generateDouble() * 2.0f - 1.0f) * 20.0f,
                    20.0f + rng->generateDouble() * 60.0f,
                    (rng->generateDouble() * 2.0f - 1.0f) * 20.0f
                );
                float angle = rng->generateDouble() * 2.0f * 3.14159f;
                float speed = 150.0f + rng->generateDouble() * 200.0f;
                d.vel = QVector3D(
                    std::cos(angle) * speed,
                    120.0f + rng->generateDouble() * 180.0f,
                    std::sin(angle) * speed
                );
                d.lifetime = 0.0f;
                d.maxLifetime = 0.5f + rng->generateDouble() * 0.35f;
                d.size = 6.0f + rng->generateDouble() * 4.0f;
                d.colorHex = (i % 2 == 0) ? QStringLiteral("#00e5ff") : QStringLiteral("#34495e");
                d.active = true;
                break;
            }
        }
    }
}

void AnimationManager::update(float dt)
{
    m_animTime += dt;

    // 1. Update tracers
    bool tracersModified = false;
    for (auto &t : m_tracers) {
        if (t.active) {
            t.lifetime += dt;
            if (t.lifetime >= t.maxLifetime) {
                t.active = false;
            }
            tracersModified = true;
        }
    }
    if (tracersModified) {
        rebuildTracerList();
    }

    // 2. Update hit sparks
    bool sparksModified = false;
    for (auto &s : m_sparks) {
        if (s.active) {
            s.lifetime += dt;
            if (s.lifetime >= s.maxLifetime) {
                s.active = false;
            } else {
                s.pos += s.vel * dt;
                s.vel.setY(s.vel.y() - 600.0f * dt); // Gravity
                if (s.pos.y() < 5.0f) {
                    s.pos.setY(5.0f);
                    s.vel.setY(-s.vel.y() * 0.3f);
                }
            }
            sparksModified = true;
        }
    }
    if (sparksModified) {
        rebuildSparkList();
    }

    // 3. Update vent explosion debris
    bool debrisModified = false;
    for (auto &d : m_debris) {
        if (d.active) {
            d.lifetime += dt;
            if (d.lifetime >= d.maxLifetime) {
                d.active = false;
            } else {
                d.pos += d.vel * dt;
                d.vel.setY(d.vel.y() - 750.0f * dt); // Gravity
                if (d.pos.y() < 5.0f) {
                    d.pos.setY(5.0f);
                    d.vel.setY(-d.vel.y() * 0.25f);
                }
            }
            debrisModified = true;
        }
    }
    if (debrisModified) {
        rebuildDebrisList();
    }

    // 4. Update screen damage flash
    if (m_damageFlash > 0.0f) {
        m_damageFlash = std::max(0.0f, m_damageFlash - dt * 4.0f);
        emit damageFlashChanged(m_damageFlash);
    }

    // 5. Update screen heal flash
    if (m_healFlash > 0.0f) {
        m_healFlash = std::max(0.0f, m_healFlash - dt * 3.0f);
        emit healFlashChanged(m_healFlash);
    }

    // 6. Update elevator glow pulse
    float newGlow = 0.5f + 0.5f * std::sin(m_animTime * 3.5f);
    if (std::abs(newGlow - m_elevatorGlow) > 0.01f) {
        m_elevatorGlow = newGlow;
        emit elevatorGlowChanged(m_elevatorGlow);
    }
}

void AnimationManager::rebuildTracerList()
{
    m_cachedTracers.clear();
    for (const auto &t : m_tracers) {
        if (t.active) {
            QVariantMap item;
            item[QStringLiteral("startX")] = t.start.x();
            item[QStringLiteral("startY")] = t.start.y();
            item[QStringLiteral("startZ")] = t.start.z();
            item[QStringLiteral("endX")] = t.end.x();
            item[QStringLiteral("endY")] = t.end.y();
            item[QStringLiteral("endZ")] = t.end.z();
            item[QStringLiteral("midX")] = (t.start.x() + t.end.x()) * 0.5f;
            item[QStringLiteral("midY")] = (t.start.y() + t.end.y()) * 0.5f;
            item[QStringLiteral("midZ")] = (t.start.z() + t.end.z()) * 0.5f;
            float len = t.start.distanceToPoint(t.end);
            item[QStringLiteral("length")] = len;
            item[QStringLiteral("alpha")] = 1.0f - (t.lifetime / t.maxLifetime);
            item[QStringLiteral("color")] = t.colorHex;

            float pitch = 0.0f;
            float yaw = 0.0f;
            if (len > 1e-3f) {
                QVector3D dir = (t.end - t.start) / len;
                pitch = -qRadiansToDegrees(std::asin(std::clamp(dir.y(), -1.0f, 1.0f)));
                yaw = qRadiansToDegrees(std::atan2(dir.x(), -dir.z()));
            }
            item[QStringLiteral("pitch")] = pitch;
            item[QStringLiteral("yaw")] = yaw;

            m_cachedTracers.append(item);
        }
    }
    emit tracersChanged();
}

void AnimationManager::rebuildSparkList()
{
    m_cachedSparks.clear();
    for (const auto &s : m_sparks) {
        if (s.active) {
            QVariantMap item;
            item[QStringLiteral("x")] = s.pos.x();
            item[QStringLiteral("y")] = s.pos.y();
            item[QStringLiteral("z")] = s.pos.z();
            item[QStringLiteral("size")] = s.size;
            item[QStringLiteral("alpha")] = 1.0f - (s.lifetime / s.maxLifetime);
            item[QStringLiteral("color")] = s.colorHex;
            m_cachedSparks.append(item);
        }
    }
    emit sparksChanged();
}

void AnimationManager::rebuildDebrisList()
{
    m_cachedDebris.clear();
    for (const auto &d : m_debris) {
        if (d.active) {
            QVariantMap item;
            item[QStringLiteral("x")] = d.pos.x();
            item[QStringLiteral("y")] = d.pos.y();
            item[QStringLiteral("z")] = d.pos.z();
            item[QStringLiteral("size")] = d.size;
            item[QStringLiteral("alpha")] = 1.0f - (d.lifetime / d.maxLifetime);
            item[QStringLiteral("color")] = d.colorHex;
            m_cachedDebris.append(item);
        }
    }
    emit ventBurstsChanged();
}
