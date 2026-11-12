#ifndef ANIMATIONMANAGER_H
#define ANIMATIONMANAGER_H

#include <QObject>
#include <QString>
#include <QVector3D>
#include <QtGui/QVector3D>
#include <QVariantList>
#include <QVariantMap>
#include <QColor>
#include <QtGui/QColor>
#include <QtGlobal>
#include <QtQml/qqmlregistration.h>
#include <vector>
#include "GameConfig.h"

/**
 * @brief The AnimationManager class manages pooled 3D and 2D visual effects.
 * 
 * Handles bullet tracers, hit sparks/block debris, vent destruction bursts,
 * screen damage flash, healing glow, and elevator glow pulses with fixed-size
 * preallocated pools to guarantee 60+ FPS stability with zero garbage collection overhead.
 */
class AnimationManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList tracers READ tracers NOTIFY tracersChanged)
    Q_PROPERTY(QVariantList sparks READ sparks NOTIFY sparksChanged)
    Q_PROPERTY(QVariantList ventBursts READ ventBursts NOTIFY ventBurstsChanged)
    Q_PROPERTY(float damageFlash READ damageFlash NOTIFY damageFlashChanged)
    Q_PROPERTY(float healFlash READ healFlash NOTIFY healFlashChanged)
    Q_PROPERTY(float elevatorGlow READ elevatorGlow NOTIFY elevatorGlowChanged)

public:
    explicit AnimationManager(QObject *parent = nullptr);
    ~AnimationManager() override = default;

    QVariantList tracers() const;
    QVariantList sparks() const;
    QVariantList ventBursts() const;
    float damageFlash() const { return m_damageFlash; }
    float healFlash() const { return m_healFlash; }
    float elevatorGlow() const { return m_elevatorGlow; }

    // Frame update loop
    Q_INVOKABLE void update(float dt);

    // Effect triggers
    Q_INVOKABLE void spawnTracer(const QVector3D &start, const QVector3D &end, int weaponType);
    Q_INVOKABLE void spawnSparks(const QVector3D &hitPos, const QVector3D &normal, int sparkType = 0);
    Q_INVOKABLE void spawnVentBurst(const QVector3D &ventPos);
    Q_INVOKABLE void triggerDamageFlash();
    Q_INVOKABLE void triggerHealFlash();
    Q_INVOKABLE void clearAll();

signals:
    void tracersChanged();
    void sparksChanged();
    void ventBurstsChanged();
    void damageFlashChanged(float intensity);
    void healFlashChanged(float intensity);
    void elevatorGlowChanged(float glow);

private:
    struct TracerData {
        QVector3D start;
        QVector3D end;
        float progress = 0.0f;
        float lifetime = 0.0f;
        float maxLifetime = 0.12f;
        QString colorHex = QStringLiteral("#f39c12");
        bool active = false;
    };

    struct SparkData {
        QVector3D pos;
        QVector3D vel;
        float lifetime = 0.0f;
        float maxLifetime = 0.4f;
        float size = 4.0f;
        QString colorHex = QStringLiteral("#ffcc00");
        bool active = false;
    };

    struct DebrisData {
        QVector3D pos;
        QVector3D vel;
        float lifetime = 0.0f;
        float maxLifetime = 0.8f;
        float size = 8.0f;
        QString colorHex = QStringLiteral("#00e5ff");
        bool active = false;
    };

    std::vector<TracerData> m_tracers;
    std::vector<SparkData> m_sparks;
    std::vector<DebrisData> m_debris;

    float m_damageFlash = 0.0f;
    float m_healFlash = 0.0f;
    float m_elevatorGlow = 0.5f;
    float m_animTime = 0.0f;

    void rebuildTracerList();
    void rebuildSparkList();
    void rebuildDebrisList();

    QVariantList m_cachedTracers;
    QVariantList m_cachedSparks;
    QVariantList m_cachedDebris;
};

#endif // ANIMATIONMANAGER_H
