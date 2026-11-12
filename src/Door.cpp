#include "Door.h"
#include "GameConfig.h"
#include <QDebug>
#include <QtMath>

Door::Door(QObject *parent)
    : QObject(parent)
    , m_isOpen(false)
    , m_isOpening(false)
    , m_isClosing(false)
    , m_blocking(true)
    , m_openProgress(0.0f)
    , m_animSpeed(1.8f) // ~0.556s full open/close slide duration
    , m_closeHeight(110.0f)
    , m_openHeight(360.0f)
    , m_position(0.0f, 110.0f, -500.0f)
    , m_doorType(DoorType::Standard)
    , m_state(DoorState::Closed)
    , m_doorId(-1)
    , m_row(-1)
    , m_col(-1)
    , m_axis(0.0f)
    , m_requiredKeyIndex(-1)
    , m_requiredKeyCount(0)
    , m_requiredKeyMask(0)
    , m_requiresBossDefeated(false)
{
}

void Door::configure(int id,
                     int row,
                     int col,
                     float axis,
                     DoorType type,
                     int requiredKeyIndex,
                     int requiredKeyCount,
                     int requiredKeyMask,
                     bool requiresBossDefeated,
                     const QString &label)
{
    m_doorId = id;
    m_row = row;
    m_col = col;
    m_axis = axis;
    m_doorType = type;
    m_requiredKeyIndex = requiredKeyIndex;
    m_requiredKeyCount = requiredKeyCount;
    m_requiredKeyMask = requiredKeyMask;
    m_requiresBossDefeated = requiresBossDefeated;
    m_label = label;

    float bs = GameConfig::BLOCK_SIZE;
    m_position = QVector3D((col + 0.5f) * bs, 0.0f, (row + 0.5f) * bs);

    emit configChanged();
    emit positionChanged();

    reset();
}

bool Door::isOpen() const
{
    return m_isOpen;
}

void Door::setOpen(bool open)
{
    DoorState targetState = open ? DoorState::Open : ((m_doorType == DoorType::Standard) ? DoorState::Closed : DoorState::Locked);
    float targetProgress = open ? 1.0f : 0.0f;

    bool changed = (m_isOpen != open) || m_isOpening || m_isClosing || !qFuzzyCompare(m_openProgress, targetProgress);

    m_isOpen = open;
    m_isOpening = false;
    m_isClosing = false;
    m_openProgress = targetProgress;

    setStateInternal(targetState);
    updateBlockingFlag();

    if (changed) {
        emit openChanged(m_isOpen);
        emit openingChanged(false);
        emit closingChanged(false);
        emit openProgressChanged(m_openProgress);
        if (m_isOpen) {
            emit doorOpened();
        } else {
            emit doorClosed();
        }
    }
}

bool Door::isOpening() const
{
    return m_isOpening;
}

bool Door::isClosing() const
{
    return m_isClosing;
}

bool Door::isLocked() const
{
    return m_state == DoorState::Locked;
}

bool Door::isBlocking() const
{
    // Strict clearance rule: door stays blocking until visual panels have fully cleared (openProgress >= 1.0f).
    return m_blocking;
}

float Door::openProgress() const
{
    return m_openProgress;
}

void Door::setOpenProgress(float progress)
{
    float clamped = qBound(0.0f, progress, 1.0f);
    if (!qFuzzyCompare(m_openProgress, clamped)) {
        m_openProgress = clamped;
        updateBlockingFlag();
        emit openProgressChanged(m_openProgress);
    }
}

float Door::currentHeight() const
{
    return m_closeHeight + (m_openHeight - m_closeHeight) * m_openProgress;
}

QVector3D Door::position() const
{
    return m_position;
}

Door::DoorType Door::doorType() const
{
    return m_doorType;
}

Door::DoorState Door::doorState() const
{
    return m_state;
}

int Door::doorId() const
{
    return m_doorId;
}

int Door::row() const
{
    return m_row;
}

int Door::col() const
{
    return m_col;
}

float Door::axis() const
{
    return m_axis;
}

int Door::requiredKeyIndex() const
{
    return m_requiredKeyIndex;
}

int Door::requiredKeyCount() const
{
    return m_requiredKeyCount;
}

int Door::requiredKeyMask() const
{
    return m_requiredKeyMask;
}

bool Door::requiresBossDefeated() const
{
    return m_requiresBossDefeated;
}

QString Door::lockedReason() const
{
    return m_lockedReason;
}

QString Door::label() const
{
    return m_label;
}

QString Door::defaultLockedReason() const
{
    switch (m_doorType) {
    case DoorType::Standard:
        return QString();
    case DoorType::KeyLocked:
        return QStringLiteral("[LOCKED] REQUIRES ACCESS KEY %1").arg(m_requiredKeyIndex + 1);
    case DoorType::AreaLocked:
        return QStringLiteral("[LOCKED] REQUIRES %1 ACCESS KEYS").arg(m_requiredKeyCount);
    case DoorType::MainExit:
        if (m_requiresBossDefeated) {
            return QStringLiteral("[LOCKED] DESTROY VENTS, DEFEAT BOSS & COLLECT 4 KEYS");
        }
        return QStringLiteral("[LOCKED] REQUIRES ALL 4 ACCESS KEYS");
    }
    return QStringLiteral("[LOCKED]");
}

void Door::updateBlockingFlag()
{
    // Release collision blocking ONLY when sliding panels have reached full 100-unit clearance (1.0f)
    bool shouldBlock = (m_openProgress < 1.0f) || (m_state != DoorState::Open);
    if (m_blocking != shouldBlock) {
        m_blocking = shouldBlock;
        emit blockingChanged(m_blocking);
    }
}

void Door::setStateInternal(DoorState newState)
{
    if (m_state != newState) {
        m_state = newState;
        emit stateChanged(m_state);
    }
}

bool Door::tryOpen(bool accessGranted, const QString &denyReason)
{
    // Ignore conflicting input while already animating
    if (m_state == DoorState::Opening || m_state == DoorState::Closing) {
        return false;
    }

    if (m_state == DoorState::Open) {
        return false;
    }

    if (m_state == DoorState::Locked) {
        if (!accessGranted) {
            QString reason = denyReason.isEmpty() ? defaultLockedReason() : denyReason;
            if (m_lockedReason != reason) {
                m_lockedReason = reason;
                emit lockedReasonChanged();
            }
            emit doorAccessDenied(m_lockedReason);
            qDebug() << "[Door]" << m_doorId << "access denied:" << m_lockedReason;
            return false;
        }

        if (!m_lockedReason.isEmpty()) {
            m_lockedReason.clear();
            emit lockedReasonChanged();
        }
        setStateInternal(DoorState::Closed);
        emit doorUnlocked();
        qDebug() << "[Door]" << m_doorId << "unlocked!";
    }

    // Closed -> Opening
    m_isOpening = true;
    m_isClosing = false;
    m_isOpen = false;
    setStateInternal(DoorState::Opening);
    updateBlockingFlag();
    emit openingChanged(true);
    emit closingChanged(false);
    emit doorAnimationStarted(true);
    qDebug() << "[Door]" << m_doorId << "opening initiated.";
    return true;
}

bool Door::tryClose(bool isObstructed)
{
    // Ignore conflicting input while already animating or not open
    if (m_state == DoorState::Opening || m_state == DoorState::Closing) {
        return false;
    }

    if (m_state != DoorState::Open) {
        return false;
    }

    // Anti-crush / anti-trap check: refuse closing while player or enemy overlaps doorway tile
    if (isObstructed) {
        emit doorObstructed();
        qDebug() << "[Door]" << m_doorId << "close blocked: entity inside doorway.";
        return false;
    }

    // Open -> Closing
    m_isOpen = false;
    m_isOpening = false;
    m_isClosing = true;
    setStateInternal(DoorState::Closing);
    updateBlockingFlag();
    emit openChanged(false);
    emit openingChanged(false);
    emit closingChanged(true);
    emit doorAnimationStarted(false);
    qDebug() << "[Door]" << m_doorId << "closing initiated.";
    return true;
}

bool Door::interact(bool accessGranted, const QString &denyReason, bool isObstructed)
{
    switch (m_state) {
    case DoorState::Locked:
        return tryOpen(accessGranted, denyReason);
    case DoorState::Closed:
        return tryOpen(true);
    case DoorState::Open:
        return tryClose(isObstructed);
    case DoorState::Opening:
    case DoorState::Closing:
        return false; // Prevent conflicting transition mid-animation
    }
    return false;
}

void Door::open()
{
    tryOpen(m_doorType == DoorType::Standard, defaultLockedReason());
}

void Door::close()
{
    tryClose(false);
}

void Door::toggle()
{
    if (m_state == DoorState::Open) {
        tryClose(false);
    } else if (m_state == DoorState::Closed || m_state == DoorState::Locked) {
        tryOpen(m_doorType == DoorType::Standard, defaultLockedReason());
    }
}

void Door::takeHit()
{
    emit doorHit();
    if (m_doorType == DoorType::Standard && m_state == DoorState::Closed) {
        qDebug() << "[Door] Door shot by player! Opening...";
        tryOpen(true);
    }
}

void Door::update(float deltaTime, bool isObstructed)
{
    float dt = qBound(0.0f, deltaTime, 0.1f);

    if (m_state == DoorState::Opening) {
        m_openProgress = qMin(1.0f, m_openProgress + dt * m_animSpeed);
        if (m_openProgress >= 1.0f) {
            m_openProgress = 1.0f;
            m_isOpening = false;
            m_isOpen = true;
            setStateInternal(DoorState::Open);
            updateBlockingFlag(); // Only now does blocking transition to false (openProgress == 1.0f)
            emit openingChanged(false);
            emit openChanged(true);
            emit doorOpened();
            qDebug() << "[Door]" << m_doorId << "fully open (collision released).";
        } else {
            updateBlockingFlag();
        }
        emit openProgressChanged(m_openProgress);
    } else if (m_state == DoorState::Closing) {
        // Anti-crush / anti-trap runtime guard: if an entity stepped into the doorway before panels closed, reverse cleanly
        if (isObstructed) {
            m_isClosing = false;
            m_isOpening = true;
            setStateInternal(DoorState::Opening);
            updateBlockingFlag();
            emit closingChanged(false);
            emit openingChanged(true);
            emit doorObstructed();
            qDebug() << "[Door]" << m_doorId << "anti-crush triggered during close: reopening.";
            return;
        }

        m_openProgress = qMax(0.0f, m_openProgress - dt * m_animSpeed);
        updateBlockingFlag();
        if (m_openProgress <= 0.0f) {
            m_openProgress = 0.0f;
            m_isClosing = false;
            m_isOpen = false;
            setStateInternal(DoorState::Closed);
            updateBlockingFlag();
            emit closingChanged(false);
            emit doorClosed();
            qDebug() << "[Door]" << m_doorId << "fully closed.";
        }
        emit openProgressChanged(m_openProgress);
    }
}

void Door::reset()
{
    m_isOpen = false;
    m_isOpening = false;
    m_isClosing = false;
    m_openProgress = 0.0f;

    DoorState initialState = (m_doorType == DoorType::Standard) ? DoorState::Closed : DoorState::Locked;
    QString initialReason = defaultLockedReason();
    if (m_lockedReason != initialReason) {
        m_lockedReason = initialReason;
        emit lockedReasonChanged();
    }

    setStateInternal(initialState);
    updateBlockingFlag();

    emit openChanged(false);
    emit openingChanged(false);
    emit closingChanged(false);
    emit openProgressChanged(0.0f);
}
