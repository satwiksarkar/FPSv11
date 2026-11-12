#include "Player.h"
#include "GameConfig.h"
#include "GameWorld.h"
#include <QtMath>
#include <QDebug>
#include <QQuickWindow>
#include <QCursor>

Player::Player(QObject *parent)
    : QObject(parent)
    , m_world(nullptr)
    , m_healthSystem(new HealthSystem(GameConfig::MAX_PLAYER_HEALTH, this))
    , m_inventory(new Inventory(this))
    , m_position(250.0f, 0.0f, 1350.0f)
    , m_verticalVelocity(0.0f)
    , m_isGrounded(true)
    , m_yaw(0.0f)
    , m_pitch(0.0f)
    , m_currentEyeHeight(GameConfig::EYE_HEIGHT_STAND)
    , m_isCrouching(false)
    , m_moveForward(false)
    , m_moveBackward(false)
    , m_moveLeft(false)
    , m_moveRight(false)
    , m_isMoving(false)
    , m_hasHeavyWeapon(false)
    , m_currentWeaponIndex(0)
{
    // Re-emit HealthSystem events for QML bindings
    connect(m_healthSystem, &HealthSystem::healthChanged, this, &Player::healthChanged);
    connect(m_healthSystem, &HealthSystem::damageTaken, this, &Player::damageTaken);
    connect(m_healthSystem, &HealthSystem::healed, this, &Player::healed);
    connect(m_healthSystem, &HealthSystem::died, this, &Player::died);

    qDebug() << "[Player] Initialized at spawn position:" << m_position << "with HealthSystem & Inventory";
}

GameWorld* Player::world() const
{
    return m_world;
}

void Player::setWorld(GameWorld *world)
{
    if (m_world != world) {
        m_world = world;
        emit worldChanged();
    }
}

HealthSystem* Player::healthSystem() const
{
    return m_healthSystem;
}

Inventory* Player::inventory() const
{
    return m_inventory;
}

QVector3D Player::position() const
{
    return m_position;
}

void Player::setPosition(const QVector3D &pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged(m_position);
        emit cameraPositionChanged(cameraPosition());
    }
}

QVector3D Player::cameraPosition() const
{
    return QVector3D(m_position.x(), m_position.y() + m_currentEyeHeight, m_position.z());
}

QVector3D Player::cameraRotation() const
{
    // Qt Quick 3D Euler angles: Pitch (X-axis tilt), -Yaw (Y-axis turn), Roll (0)
    return QVector3D(m_pitch, -m_yaw, 0.0f);
}

float Player::yaw() const
{
    return m_yaw;
}

float Player::pitch() const
{
    return m_pitch;
}

int Player::health() const
{
    return m_healthSystem->health();
}

int Player::maxHealth() const
{
    return m_healthSystem->maxHealth();
}

bool Player::isDead() const
{
    return m_healthSystem->isDead();
}

bool Player::isCrouching() const
{
    return m_isCrouching;
}

bool Player::isGrounded() const
{
    return m_isGrounded;
}

bool Player::isMoving() const
{
    return m_isMoving;
}

void Player::setMoveInput(bool forward, bool backward, bool left, bool right)
{
    m_moveForward = forward;
    m_moveBackward = backward;
    m_moveLeft = left;
    m_moveRight = right;

    bool wasMoving = m_isMoving;
    m_isMoving = (m_moveForward || m_moveBackward || m_moveLeft || m_moveRight);
    if (wasMoving != m_isMoving) {
        emit movingChanged(m_isMoving);
    }
}

void Player::handleMouseMove(float deltaX, float deltaY)
{
    if (isDead()) return;

    // Apply mouse sensitivity
    m_yaw += deltaX * GameConfig::MOUSE_SENSITIVITY;
    m_pitch -= deltaY * GameConfig::MOUSE_SENSITIVITY;

    // Normalize yaw to [0, 360)
    if (m_yaw >= 360.0f) m_yaw -= 360.0f;
    if (m_yaw < 0.0f) m_yaw += 360.0f;

    // Clamp vertical pitch to prevent gimbal flip
    m_pitch = qBound(GameConfig::PITCH_LIMIT_MIN, m_pitch, GameConfig::PITCH_LIMIT_MAX);

    emit cameraRotationChanged(cameraRotation());
}

void Player::jump()
{
    if (m_isGrounded && !isDead()) {
        m_verticalVelocity = GameConfig::PLAYER_JUMP_VELOCITY;
        m_isGrounded = false;
        emit groundedChanged(m_isGrounded);
    }
}

void Player::setCrouch(bool crouch)
{
    if (m_isCrouching != crouch) {
        m_isCrouching = crouch;
        emit crouchChanged(m_isCrouching);
    }
}

void Player::setRotation(float yaw, float pitch)
{
    m_yaw = yaw;
    m_pitch = qBound(GameConfig::PITCH_LIMIT_MIN, pitch, GameConfig::PITCH_LIMIT_MAX);
    emit cameraRotationChanged(cameraRotation());
}

void Player::update(float deltaTime)
{
    if (isDead()) {
        return;
    }

    // Smooth crouch eye-height transition
    float targetEyeHeight = m_isCrouching ? GameConfig::EYE_HEIGHT_CROUCH : GameConfig::EYE_HEIGHT_STAND;
    m_currentEyeHeight += (targetEyeHeight - m_currentEyeHeight) * qMin(1.0f, deltaTime * GameConfig::CROUCH_TRANSITION_SPEED);

    // Compute forward & right vectors based on camera yaw
    float yawRad = qDegreesToRadians(m_yaw);
    QVector3D forward(qSin(yawRad), 0.0f, -qCos(yawRad));
    QVector3D right(qCos(yawRad), 0.0f, qSin(yawRad));

    QVector3D wishDir(0.0f, 0.0f, 0.0f);
    if (m_moveForward) wishDir += forward;
    if (m_moveBackward) wishDir -= forward;
    if (m_moveRight) wishDir += right;
    if (m_moveLeft) wishDir -= right;

    if (!wishDir.isNull()) {
        wishDir.normalize();
    }

    // Determine current speed based on crouching state
    float currentSpeed = m_isCrouching ? GameConfig::PLAYER_CROUCH_SPEED : GameConfig::PLAYER_WALK_SPEED;
    QVector3D horizontalMovement = wishDir * currentSpeed * deltaTime;

    // Vertical physics (Gravity & Jump)
    if (!m_isGrounded) {
        m_verticalVelocity -= GameConfig::GRAVITY * deltaTime;
    }

    QVector3D intendedPos = m_position;
    intendedPos += horizontalMovement;
    intendedPos.setY(intendedPos.y() + m_verticalVelocity * deltaTime);

    // Floor collision
    if (intendedPos.y() <= 0.0f) {
        intendedPos.setY(0.0f);
        m_verticalVelocity = 0.0f;
        if (!m_isGrounded) {
            m_isGrounded = true;
            emit groundedChanged(m_isGrounded);
        }
    } else {
        if (m_isGrounded) {
            m_isGrounded = false;
            emit groundedChanged(m_isGrounded);
        }
    }

    // Collision resolution against arena walls and door
    if (m_world) {
        m_position = m_world->resolveCollision(m_position, intendedPos, 35.0f);
    } else {
        m_position.setX(qBound(-GameConfig::BOUNDARY_LIMIT, intendedPos.x(), GameConfig::BOUNDARY_LIMIT));
        m_position.setY(intendedPos.y());
        m_position.setZ(qBound(-GameConfig::BOUNDARY_LIMIT, intendedPos.z(), GameConfig::BOUNDARY_LIMIT));
    }

    emit positionChanged(m_position);
    emit cameraPositionChanged(cameraPosition());
}

void Player::takeDamage(int amount)
{
    m_healthSystem->takeDamage(amount);
}

void Player::heal(int amount)
{
    m_healthSystem->heal(amount);
}

bool Player::useInventoryItem(int itemTypeIndex)
{
    if (itemTypeIndex == 0) return useFoodPack();
    if (itemTypeIndex == 1) return useBandage();
    if (itemTypeIndex == 2) return useMedkit();
    return false;
}

bool Player::useFoodPack()
{
    return m_inventory->useFoodPack(m_healthSystem);
}

bool Player::useBandage()
{
    return m_inventory->useBandage(m_healthSystem);
}

bool Player::useMedkit()
{
    return m_inventory->useMedkit(m_healthSystem);
}

void Player::reset()
{
    m_position = m_world ? m_world->spawnPosition() : QVector3D(0.0f, 0.0f, 150.0f);
    m_verticalVelocity = 0.0f;
    m_isGrounded = true;
    m_yaw = 0.0f;
    m_pitch = 0.0f;
    m_currentEyeHeight = GameConfig::EYE_HEIGHT_STAND;
    m_isCrouching = false;
    m_moveForward = false;
    m_moveBackward = false;
    m_moveLeft = false;
    m_moveRight = false;
    m_isMoving = false;

    m_healthSystem->reset();
    m_inventory->reset();
    m_hasHeavyWeapon = false;
    m_currentWeaponIndex = 0;

    emit positionChanged(m_position);
    emit cameraPositionChanged(cameraPosition());
    emit cameraRotationChanged(cameraRotation());
    emit crouchChanged(m_isCrouching);
    emit groundedChanged(m_isGrounded);
    emit movingChanged(m_isMoving);
    emit hasHeavyWeaponChanged(false);
    emit currentWeaponIndexChanged(0);
}

bool Player::hasHeavyWeapon() const { return m_hasHeavyWeapon; }

void Player::setHasHeavyWeapon(bool has)
{
    if (m_hasHeavyWeapon != has) {
        m_hasHeavyWeapon = has;
        emit hasHeavyWeaponChanged(m_hasHeavyWeapon);
    }
}

int Player::currentWeaponIndex() const { return m_currentWeaponIndex; }

void Player::setCurrentWeaponIndex(int index)
{
    if (m_currentWeaponIndex != index) {
        m_currentWeaponIndex = index;
        emit currentWeaponIndexChanged(m_currentWeaponIndex);
    }
}

void Player::switchWeapon()
{
    if (!m_hasHeavyWeapon) {
        m_currentWeaponIndex = 0;
        return;
    }
    m_currentWeaponIndex = (m_currentWeaponIndex == 0) ? 1 : 0;
    qDebug() << "[Player] Switched active weapon to:" << (m_currentWeaponIndex == 0 ? "Sniper Rifle" : "Plasma Repeater");
    emit currentWeaponIndexChanged(m_currentWeaponIndex);
}

void Player::giveHeavyWeapon()
{
    if (!m_hasHeavyWeapon) {
        m_hasHeavyWeapon = true;
        m_currentWeaponIndex = 1; // Auto-equip on pickup
        qDebug() << "[Player] Acquired Heavy Weapon (Plasma Repeater)! Auto-equipped.";
        emit hasHeavyWeaponChanged(true);
        emit currentWeaponIndexChanged(m_currentWeaponIndex);
    }
}

void Player::centerCursor(QObject *windowObj)
{
    QQuickWindow *window = qobject_cast<QQuickWindow*>(windowObj);
    if (window) {
        QPoint centerLocal(window->width() / 2, window->height() / 2);
        QPoint centerGlobal = window->mapToGlobal(centerLocal);
        QCursor::setPos(centerGlobal);
    }
}
