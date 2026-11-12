#include "Enemy.h"
#include "Player.h"
#include "GameWorld.h"
#include "GameManager.h"
#include "LevelManager.h"
#include "CollisionSystem.h"
#include "GameConfig.h"
#include <QtMath>
#include <QDebug>
#include <QRandomGenerator>
#include <QQueue>
#include <QSet>

// ==================== CONSTRUCTOR ====================

Enemy::Enemy(EnemyType type, QObject *parent)
    : QObject(parent)
    , m_type(type)
    , m_healthSystem(nullptr)
    , m_world(nullptr)
    , m_isActive(false)
    , m_position(0.0f, 0.0f, 0.0f)
    , m_rotationY(0.0f)
    , m_droneState(DroneState::Idle)
    , m_sentinelState(SentinelState::Guard)
    , m_lastSeenPlayerPos(0.0f, 0.0f, 0.0f)
    , m_aimTimer(0.0f)
    , m_searchTimer(0.0f)
    , m_attackTimer(0.0f)
    , m_pathfindTimer(0.0f)
    , m_isShooting(false)
    , m_muzzleFlashTimer(0.0f)
    , m_canShoot(false)
    , m_currentPathIndex(0)
{
    // Set type-specific constants
    if (m_type == EnemyType::Drone) {
        m_maxHp = GameConfig::DRONE_HEALTH;
        m_moveSpeed = GameConfig::DRONE_SPEED;
        m_attackRange = GameConfig::DRONE_ATTACK_RANGE;
        m_attackCooldown = GameConfig::DRONE_ATTACK_COOLDOWN;
        m_attackDamage = GameConfig::DRONE_MELEE_DAMAGE;
        m_detectRange = 2500.0f;        // ~25 blocks detect range for Drones
        m_canShoot = false;             // Default melee drone, set to true for shooter drones
        m_shootRange = 1200.0f;         // Range for shooter drone variants
        m_hitChance = 0.65f;
        m_aimDuration = 0.0f;
        m_searchDuration = 0.0f;
        m_scoreValue = 50;              // Drone small score
    } else {
        m_maxHp = GameConfig::SENTINEL_HEALTH;
        m_moveSpeed = 150.0f;           // Sentinel move speed for search/reposition
        m_attackRange = 0.0f;           // Sentinels don't melee
        m_attackCooldown = GameConfig::SENTINEL_SHOOT_INTERVAL;
        m_attackDamage = GameConfig::SENTINEL_DAMAGE;
        m_detectRange = GameConfig::SENTINEL_RANGE_TILES * GameConfig::BLOCK_SIZE;
        m_shootRange = m_detectRange;
        m_hitChance = GameConfig::SENTINEL_ACCURACY;
        m_canShoot = true;
        m_aimDuration = 0.8f;           // ~0.8s aim delay before first shot
        m_searchDuration = 4.0f;        // Search for ~4s at last seen position
        m_scoreValue = 150;             // Sentinel larger score
    }

    m_healthSystem = new HealthSystem(m_maxHp, this);

    connect(m_healthSystem, &HealthSystem::healthChanged, this, &Enemy::healthChanged);
    connect(m_healthSystem, &HealthSystem::died, this, [this]() {
        if (m_type == EnemyType::Drone) {
            m_droneState = DroneState::Dead;
        } else {
            m_sentinelState = SentinelState::Dead;
        }
        qDebug() << "[Enemy]" << (m_type == EnemyType::Drone ? "Drone" : "Sentinel") << "eliminated!";
        emit stateChanged(state());
        emit died();
    });
}

// ==================== PROPERTY GETTERS ====================

HealthSystem* Enemy::healthSystem() const { return m_healthSystem; }
Enemy::EnemyType Enemy::enemyType() const { return m_type; }

QVector3D Enemy::position() const { return m_position; }

void Enemy::setPosition(const QVector3D &pos) {
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged(m_position);
    }
}

float Enemy::rotationY() const { return m_rotationY; }

int Enemy::health() const { return m_healthSystem->health(); }
int Enemy::maxHealth() const { return m_healthSystem->maxHealth(); }
bool Enemy::isDead() const { return m_healthSystem->isDead(); }

bool Enemy::isActive() const { return m_isActive; }

void Enemy::setActive(bool active) {
    if (m_isActive != active) {
        m_isActive = active;
        emit activeChanged(active);
        emit visibleChanged();
    }
}

bool Enemy::isVisible() const {
    return m_isActive && !isDead();
}

int Enemy::scoreValue() const { return m_scoreValue; }

Enemy::EnemyState Enemy::state() const {
    if (m_type == EnemyType::Drone) {
        switch (m_droneState) {
        case DroneState::Idle:   return EnemyState::Idle;
        case DroneState::Chase:  return EnemyState::Chase;
        case DroneState::Attack: return EnemyState::Attack;
        case DroneState::Dead:   return EnemyState::Dead;
        }
    } else {
        switch (m_sentinelState) {
        case SentinelState::Guard:  return EnemyState::Guard;
        case SentinelState::Detect: return EnemyState::Detect;
        case SentinelState::Aim:    return EnemyState::Aim;
        case SentinelState::Shoot:  return EnemyState::Shoot;
        case SentinelState::Search: return EnemyState::Search;
        case SentinelState::Dead:   return EnemyState::Dead;
        }
    }
    return EnemyState::Dead;
}

QString Enemy::stateString() const {
    switch (state()) {
    case EnemyState::Idle:   return QStringLiteral("IDLE");
    case EnemyState::Chase:  return QStringLiteral("CHASE");
    case EnemyState::Attack: return QStringLiteral("ATTACK");
    case EnemyState::Guard:  return QStringLiteral("GUARD");
    case EnemyState::Detect: return QStringLiteral("DETECT");
    case EnemyState::Aim:    return QStringLiteral("AIM");
    case EnemyState::Shoot:  return QStringLiteral("SHOOT");
    case EnemyState::Search: return QStringLiteral("SEARCH");
    case EnemyState::Dead:   return QStringLiteral("DEAD");
    }
    return QStringLiteral("UNKNOWN");
}

bool Enemy::isAttacking() const {
    return state() == EnemyState::Attack || state() == EnemyState::Shoot;
}

bool Enemy::isShooting() const { return m_isShooting; }

bool Enemy::canShoot() const { return m_canShoot; }

void Enemy::setCanShoot(bool canShoot) {
    if (m_canShoot != canShoot) {
        m_canShoot = canShoot;
        emit canShootChanged(m_canShoot);
    }
}

GameWorld* Enemy::world() const { return m_world; }

void Enemy::setWorld(GameWorld *world) {
    if (m_world != world) {
        m_world = world;
    }
}

// ==================== MAIN UPDATE ====================

void Enemy::update(float deltaTime, const QVector3D &playerPos,
                   Player *player, GameManager *gameManager)
{
    if (!m_isActive || isDead() || deltaTime <= 0.0f) return;

    // Check game state - don't update if paused or story
    if (gameManager && (gameManager->isPaused() || gameManager->isStoryText())) return;

    // Process muzzle flash timer
    if (m_muzzleFlashTimer > 0.0f) {
        m_muzzleFlashTimer -= deltaTime;
        if (m_muzzleFlashTimer <= 0.0f) {
            m_isShooting = false;
            emit isShootingChanged(false);
        }
    }

    // Attack cooldown
    if (m_attackTimer > 0.0f) {
        m_attackTimer -= deltaTime;
    }

    // Anti-clipping / Unstuck recovery: ensure enemies never remain inside crates or walls
    if (m_world && m_world->levelManager()) {
        LevelManager *lm = m_world->levelManager();
        float bs = GameConfig::BLOCK_SIZE;
        int curC = qFloor(m_position.x() / bs);
        int curR = qFloor(m_position.z() / bs);
        if (lm->isSolidTile(curR, curC)) {
            float bestDistSq = 1e9f;
            QVector3D bestPos = m_position;
            for (int dr = -2; dr <= 2; ++dr) {
                for (int dc = -2; dc <= 2; ++dc) {
                    if (dr == 0 && dc == 0) continue;
                    int nr = curR + dr;
                    int nc = curC + dc;
                    if (nr >= 0 && nr < lm->mapHeight() && nc >= 0 && nc < lm->mapWidth() && !lm->isSolidTile(nr, nc)) {
                        QVector3D candidate((nc + 0.5f) * bs, 0.0f, (nr + 0.5f) * bs);
                        float dSq = (candidate - m_position).lengthSquared();
                        if (dSq < bestDistSq) {
                            bestDistSq = dSq;
                            bestPos = candidate;
                        }
                    }
                }
            }
            if (bestDistSq < 1e8f) {
                m_position = bestPos;
                emit positionChanged(m_position);
            }
        }
    }

    // Pathfinding refresh timer
    m_pathfindTimer -= deltaTime;

    // Dispatch to type-specific update
    if (m_type == EnemyType::Drone) {
        updateDrone(deltaTime, playerPos, player);
    } else {
        updateSentinel(deltaTime, playerPos, player);
    }
}

// ==================== DRONE FSM ====================

void Enemy::updateDrone(float deltaTime, const QVector3D &playerPos, Player *player)
{
    EnemyState prevState = state();

    float dx = playerPos.x() - m_position.x();
    float dz = playerPos.z() - m_position.z();
    float dist = qSqrt(dx * dx + dz * dz);

    if (dist <= m_attackRange) {
        // CLOSE-RANGE ATTACK: Both shooter and melee drones deal contact damage when close
        m_droneState = DroneState::Attack;
        faceTarget(playerPos);

        if (m_attackTimer <= 0.0f) {
            m_attackTimer = m_attackCooldown;
            if (player && !player->isDead()) {
                player->takeDamage(m_attackDamage);
                emit attackedPlayer(m_attackDamage);
                qDebug() << "[Drone] Close-range contact damage:" << m_attackDamage;
            }
        }
    } else if (dist <= m_detectRange) {
        bool canSee = hasLineOfSight(playerPos);

        // If this drone can shoot, has line of sight, and is within shoot range:
        if (m_canShoot && canSee && dist <= m_shootRange) {
            faceTarget(playerPos);
            m_droneState = DroneState::Chase;

            // Advance along BFS path towards player while maintaining firing position
            if (m_pathfindTimer <= 0.0f) {
                m_pathfindTimer = GameConfig::ENEMY_PATHFIND_REFRESH;
                computeBFSPath(playerPos);
            }
            if (dist > m_attackRange * 1.5f) {
                moveAlongPath(deltaTime, m_moveSpeed * 0.75f);
            }

            // Shoot plasma bolts on cooldown
            if (m_attackTimer <= 0.0f) {
                m_attackTimer = m_attackCooldown;

                double roll = QRandomGenerator::global()->generateDouble();
                bool didHit = (roll <= m_hitChance);

                m_isShooting = true;
                m_muzzleFlashTimer = 0.12f;
                emit isShootingChanged(true);

                if (didHit && player && !player->isDead()) {
                    player->takeDamage(m_attackDamage);
                    emit attackedPlayer(m_attackDamage);
                }

                // Fire from elevated drone weapon position (Y: ~85)
                emit shotFired(m_position + QVector3D(0, 85, 0), playerPos, didHit);
                qDebug() << "[Shooter Drone] Plasma bolt fired!" << (didHit ? "HIT" : "MISS");
            }
        } else {
            // Non-shooting drone (or shooting drone without clear LOS):
            // CHASE: pursue the player using BFS to engage
            m_droneState = DroneState::Chase;

            if (m_pathfindTimer <= 0.0f) {
                m_pathfindTimer = GameConfig::ENEMY_PATHFIND_REFRESH;
                computeBFSPath(playerPos);
            }

            moveAlongPath(deltaTime, m_moveSpeed);
            faceTarget(playerPos);
        }
    } else {
        // IDLE: player too far
        m_droneState = DroneState::Idle;
    }

    if (state() != prevState) {
        emit stateChanged(state());
    }
}

// ==================== SENTINEL FSM ====================

void Enemy::updateSentinel(float deltaTime, const QVector3D &playerPos, Player *player)
{
    EnemyState prevState = state();

    float dx = playerPos.x() - m_position.x();
    float dz = playerPos.z() - m_position.z();
    float dist = qSqrt(dx * dx + dz * dz);

    bool canSee = (dist <= m_detectRange) && hasLineOfSight(playerPos);

    switch (m_sentinelState) {
    case SentinelState::Guard:
        if (canSee) {
            m_sentinelState = SentinelState::Detect;
            m_lastSeenPlayerPos = playerPos;
            qDebug() << "[Sentinel] Player detected at distance:" << dist;
        }
        break;

    case SentinelState::Detect:
        faceTarget(playerPos);
        if (!canSee) {
            // Lost sight, go search last known position
            m_sentinelState = SentinelState::Search;
            m_searchTimer = m_searchDuration;
            m_pathfindTimer = 0.0f;
        } else {
            m_lastSeenPlayerPos = playerPos;
            m_aimTimer = m_aimDuration;
            m_sentinelState = SentinelState::Aim;
        }
        break;

    case SentinelState::Aim:
        faceTarget(playerPos);
        if (!canSee) {
            m_sentinelState = SentinelState::Search;
            m_searchTimer = m_searchDuration;
            m_pathfindTimer = 0.0f;
        } else {
            m_lastSeenPlayerPos = playerPos;
            m_aimTimer -= deltaTime;
            if (m_aimTimer <= 0.0f) {
                m_sentinelState = SentinelState::Shoot;
                m_attackTimer = 0.0f; // Fire immediately after aim
            }
        }
        break;

    case SentinelState::Shoot:
        faceTarget(playerPos);
        if (!canSee) {
            m_sentinelState = SentinelState::Search;
            m_searchTimer = m_searchDuration;
            m_pathfindTimer = 0.0f;
        } else {
            m_lastSeenPlayerPos = playerPos;

            if (m_attackTimer <= 0.0f) {
                m_attackTimer = m_attackCooldown;

                // Roll accuracy
                double roll = QRandomGenerator::global()->generateDouble();
                bool didHit = (roll <= m_hitChance);

                m_isShooting = true;
                m_muzzleFlashTimer = 0.1f;
                emit isShootingChanged(true);

                if (didHit && player && !player->isDead()) {
                    player->takeDamage(m_attackDamage);
                    emit attackedPlayer(m_attackDamage);
                }

                emit shotFired(m_position + QVector3D(0, 110, 0), playerPos, didHit);
                qDebug() << "[Sentinel] Shot fired!" << (didHit ? "HIT" : "MISS");
            }
        }
        break;

    case SentinelState::Search:
        // Move to last seen position via BFS
        if (m_pathfindTimer <= 0.0f) {
            m_pathfindTimer = GameConfig::ENEMY_PATHFIND_REFRESH;
            computeBFSPath(m_lastSeenPlayerPos);
        }
        moveAlongPath(deltaTime, m_moveSpeed * 0.6f);

        // Check if player reappears
        if (canSee) {
            m_lastSeenPlayerPos = playerPos;
            m_aimTimer = m_aimDuration * 0.5f; // Quicker re-aim
            m_sentinelState = SentinelState::Aim;
            break;
        }

        m_searchTimer -= deltaTime;
        if (m_searchTimer <= 0.0f) {
            m_sentinelState = SentinelState::Guard;
            qDebug() << "[Sentinel] Search complete, returning to GUARD.";
        }
        break;

    case SentinelState::Dead:
        break;
    }

    if (state() != prevState) {
        emit stateChanged(state());
    }
}

// ==================== BFS PATHFINDING ====================

void Enemy::computeBFSPath(const QVector3D &targetPos)
{
    m_bfsPath.clear();
    m_currentPathIndex = 0;

    if (!m_world || !m_world->levelManager()) return;

    LevelManager *lm = m_world->levelManager();
    float bs = GameConfig::BLOCK_SIZE;
    int mapW = lm->mapWidth();
    int mapH = lm->mapHeight();

    // Convert world positions to tile coordinates
    int startCol = qFloor(m_position.x() / bs);
    int startRow = qFloor(m_position.z() / bs);
    int endCol = qFloor(targetPos.x() / bs);
    int endRow = qFloor(targetPos.z() / bs);

    // Clamp to map bounds
    startCol = qBound(0, startCol, mapW - 1);
    startRow = qBound(0, startRow, mapH - 1);
    endCol = qBound(0, endCol, mapW - 1);
    endRow = qBound(0, endRow, mapH - 1);

    if (startCol == endCol && startRow == endRow) {
        return;
    }

    // Direct line of sight short-circuit when close
    float dx = targetPos.x() - m_position.x();
    float dz = targetPos.z() - m_position.z();
    if ((dx * dx + dz * dz) < (3.5f * bs * 3.5f * bs) && hasLineOfSight(targetPos)) {
        m_bfsPath.append(qMakePair(endRow, endCol));
        return;
    }

    // If start is solid (enemy stuck), escape to nearest non-solid floor tile
    if (lm->isSolidTile(startRow, startCol)) {
        bool foundEscape = false;
        for (int dr = -1; dr <= 1 && !foundEscape; ++dr) {
            for (int dc = -1; dc <= 1 && !foundEscape; ++dc) {
                int nr = startRow + dr;
                int nc = startCol + dc;
                if (nr >= 0 && nr < mapH && nc >= 0 && nc < mapW && !lm->isSolidTile(nr, nc)) {
                    startRow = nr;
                    startCol = nc;
                    m_position = QVector3D((nc + 0.5f) * bs, 0.0f, (nr + 0.5f) * bs);
                    emit positionChanged(m_position);
                    foundEscape = true;
                }
            }
        }
        if (!foundEscape) return;
    }
    if (lm->isSolidTile(endRow, endCol)) {
        // Find nearest non-solid tile to the target
        bool found = false;
        for (int dr = -1; dr <= 1 && !found; ++dr) {
            for (int dc = -1; dc <= 1 && !found; ++dc) {
                int nr = endRow + dr;
                int nc = endCol + dc;
                if (nr >= 0 && nr < mapH && nc >= 0 && nc < mapW && !lm->isSolidTile(nr, nc)) {
                    endRow = nr;
                    endCol = nc;
                    found = true;
                }
            }
        }
        if (!found) return;
    }

    // Zero-heap-allocation BFS traversal using static reusable vectors and visit token
    int totalCells = mapW * mapH;
    static std::vector<int> s_parent;
    static std::vector<uint32_t> s_visited;
    static uint32_t s_visitToken = 0;
    static std::vector<int> s_queue;

    if (static_cast<int>(s_parent.size()) < totalCells) {
        s_parent.resize(totalCells, -1);
        s_visited.resize(totalCells, 0);
        s_queue.resize(totalCells, 0);
    }

    s_visitToken++;
    if (s_visitToken == 0) {
        std::fill(s_visited.begin(), s_visited.end(), 0);
        s_visitToken = 1;
    }

    int startIdx = startRow * mapW + startCol;
    int endIdx = endRow * mapW + endCol;

    int qHead = 0;
    int qTail = 0;
    s_queue[qTail++] = startIdx;
    s_visited[startIdx] = s_visitToken;
    s_parent[startIdx] = -1;

    // 4-directional neighbors (up, down, left, right)
    const int dRow[4] = {-1, 1, 0, 0};
    const int dCol[4] = {0, 0, -1, 1};

    bool found = false;
    while (qHead < qTail) {
        int cur = s_queue[qHead++];
        if (cur == endIdx) {
            found = true;
            break;
        }

        int curRow = cur / mapW;
        int curCol = cur % mapW;

        for (int i = 0; i < 4; ++i) {
            int nr = curRow + dRow[i];
            int nc = curCol + dCol[i];
            if (nr < 0 || nr >= mapH || nc < 0 || nc >= mapW) continue;

            int nIdx = nr * mapW + nc;
            if (s_visited[nIdx] == s_visitToken) continue;
            if (lm->isSolidTile(nr, nc)) continue;

            s_visited[nIdx] = s_visitToken;
            s_parent[nIdx] = cur;
            s_queue[qTail++] = nIdx;
        }
    }

    if (!found) return;

    // Reconstruct path from end to start
    QList<QPair<int,int>> reversePath;
    int idx = endIdx;
    while (idx != startIdx && idx != -1) {
        int r = idx / mapW;
        int c = idx % mapW;
        reversePath.prepend(qMakePair(r, c));
        idx = s_parent[idx];
    }

    m_bfsPath = reversePath;
    m_currentPathIndex = 0;
}

QVector3D Enemy::getNextPathTarget() const
{
    if (m_currentPathIndex >= m_bfsPath.size()) {
        return m_position; // No target, stay put
    }

    float bs = GameConfig::BLOCK_SIZE;
    auto tile = m_bfsPath[m_currentPathIndex];
    // Center of the tile
    float x = (tile.second + 0.5f) * bs;
    float z = (tile.first + 0.5f) * bs;
    return QVector3D(x, 0.0f, z);
}

// ==================== MOVEMENT ALONG PATH ====================

void Enemy::moveAlongPath(float deltaTime, float speed)
{
    if (m_bfsPath.isEmpty() || m_currentPathIndex >= m_bfsPath.size()) return;

    QVector3D target = getNextPathTarget();
    float dx = target.x() - m_position.x();
    float dz = target.z() - m_position.z();
    float dist = qSqrt(dx * dx + dz * dz);

    // If we're close enough to the current path tile, advance to next
    float arrivalThreshold = GameConfig::BLOCK_SIZE * 0.3f;
    if (dist < arrivalThreshold) {
        m_currentPathIndex++;
        if (m_currentPathIndex >= m_bfsPath.size()) return;
        target = getNextPathTarget();
        dx = target.x() - m_position.x();
        dz = target.z() - m_position.z();
        dist = qSqrt(dx * dx + dz * dz);
        if (dist < 1.0f) return;
    }

    if (dist < 1.0f) return;

    float step = speed * deltaTime;
    QVector3D dir(dx / dist, 0.0f, dz / dist);
    QVector3D intendedPos = m_position + dir * step;

    // Resolve collision with walls
    if (m_world) {
        m_position = m_world->resolveCollision(m_position, intendedPos, 35.0f);
    } else {
        m_position = intendedPos;
    }
    emit positionChanged(m_position);
}

// ==================== LINE OF SIGHT (DDA) ====================

bool Enemy::hasLineOfSight(const QVector3D &targetPos) const
{
    if (!m_world) return true;

    // If enemy itself is inside a solid tile, it has zero line of sight
    if (m_world->levelManager()) {
        LevelManager *lm = m_world->levelManager();
        float bs = GameConfig::BLOCK_SIZE;
        int curC = qFloor(m_position.x() / bs);
        int curR = qFloor(m_position.z() / bs);
        if (lm->isSolidTile(curR, curC)) {
            return false;
        }
    }

    // Ray from enemy eye height to target eye height
    QVector3D eyeOrigin = m_position + QVector3D(0.0f, 110.0f, 0.0f);
    QVector3D targetEye = targetPos + QVector3D(0.0f, 110.0f, 0.0f);

    QVector3D delta = targetEye - eyeOrigin;
    float dist = delta.length();
    if (dist < 1.0f) return true;

    QVector3D dir = delta / dist;
    float outDist = 0.0f;
    QVector3D outHitPos;

    if (m_world->raycastDDA(eyeOrigin, dir, dist, outDist, outHitPos)) {
        // Raycast hit a solid collider before reaching target
        if (outDist < dist - 40.0f) {
            return false;
        }
    }

    return true;
}

// ==================== FACING ====================

void Enemy::faceTarget(const QVector3D &targetPos)
{
    float dx = targetPos.x() - m_position.x();
    float dz = targetPos.z() - m_position.z();
    float angleRad = qAtan2(dx, dz);
    float newRot = qRadiansToDegrees(angleRad);
    if (qAbs(m_rotationY - newRot) > 1.5f) {
        m_rotationY = newRot;
        emit rotationChanged(m_rotationY);
    }
}

// ==================== HIT DETECTION ====================

bool Enemy::intersectRayAABB(const QVector3D &origin, const QVector3D &dir,
                             const QVector3D &boxMin, const QVector3D &boxMax,
                             float &outDist) const
{
    float tmin = 0.0f;
    float tmax = 10000.0f;

    for (int i = 0; i < 3; ++i) {
        float o = (i == 0) ? origin.x() : ((i == 1) ? origin.y() : origin.z());
        float d = (i == 0) ? dir.x() : ((i == 1) ? dir.y() : dir.z());
        float bmin = (i == 0) ? boxMin.x() : ((i == 1) ? boxMin.y() : boxMin.z());
        float bmax = (i == 0) ? boxMax.x() : ((i == 1) ? boxMax.y() : boxMax.z());

        if (qAbs(d) < 1e-6f) {
            if (o < bmin || o > bmax) return false;
        } else {
            float ood = 1.0f / d;
            float t1 = (bmin - o) * ood;
            float t2 = (bmax - o) * ood;
            if (t1 > t2) std::swap(t1, t2);
            tmin = qMax(tmin, t1);
            tmax = qMin(tmax, t2);
            if (tmin > tmax) return false;
        }
    }

    outDist = tmin;
    return true;
}

bool Enemy::checkRaycastHit(const QVector3D &rayOrigin, const QVector3D &rayDir,
                            bool &outIsHeadshot, float &outDistance) const
{
    if (!m_isActive || isDead()) return false;

    // Head Hitbox AABB (Generously sized for head/visor/horns from Y: 120 to 200, width: 90)
    QVector3D headMin(m_position.x() - 45.0f, m_position.y() + 120.0f, m_position.z() - 45.0f);
    QVector3D headMax(m_position.x() + 45.0f, m_position.y() + 200.0f, m_position.z() + 45.0f);

    float headDist = 0.0f;
    if (intersectRayAABB(rayOrigin, rayDir, headMin, headMax, headDist)) {
        outIsHeadshot = true;
        outDistance = headDist;
        return true;
    }

    // Body Hitbox AABB (Fully encloses torso, limbs, claws, weapons, and all rotation angles from Y: -15 to 150, width: 150)
    QVector3D bodyMin(m_position.x() - 75.0f, m_position.y() - 15.0f, m_position.z() - 75.0f);
    QVector3D bodyMax(m_position.x() + 75.0f, m_position.y() + 150.0f, m_position.z() + 75.0f);

    float bodyDist = 0.0f;
    if (intersectRayAABB(rayOrigin, rayDir, bodyMin, bodyMax, bodyDist)) {
        outIsHeadshot = false;
        outDistance = bodyDist;
        return true;
    }

    return false;
}

// ==================== COMBAT ====================

void Enemy::takeDamage(int amount, bool isHeadshot)
{
    if (!m_isActive || isDead() || amount <= 0) return;

    qDebug() << "[Enemy]" << (m_type == EnemyType::Drone ? "Drone" : "Sentinel")
             << "took" << amount << (isHeadshot ? "HEADSHOT" : "BODY") << "damage!";
    m_healthSystem->takeDamage(amount);
}

void Enemy::reset()
{
    m_position = QVector3D(0.0f, 0.0f, 0.0f);
    m_rotationY = 0.0f;
    m_healthSystem->setMaxHealth(m_maxHp);
    m_healthSystem->reset();
    m_droneState = DroneState::Idle;
    m_sentinelState = SentinelState::Guard;
    m_attackTimer = 0.0f;
    m_pathfindTimer = 0.0f;
    m_aimTimer = 0.0f;
    m_searchTimer = 0.0f;
    m_isShooting = false;
    m_muzzleFlashTimer = 0.0f;
    m_bfsPath.clear();
    m_currentPathIndex = 0;
    m_isActive = false;

    emit positionChanged(m_position);
    emit rotationChanged(m_rotationY);
    emit stateChanged(state());
    emit isShootingChanged(false);
    emit activeChanged(false);
    emit visibleChanged();
}

void Enemy::respawn(const QVector3D &spawnPos)
{
    reset();
    m_position = spawnPos;
    m_isActive = true;

    emit positionChanged(m_position);
    emit activeChanged(true);
    emit visibleChanged();
    emit healthChanged(health());
    emit stateChanged(state());

    qDebug() << "[Enemy]" << (m_type == EnemyType::Drone ? "Drone" : "Sentinel")
             << "respawned at" << spawnPos << "HP:" << health();
}
