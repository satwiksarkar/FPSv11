#ifndef PLAYER_H
#define PLAYER_H

#include <QObject>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>
#include "GameWorld.h"
#include "HealthSystem.h"
#include "Inventory.h"

/**
 * @brief The Player class encapsulates first-person controller logic.
 * 
 * Manages player translation, WASD movement vectors relative to camera yaw,
 * mouse-look pitch/yaw clamping, jumping with gravity, crouching height lerping,
 * delta-time updates, health management via HealthSystem, and items via Inventory.
 */
class Player : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(GameWorld* world READ world WRITE setWorld NOTIFY worldChanged)
    Q_PROPERTY(HealthSystem* healthSystem READ healthSystem CONSTANT)
    Q_PROPERTY(Inventory* inventory READ inventory CONSTANT)
    Q_PROPERTY(QVector3D position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(QVector3D cameraPosition READ cameraPosition NOTIFY cameraPositionChanged)
    Q_PROPERTY(QVector3D cameraRotation READ cameraRotation NOTIFY cameraRotationChanged)
    Q_PROPERTY(float yaw READ yaw NOTIFY cameraRotationChanged)
    Q_PROPERTY(float pitch READ pitch NOTIFY cameraRotationChanged)
    Q_PROPERTY(int health READ health NOTIFY healthChanged)
    Q_PROPERTY(int maxHealth READ maxHealth CONSTANT)
    Q_PROPERTY(bool isDead READ isDead NOTIFY healthChanged)
    Q_PROPERTY(bool isCrouching READ isCrouching NOTIFY crouchChanged)
    Q_PROPERTY(bool isGrounded READ isGrounded NOTIFY groundedChanged)
    Q_PROPERTY(bool isMoving READ isMoving NOTIFY movingChanged)
    Q_PROPERTY(bool hasHeavyWeapon READ hasHeavyWeapon WRITE setHasHeavyWeapon NOTIFY hasHeavyWeaponChanged)
    Q_PROPERTY(int currentWeaponIndex READ currentWeaponIndex WRITE setCurrentWeaponIndex NOTIFY currentWeaponIndexChanged)

public:
    explicit Player(QObject *parent = nullptr);

    Q_INVOKABLE bool hasHeavyWeapon() const;
    Q_INVOKABLE void setHasHeavyWeapon(bool has);
    Q_INVOKABLE int currentWeaponIndex() const;
    Q_INVOKABLE void setCurrentWeaponIndex(int index);
    Q_INVOKABLE void switchWeapon();
    Q_INVOKABLE void giveHeavyWeapon();

    // World association
    GameWorld* world() const;
    void setWorld(GameWorld *world);

    // Subsystems
    HealthSystem* healthSystem() const;
    Inventory* inventory() const;

    // Getters
    QVector3D position() const;
    QVector3D cameraPosition() const;
    QVector3D cameraRotation() const;
    float yaw() const;
    float pitch() const;
    int health() const;
    int maxHealth() const;
    bool isDead() const;
    bool isCrouching() const;
    bool isGrounded() const;
    bool isMoving() const;

    Q_INVOKABLE void setPosition(const QVector3D &pos);

    // Game loop delta-time update
    Q_INVOKABLE void update(float deltaTime);

    // Input handlers
    Q_INVOKABLE void setMoveInput(bool forward, bool backward, bool left, bool right);
    Q_INVOKABLE void handleMouseMove(float deltaX, float deltaY);
    Q_INVOKABLE void jump();
    Q_INVOKABLE void setCrouch(bool crouch);
    Q_INVOKABLE void setRotation(float yaw, float pitch);

    // Combat & Health handlers (delegated to HealthSystem)
    Q_INVOKABLE void takeDamage(int amount);
    Q_INVOKABLE void heal(int amount);
    Q_INVOKABLE void reset();

    // Inventory actions
    Q_INVOKABLE bool useInventoryItem(int itemTypeIndex);
    Q_INVOKABLE bool useFoodPack();
    Q_INVOKABLE bool useBandage();
    Q_INVOKABLE bool useMedkit();

    // Mouse lock & cursor centering
    Q_INVOKABLE void centerCursor(QObject *windowObj);

signals:
    void worldChanged();
    void positionChanged(const QVector3D &newPos);
    void cameraPositionChanged(const QVector3D &newCamPos);
    void cameraRotationChanged(const QVector3D &newCamRot);
    void healthChanged(int newHealth);
    void crouchChanged(bool isCrouching);
    void groundedChanged(bool isGrounded);
    void movingChanged(bool isMoving);
    void died();
    void damageTaken(int amount);
    void healed(int amount);
    void hasHeavyWeaponChanged(bool has);
    void currentWeaponIndexChanged(int index);

private:
    void updateCamera();

    GameWorld *m_world;
    HealthSystem *m_healthSystem;
    Inventory *m_inventory;

    // Weapon ownership & active index (0 = Sniper, 1 = Plasma Repeater)
    bool m_hasHeavyWeapon;
    int m_currentWeaponIndex;

    // Position & Kinematics
    QVector3D m_position;
    float m_verticalVelocity;
    bool m_isGrounded;

    // Camera view angles
    float m_yaw;    // Horizontal rotation (degrees)
    float m_pitch;  // Vertical look tilt (degrees)

    // Crouch & Eye Height
    float m_currentEyeHeight;
    bool m_isCrouching;

    // Movement input states
    bool m_moveForward;
    bool m_moveBackward;
    bool m_moveLeft;
    bool m_moveRight;
    bool m_isMoving;
};

#endif // PLAYER_H
