#ifndef ACCESSKEYPICKUP_H
#define ACCESSKEYPICKUP_H

#include <QObject>
#include <QString>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>

/**
 * @brief AccessKeyPickup represents one of four collectible mission access keys
 * on a campaign level. Visual/pickup state mirrors LevelManager's authoritative
 * four-bit key mask rather than owning independent progression truth.
 */
class AccessKeyPickup : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int keyIndex READ keyIndex NOTIFY configChanged)
    Q_PROPERTY(int levelIndex READ levelIndex NOTIFY configChanged)
    Q_PROPERTY(QString keyName READ keyName NOTIFY configChanged)
    Q_PROPERTY(QVector3D position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(QVector3D renderPosition READ renderPosition NOTIFY renderPositionChanged)
    Q_PROPERTY(bool collected READ isCollected WRITE setCollected NOTIFY collectedChanged)
    Q_PROPERTY(float rotationY READ rotationY NOTIFY rotationChanged)
    Q_PROPERTY(float bobOffset READ bobOffset NOTIFY bobOffsetChanged)

public:
    explicit AccessKeyPickup(QObject *parent = nullptr);

    void configure(int levelIndex,
                   int keyIndex,
                   const QVector3D &position,
                   const QString &keyName = QString());

    int keyIndex() const;
    int levelIndex() const;
    QString keyName() const;

    QVector3D position() const;
    void setPosition(const QVector3D &pos);
    QVector3D renderPosition() const;

    bool isCollected() const;
    void setCollected(bool collected);

    float rotationY() const;
    float bobOffset() const;

    Q_INVOKABLE void update(float deltaTime);
    Q_INVOKABLE bool isPlayerInRange(const QVector3D &playerPos,
                                       bool playerAlive = true,
                                       float radius = 75.0f) const;
    Q_INVOKABLE bool checkCollection(const QVector3D &playerPos,
                                       bool playerAlive = true,
                                       float radius = 75.0f);
    Q_INVOKABLE void reset();

signals:
    void configChanged();
    void positionChanged();
    void renderPositionChanged();
    void collectedChanged(bool collected);
    void rotationChanged();
    void bobOffsetChanged();
    void collectedTriggered(int keyIndex);

private:
    int m_levelIndex;
    int m_keyIndex;
    QString m_keyName;
    QVector3D m_position;
    bool m_collected;
    float m_rotationY;
    float m_bobTimer;
    float m_bobOffset;
};

#endif // ACCESSKEYPICKUP_H
