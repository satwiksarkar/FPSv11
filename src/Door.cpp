#include "Door.h"
#include <QDebug>
#include <QtMath>

Door::Door(QObject *parent)
    : QObject(parent)
    , m_isOpen(false)
    , m_isOpening(false)
    , m_openProgress(0.0f)
    , m_closeHeight(110.0f)
    , m_openHeight(360.0f)
    , m_position(0.0f, 110.0f, -500.0f)
{
}

bool Door::isOpen() const
{
    return m_isOpen;
}

void Door::setOpen(bool open)
{
    if (m_isOpen != open) {
        m_isOpen = open;
        m_isOpening = false;
        m_openProgress = m_isOpen ? 1.0f : 0.0f;
        emit openChanged(m_isOpen);
        emit openingChanged(false);
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

float Door::openProgress() const
{
    return m_openProgress;
}

void Door::setOpenProgress(float progress)
{
    float clamped = qBound(0.0f, progress, 1.0f);
    if (!qFuzzyCompare(m_openProgress, clamped)) {
        m_openProgress = clamped;
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

void Door::open()
{
    if (!m_isOpen) {
        m_isOpening = true;
        emit openingChanged(true);
        qDebug() << "[Door] Opening animation initiated.";
    }
}

void Door::close()
{
    setOpen(false);
}

void Door::toggle()
{
    if (m_isOpen) {
        close();
    } else {
        open();
    }
}

void Door::takeHit()
{
    emit doorHit();
    if (!m_isOpen && !m_isOpening) {
        qDebug() << "[Door] Door shot by player! Opening...";
        open();
    }
}

void Door::update(float deltaTime)
{
    if (m_isOpening) {
        m_openProgress += deltaTime * 0.9f; // Opens over ~1.1 seconds
        if (m_openProgress >= 1.0f) {
            m_openProgress = 1.0f;
            m_isOpening = false;
            m_isOpen = true;
            emit openingChanged(false);
            emit openChanged(true);
            emit doorOpened();
            qDebug() << "[Door] Fully opened!";
        }
        emit openProgressChanged(m_openProgress);
    }
}

void Door::reset()
{
    m_isOpen = false;
    m_isOpening = false;
    m_openProgress = 0.0f;
    emit openChanged(false);
    emit openingChanged(false);
    emit openProgressChanged(0.0f);
}
