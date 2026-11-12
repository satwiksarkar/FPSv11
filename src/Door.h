#ifndef DOOR_H
#define DOOR_H

#include <QObject>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>

/**
 * @brief The Door class manages the start room barrier and opening sequence.
 * 
 * When shot by the sniper rifle or triggered with interaction key 'E',
 * the door transitions to the open state, revealing the three environment paths.
 */
class Door : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isOpen READ isOpen WRITE setOpen NOTIFY openChanged)
    Q_PROPERTY(bool isOpening READ isOpening NOTIFY openingChanged)
    Q_PROPERTY(float openProgress READ openProgress WRITE setOpenProgress NOTIFY openProgressChanged)
    Q_PROPERTY(float currentHeight READ currentHeight NOTIFY openProgressChanged)
    Q_PROPERTY(QVector3D position READ position CONSTANT)

public:
    explicit Door(QObject *parent = nullptr);

    bool isOpen() const;
    void setOpen(bool open);

    bool isOpening() const;
    float openProgress() const;
    void setOpenProgress(float progress);

    float currentHeight() const;
    QVector3D position() const;

    Q_INVOKABLE void open();
    Q_INVOKABLE void close();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void takeHit();
    Q_INVOKABLE void update(float deltaTime);
    Q_INVOKABLE void reset();

signals:
    void openChanged(bool isOpen);
    void openingChanged(bool isOpening);
    void openProgressChanged(float progress);
    void doorOpened();
    void doorClosed();
    void doorHit();

private:
    bool m_isOpen;
    bool m_isOpening;
    float m_openProgress;
    float m_closeHeight;
    float m_openHeight;
    QVector3D m_position;
};

#endif // DOOR_H
