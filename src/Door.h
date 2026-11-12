#ifndef DOOR_H
#define DOOR_H

#include <QObject>
#include <QString>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>

/**
 * @brief The Door class implements interactive and security doors for Project VANGUARD.
 *
 * Supports both legacy GameWorld::m_door usage and tile-placed sliding bulkhead doors
 * with a deterministic state machine (Locked, Closed, Opening, Open, Closing),
 * synchronized collision blocking until openProgress reaches 1.0, and anti-crush checks.
 */
class Door : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // Legacy compatibility properties (GameWorld::m_door & existing QML)
    Q_PROPERTY(bool isOpen READ isOpen WRITE setOpen NOTIFY openChanged)
    Q_PROPERTY(bool isOpening READ isOpening NOTIFY openingChanged)
    Q_PROPERTY(float openProgress READ openProgress WRITE setOpenProgress NOTIFY openProgressChanged)
    Q_PROPERTY(float currentHeight READ currentHeight NOTIFY openProgressChanged)
    Q_PROPERTY(QVector3D position READ position NOTIFY positionChanged)

    // Extended tile-door state & metadata properties
    Q_PROPERTY(bool isClosing READ isClosing NOTIFY closingChanged)
    Q_PROPERTY(bool isLocked READ isLocked NOTIFY stateChanged)
    Q_PROPERTY(bool blocking READ isBlocking NOTIFY blockingChanged)
    Q_PROPERTY(DoorType doorType READ doorType NOTIFY configChanged)
    Q_PROPERTY(DoorState doorState READ doorState NOTIFY stateChanged)
    Q_PROPERTY(int doorId READ doorId NOTIFY configChanged)
    Q_PROPERTY(int row READ row NOTIFY configChanged)
    Q_PROPERTY(int col READ col NOTIFY configChanged)
    Q_PROPERTY(float axis READ axis NOTIFY configChanged)
    Q_PROPERTY(int requiredKeyIndex READ requiredKeyIndex NOTIFY configChanged)
    Q_PROPERTY(int requiredKeyCount READ requiredKeyCount NOTIFY configChanged)
    Q_PROPERTY(int requiredKeyMask READ requiredKeyMask NOTIFY configChanged)
    Q_PROPERTY(bool requiresBossDefeated READ requiresBossDefeated NOTIFY configChanged)
    Q_PROPERTY(QString lockedReason READ lockedReason NOTIFY lockedReasonChanged)
    Q_PROPERTY(QString label READ label NOTIFY configChanged)

public:
    enum class DoorType {
        Standard = 0,
        KeyLocked,
        AreaLocked,
        MainExit
    };
    Q_ENUM(DoorType)

    enum class DoorState {
        Locked = 0,
        Closed,
        Opening,
        Open,
        Closing
    };
    Q_ENUM(DoorState)

    explicit Door(QObject *parent = nullptr);

    void configure(int id,
                   int row,
                   int col,
                   float axis,
                   DoorType type,
                   int requiredKeyIndex = -1,
                   int requiredKeyCount = 0,
                   int requiredKeyMask = 0,
                   bool requiresBossDefeated = false,
                   const QString &label = QString());

    // Legacy getters/setters
    bool isOpen() const;
    void setOpen(bool open);
    bool isOpening() const;
    float openProgress() const;
    void setOpenProgress(float progress);
    float currentHeight() const;
    QVector3D position() const;

    // Extended getters
    bool isClosing() const;
    bool isLocked() const;
    bool isBlocking() const;
    DoorType doorType() const;
    DoorState doorState() const;
    int doorId() const;
    int row() const;
    int col() const;
    float axis() const;
    int requiredKeyIndex() const;
    int requiredKeyCount() const;
    int requiredKeyMask() const;
    bool requiresBossDefeated() const;
    QString lockedReason() const;
    QString label() const;

    // State machine operations
    Q_INVOKABLE bool tryOpen(bool accessGranted = true, const QString &denyReason = QString());
    Q_INVOKABLE bool tryClose(bool isObstructed = false);
    Q_INVOKABLE bool interact(bool accessGranted = true,
                              const QString &denyReason = QString(),
                              bool isObstructed = false);
    Q_INVOKABLE void update(float deltaTime, bool isObstructed = false);

    // Legacy / convenience QML methods
    Q_INVOKABLE void open();
    Q_INVOKABLE void close();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void takeHit();
    Q_INVOKABLE void reset();

signals:
    void openChanged(bool isOpen);
    void openingChanged(bool isOpening);
    void closingChanged(bool isClosing);
    void openProgressChanged(float progress);
    void positionChanged();
    void stateChanged(Door::DoorState newState);
    void blockingChanged(bool blocking);
    void configChanged();
    void lockedReasonChanged();

    void doorOpened();
    void doorClosed();
    void doorHit();
    void doorAnimationStarted(bool opening);
    void doorUnlocked();
    void doorAccessDenied(const QString &reason);
    void doorObstructed(bool midCloseReversal);

private:
    QString defaultLockedReason() const;
    void updateBlockingFlag();
    void setStateInternal(DoorState newState);

    bool m_isOpen;
    bool m_isOpening;
    bool m_isClosing;
    bool m_blocking;
    bool m_reopeningUnblocked;
    float m_openProgress;
    float m_animSpeed;
    float m_closeHeight;
    float m_openHeight;
    QVector3D m_position;

    DoorType m_doorType;
    DoorState m_state;
    int m_doorId;
    int m_row;
    int m_col;
    float m_axis;
    int m_requiredKeyIndex;
    int m_requiredKeyCount;
    int m_requiredKeyMask;
    bool m_requiresBossDefeated;
    QString m_lockedReason;
    QString m_label;
};

#endif // DOOR_H
