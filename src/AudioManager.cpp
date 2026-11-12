#include "AudioManager.h"
#include <utility>
#include <algorithm>
#include <memory>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QStandardPaths>
#include <QDebug>

AudioManager::AudioManager(QObject *parent)
    : QObject(parent)
    , m_masterVolume(1.0f)
    , m_soundEnabled(true)
    , m_currentAmbientLevel(0)
    , m_currentAmbient(nullptr)
{
    qDebug() << "[AudioManager] Initializing audio subsystem with preloaded voice pools...";
    preloadAllSounds();
    qDebug() << "[AudioManager] Initialized successfully. Sound enabled:" << m_soundEnabled
             << "Master volume:" << m_masterVolume;
}

AudioManager::~AudioManager()
{
    stopAmbient();
    for (auto &pool : m_soundPools) {
        qDeleteAll(pool);
        pool.clear();
    }
    m_soundPools.clear();
    qDeleteAll(m_ambientTracks);
    m_ambientTracks.clear();
}

float AudioManager::masterVolume() const
{
    return m_masterVolume;
}

void AudioManager::setMasterVolume(float volume)
{
    float clamped = std::clamp(volume, 0.0f, 1.0f);
    if (!qFuzzyCompare(m_masterVolume, clamped)) {
        m_masterVolume = clamped;
        for (const auto &pool : std::as_const(m_soundPools)) {
            for (auto *effect : pool) {
                if (effect) {
                    effect->setVolume(m_masterVolume * 0.85f);
                }
            }
        }
        if (m_currentAmbient) {
            m_currentAmbient->setVolume(m_masterVolume * 0.45f);
        }
        emit masterVolumeChanged(m_masterVolume);
    }
}

bool AudioManager::soundEnabled() const
{
    return m_soundEnabled;
}

void AudioManager::setSoundEnabled(bool enabled)
{
    if (m_soundEnabled != enabled) {
        m_soundEnabled = enabled;
        if (!m_soundEnabled) {
            stopAmbient();
            for (const auto &pool : std::as_const(m_soundPools)) {
                for (auto *effect : pool) {
                    if (effect && effect->isPlaying()) {
                        effect->stop();
                    }
                }
            }
        } else {
            if (m_currentAmbientLevel > 0) {
                playAmbient(m_currentAmbientLevel);
            }
        }
        emit soundEnabledChanged(m_soundEnabled);
    }
}

QString AudioManager::findSoundFile(const QString &fileName)
{
    // Search candidate directories on local disk
    const QStringList searchDirs = {
        QCoreApplication::applicationDirPath() + QStringLiteral("/assets/sounds/"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../assets/sounds/"),
        QDir::currentPath() + QStringLiteral("/assets/sounds/"),
        QStringLiteral("C:/Users/JOYDEEP/Desktop/qt project/assets/sounds/")
    };

    for (const QString &dir : searchDirs) {
        QString candidate = QDir::cleanPath(dir + fileName);
        if (QFileInfo::exists(candidate)) {
            return candidate;
        }
    }

    // Fallback: If not found on disk, extract from compiled Qt resources to temporary cache folder
    QString qrcPath = QStringLiteral(":/qt/qml/FPSLabGame/assets/sounds/") + fileName;
    if (QFile::exists(qrcPath)) {
        QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + QStringLiteral("/FPSLabGame/sounds");
        QDir().mkpath(tempDir);
        QString tempFile = tempDir + QStringLiteral("/") + fileName;
        if (!QFileInfo::exists(tempFile)) {
            QFile::copy(qrcPath, tempFile);
        }
        if (QFileInfo::exists(tempFile)) {
            return tempFile;
        }
    }

    qWarning() << "[AudioManager] Could not locate sound file on disk or resources:" << fileName;
    return QString();
}

QUrl AudioManager::resolveAudioSource(const QString &fileName)
{
    QString localFile = findSoundFile(fileName);
    if (!localFile.isEmpty()) {
        return QUrl::fromLocalFile(localFile);
    }
    return QUrl::fromLocalFile(QCoreApplication::applicationDirPath() + QStringLiteral("/assets/sounds/") + fileName);
}

QSoundEffect* AudioManager::createEffect(const QString &fileName, bool loop, float volume)
{
    auto *effect = new QSoundEffect(this);
    QUrl url = resolveAudioSource(fileName);
    effect->setSource(url);
    effect->setVolume(m_masterVolume * volume);
    effect->setLoopCount(loop ? QSoundEffect::Infinite : 1);

    connect(effect, &QSoundEffect::statusChanged, this, [effect, fileName]() {
        if (effect->status() == QSoundEffect::Error) {
            qWarning() << "[AudioManager] Error loading sound:" << fileName << "from" << effect->source();
        } else if (effect->status() == QSoundEffect::Ready) {
            qDebug() << "[AudioManager] Sound ready:" << fileName;
        }
    });

    return effect;
}

void AudioManager::preloadAllSounds()
{
    struct SoundDef {
        QString name;
        int poolSize;
        float defaultVolume;
    };

    // Preload sound effects with dedicated voice pools
    const QList<SoundDef> effectDefs = {
        { QStringLiteral("gunshot.wav"),      4, 0.90f },
        { QStringLiteral("plasma_shot.wav"),  4, 0.85f },
        { QStringLiteral("enemy_hit.wav"),    4, 0.90f },
        { QStringLiteral("pickup.wav"),       3, 0.80f },
        { QStringLiteral("reload.wav"),       2, 0.75f },
        { QStringLiteral("door.wav"),         2, 0.85f },
        { QStringLiteral("death.wav"),        1, 0.95f },
        { QStringLiteral("vent_explode.wav"), 2, 1.00f },
        { QStringLiteral("level_clear.wav"),  1, 0.95f }
    };

    for (const auto &def : effectDefs) {
        QVector<QSoundEffect*> pool;
        pool.reserve(def.poolSize);
        for (int i = 0; i < def.poolSize; ++i) {
            pool.append(createEffect(def.name, false, def.defaultVolume));
        }
        m_soundPools.insert(def.name, pool);
        m_poolIndices.insert(def.name, 0);
    }

    // Preload ambient background loops for Level 1, 2, and 3
    m_ambientTracks.insert(1, createEffect(QStringLiteral("factory_hum.wav"), true, 0.40f));
    m_ambientTracks.insert(2, createEffect(QStringLiteral("armory_hum.wav"),  true, 0.40f));
    m_ambientTracks.insert(3, createEffect(QStringLiteral("core_hum.wav"),    true, 0.40f));

    qDebug() << "[AudioManager] Preloaded all sound effect pools and 3 ambient loops.";
}

void AudioManager::playEffectSafe(QSoundEffect *effect, float volumeMultiplier)
{
    if (!effect || !m_soundEnabled) return;

    float vol = std::clamp(m_masterVolume * volumeMultiplier, 0.0f, 1.0f);
    effect->setVolume(vol);

    if (effect->status() == QSoundEffect::Ready) {
        if (effect->isPlaying()) {
            effect->stop();
        }
        effect->play();
    } else if (effect->status() == QSoundEffect::Loading) {
        // Deferred playback: plays as soon as status transitions to Ready
        auto conn = std::make_shared<QMetaObject::Connection>();
        *conn = connect(effect, &QSoundEffect::statusChanged, this, [this, effect, vol, conn]() {
            if (effect->status() == QSoundEffect::Ready) {
                disconnect(*conn);
                if (m_soundEnabled) {
                    effect->setVolume(vol);
                    effect->play();
                }
            } else if (effect->status() == QSoundEffect::Error) {
                disconnect(*conn);
                qWarning() << "[AudioManager] Deferred playback failed, status Error on:" << effect->source();
            }
        });
    } else {
        qWarning() << "[AudioManager] Cannot play effect, status:" << effect->status() << "source:" << effect->source();
    }
}

void AudioManager::playPooledEffect(const QString &soundName, float volumeMultiplier)
{
    if (!m_soundEnabled) return;

    if (!m_soundPools.contains(soundName)) {
        qWarning() << "[AudioManager] Sound not found in pool:" << soundName;
        return;
    }

    const auto &pool = m_soundPools[soundName];
    if (pool.isEmpty()) return;

    int idx = m_poolIndices.value(soundName, 0);
    m_poolIndices[soundName] = (idx + 1) % pool.size();

    QSoundEffect *effect = pool[idx];
    playEffectSafe(effect, volumeMultiplier);
}

void AudioManager::playSound(const QString &soundName)
{
    QString name = soundName;
    if (!name.endsWith(QStringLiteral(".wav"))) {
        name += QStringLiteral(".wav");
    }
    playPooledEffect(name, 0.85f);
}

void AudioManager::playGunshot()
{
    playPooledEffect(QStringLiteral("gunshot.wav"), 0.90f);
}

void AudioManager::playHeavyGunshot()
{
    playPooledEffect(QStringLiteral("plasma_shot.wav"), 0.85f);
}

void AudioManager::playReload()
{
    playPooledEffect(QStringLiteral("reload.wav"), 0.75f);
}

void AudioManager::playDoor()
{
    playPooledEffect(QStringLiteral("door.wav"), 0.85f);
}

void AudioManager::playEnemyHit()
{
    playPooledEffect(QStringLiteral("enemy_hit.wav"), 0.90f);
}

void AudioManager::playDeath()
{
    playPooledEffect(QStringLiteral("death.wav"), 0.95f);
}

void AudioManager::playEnemyGunshot()
{
    playPooledEffect(QStringLiteral("gunshot.wav"), 0.70f);
}

void AudioManager::playPickup()
{
    playPooledEffect(QStringLiteral("pickup.wav"), 0.80f);
}

void AudioManager::playVentExplosion()
{
    playPooledEffect(QStringLiteral("vent_explode.wav"), 1.0f);
}

void AudioManager::playLevelComplete()
{
    playPooledEffect(QStringLiteral("level_clear.wav"), 0.95f);
}

void AudioManager::playAmbient(int level)
{
    if (!m_soundEnabled) return;

    if (level < 1 || level > 3) {
        level = 1;
    }

    if (m_currentAmbientLevel == level && m_currentAmbient && m_currentAmbient->isPlaying()) {
        return; // Already playing the requested ambient loop
    }

    stopAmbient();

    m_currentAmbientLevel = level;
    QSoundEffect *track = m_ambientTracks.value(level, nullptr);
    if (!track) {
        qWarning() << "[AudioManager] Ambient track not found for Level:" << level;
        return;
    }

    m_currentAmbient = track;
    track->setLoopCount(QSoundEffect::Infinite);
    track->setVolume(m_masterVolume * 0.40f);

    qDebug() << "[AudioManager] Starting ambient loop for Level" << level << "Status:" << track->status();

    if (track->status() == QSoundEffect::Ready) {
        track->play();
    } else {
        auto conn = std::make_shared<QMetaObject::Connection>();
        *conn = connect(track, &QSoundEffect::statusChanged, this, [this, track, level, conn]() {
            if (track->status() == QSoundEffect::Ready) {
                disconnect(*conn);
                if (m_soundEnabled && m_currentAmbientLevel == level) {
                    track->setVolume(m_masterVolume * 0.40f);
                    track->play();
                    qDebug() << "[AudioManager] Deferred ambient loop started for Level" << level;
                }
            } else if (track->status() == QSoundEffect::Error) {
                disconnect(*conn);
                qWarning() << "[AudioManager] Failed to load ambient loop for Level" << level;
            }
        });
    }
}

void AudioManager::stopAmbient()
{
    if (m_currentAmbient) {
        m_currentAmbient->stop();
        m_currentAmbient = nullptr;
    }
    m_currentAmbientLevel = 0;
}

QUrl AudioManager::soundUrl(const QString &fileName)
{
    return resolveAudioSource(fileName);
}
