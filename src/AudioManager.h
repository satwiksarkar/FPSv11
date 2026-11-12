#ifndef AUDIOMANAGER_H
#define AUDIOMANAGER_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QSoundEffect>
#include <QMap>
#include <QVector>
#include <QtQml/qqmlregistration.h>

/**
 * @brief The AudioManager class handles sound effect playback, voice pooling,
 * and ambient background audio loops for Project VANGUARD.
 * 
 * Provides preloaded audio voices and asynchronous state tracking to ensure
 * 100% reliable sound across all game levels and difficulty settings.
 */
class AudioManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(float masterVolume READ masterVolume WRITE setMasterVolume NOTIFY masterVolumeChanged)
    Q_PROPERTY(bool soundEnabled READ soundEnabled WRITE setSoundEnabled NOTIFY soundEnabledChanged)

public:
    explicit AudioManager(QObject *parent = nullptr);
    ~AudioManager() override;

    float masterVolume() const;
    void setMasterVolume(float volume);

    bool soundEnabled() const;
    void setSoundEnabled(bool enabled);

    // Named sound effect triggers
    Q_INVOKABLE void playGunshot();
    Q_INVOKABLE void playHeavyGunshot();
    Q_INVOKABLE void playReload();
    Q_INVOKABLE void playDoor();
    Q_INVOKABLE void playEnemyHit();
    Q_INVOKABLE void playDeath();
    Q_INVOKABLE void playEnemyGunshot();
    Q_INVOKABLE void playPickup();
    Q_INVOKABLE void playVentExplosion();
    Q_INVOKABLE void playLevelComplete();

    // Ambient loop playback per level (1 = factory, 2 = armory, 3 = core)
    Q_INVOKABLE void playAmbient(int level);
    Q_INVOKABLE void stopAmbient();

    // Generic player and URL resolver
    Q_INVOKABLE void playSound(const QString &soundName);
    Q_INVOKABLE QUrl soundUrl(const QString &fileName);

signals:
    void masterVolumeChanged(float newVolume);
    void soundEnabledChanged(bool enabled);

private:
    void preloadAllSounds();
    void playEffectSafe(QSoundEffect *effect, float volumeMultiplier = 1.0f);
    void playPooledEffect(const QString &soundName, float volumeMultiplier = 1.0f);
    QString findSoundFile(const QString &fileName);
    QUrl resolveAudioSource(const QString &fileName);
    QSoundEffect* createEffect(const QString &fileName, bool loop = false, float volume = 0.85f);

    float m_masterVolume;
    bool m_soundEnabled;
    int m_currentAmbientLevel;

    QMap<QString, QVector<QSoundEffect*>> m_soundPools;
    QMap<QString, int> m_poolIndices;
    QMap<int, QSoundEffect*> m_ambientTracks;
    QSoundEffect *m_currentAmbient;
};

#endif // AUDIOMANAGER_H
