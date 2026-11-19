#include "PuzzleManager.h"
#include <QDebug>
#include <QtMath>
#include <queue>

namespace {
// Tile connection direction masks
constexpr int DIR_N = 1 << 0; // 1
constexpr int DIR_E = 1 << 1; // 2
constexpr int DIR_S = 1 << 2; // 4
constexpr int DIR_W = 1 << 3; // 8

// Base connections for circuit tile types at 0 degrees rotation
// 0=Corner (N|E), 1=Straight (W|E), 2=Corner (N|E),
// 3=Straight (W|E), 4=T-Junction (W|N|E), 5=Corner (N|E),
// 6=Corner (N|E), 7=Straight (W|E), 8=Straight (W|E)
constexpr int BASE_CONNECTIONS[9] = {
    DIR_N | DIR_E,          // Tile 0: Corner
    DIR_W | DIR_E,          // Tile 1: Straight
    DIR_N | DIR_E,          // Tile 2: Corner
    DIR_W | DIR_E,          // Tile 3: Straight
    DIR_W | DIR_N | DIR_E,  // Tile 4: T-Junction
    DIR_N | DIR_E,          // Tile 5: Corner
    DIR_N | DIR_E,          // Tile 6: Corner
    DIR_W | DIR_E,          // Tile 7: Straight
    DIR_W | DIR_E           // Tile 8: Straight
};

int rotateConnectionMask(int mask, int degrees)
{
    int steps = ((degrees % 360) + 360) % 360 / 90;
    int current = mask & 0x0F;
    for (int s = 0; s < steps; ++s) {
        int next = 0;
        if (current & DIR_N) next |= DIR_E;
        if (current & DIR_E) next |= DIR_S;
        if (current & DIR_S) next |= DIR_W;
        if (current & DIR_W) next |= DIR_N;
        current = next;
    }
    return current;
}
} // namespace

PuzzleManager::PuzzleManager(QObject *parent)
    : QObject(parent)
    , m_craneSolved(false)
    , m_powerSolved(false)
    , m_securitySolved(false)
    , m_coolantSolved(false)
    , m_activePuzzle(0)
    , m_targetPuzzleId(0)
    , m_craneGrabbed(0)
    , m_craneSelectedBay(0)
    , m_securityErrorFlash(false)
    , m_valve1(0)
    , m_valve2(0)
    , m_valve3(0)
    , m_systemFlow(20.0f)
    , m_corePressure(180.0f)
{
    resetAllPuzzles();
}

int PuzzleManager::solvedCount() const
{
    int count = 0;
    if (m_craneSolved) ++count;
    if (m_powerSolved) ++count;
    if (m_securitySolved) ++count;
    if (m_coolantSolved) ++count;
    return count;
}

QVariantList PuzzleManager::craneBays() const
{
    QVariantList list;
    for (int i = 0; i < 6; ++i) {
        list.append(m_bays[i]);
    }
    return list;
}

int PuzzleManager::craneMatchedCount() const
{
    int matched = 0;
    if (m_bays[3] == 1) ++matched;
    if (m_bays[1] == 2) ++matched;
    if (m_bays[5] == 3) ++matched;
    return matched;
}

QVariantList PuzzleManager::circuitRotations() const
{
    QVariantList list;
    for (int i = 0; i < 9; ++i) {
        list.append(m_circuitRotations[i]);
    }
    return list;
}

QVariantList PuzzleManager::circuitEnergized() const
{
    QVariantList list;
    for (int i = 0; i < 9; ++i) {
        list.append(m_circuitEnergized[i]);
    }
    return list;
}

bool PuzzleManager::isFlowInRange() const
{
    return m_systemFlow >= 70.0f && m_systemFlow <= 80.0f;
}

bool PuzzleManager::isPressureInRange() const
{
    return m_corePressure >= 95.0f && m_corePressure <= 105.0f;
}

bool PuzzleManager::isBarrierBlocking(int barrierId) const
{
    switch (barrierId) {
    case 1: return !m_craneSolved;    // Cargo barrier
    case 2: return !m_powerSolved;    // Research barrier
    case 3: return !m_securitySolved; // Admin barrier
    case 4: return !m_coolantSolved;  // Maintenance barrier
    default: return false;
    }
}

bool PuzzleManager::isPositionBlockedByBarrier(float x, float z) const
{
    // Barrier 1: Cargo Containers blocking K1 chamber (rows 6..7, col 9)
    if (isBarrierBlocking(1)) {
        if (x >= 880.0f && x <= 1020.0f && z >= 580.0f && z <= 820.0f) {
            return true;
        }
    }

    // Barrier 2: Research Containment Field blocking K2 chamber (row 10, cols 64..65)
    if (isBarrierBlocking(2)) {
        if (x >= 6380.0f && x <= 6620.0f && z >= 960.0f && z <= 1140.0f) {
            return true;
        }
    }

    // Barrier 3: Admin Security Laser Gate blocking K3 vault (row 70, cols 12..13)
    if (isBarrierBlocking(3)) {
        if (x >= 1180.0f && x <= 1420.0f && z >= 6960.0f && z <= 7140.0f) {
            return true;
        }
    }

    // Barrier 4: Maintenance Substation Interlock Gate blocking K0 alcove (row 72, col 68)
    if (isBarrierBlocking(4)) {
        if (x >= 6760.0f && x <= 6940.0f && z >= 7160.0f && z <= 7340.0f) {
            return true;
        }
    }

    return false;
}

int PuzzleManager::findTargetInteractable(const QVector3D &cameraPos, const QVector3D &lookDir, int currentLevel) const
{
    if (currentLevel != 1) {
        return PuzzleNone;
    }

    // Positions of the 5 interactive entities in Level 1:
    struct TargetDef {
        int id;
        QVector3D pos;
        float radius;
    };

    const TargetDef targets[] = {
        { PuzzleCrane,      QVector3D(850.0f,  0.0f,  950.0f), 180.0f }, // Crane Console
        { PuzzlePower,      QVector3D(6250.0f, 0.0f, 1050.0f), 180.0f }, // Power Routing Terminal
        { PuzzleSecurity,   QVector3D(1550.0f, 0.0f, 7050.0f), 180.0f }, // Security Keypad
        { PuzzleAdminClue,  QVector3D(850.0f,  0.0f, 6450.0f), 180.0f }, // Supervisor Directive Desk
        { PuzzleCoolant,    QVector3D(6250.0f, 0.0f, 6650.0f), 180.0f }  // Coolant Valve Manifold
    };

    QVector3D normDir = lookDir.normalized();
    float bestDot = 0.65f; // Must look within ~50 degrees
    int bestId = PuzzleNone;
    float bestDist = 250.0f; // Max interaction distance

    for (const auto &t : targets) {
        QVector3D toTarget = t.pos - cameraPos;
        toTarget.setY(0.0f); // Horizontal plane raycast
        float dist = toTarget.length();
        if (dist > t.radius && dist > bestDist) continue;

        QVector3D dirToTarget = toTarget.normalized();
        float dot = QVector3D::dotProduct(normDir, dirToTarget);
        if (dot > bestDot) {
            bestDot = dot;
            bestId = t.id;
        }
    }

    return bestId;
}

void PuzzleManager::updateInteraction(float deltaTime,
                                      const QVector3D &cameraPos,
                                      const QVector3D &lookDir,
                                      int currentLevel,
                                      bool playerAlive)
{
    Q_UNUSED(deltaTime);

    if (!playerAlive || currentLevel != 1) {
        if (m_targetPuzzleId != PuzzleNone) {
            m_targetPuzzleId = PuzzleNone;
            m_interactionPrompt.clear();
            emit targetPuzzleIdChanged();
            emit interactionPromptChanged();
        }
        return;
    }

    // Don't change target while actively in a puzzle UI
    if (m_activePuzzle != PuzzleNone) {
        return;
    }

    int target = findTargetInteractable(cameraPos, lookDir, currentLevel);
    if (m_targetPuzzleId != target) {
        m_targetPuzzleId = target;
        emit targetPuzzleIdChanged();

        switch (m_targetPuzzleId) {
        case PuzzleCrane:
            m_interactionPrompt = m_craneSolved ? QStringLiteral("[E] CRANE CONTROLS [ALIGNED]")
                                                : QStringLiteral("[E] OPERATE CRANE CONSOLE");
            break;
        case PuzzlePower:
            m_interactionPrompt = m_powerSolved ? QStringLiteral("[E] POWER ROUTING [ONLINE]")
                                                : QStringLiteral("[E] ACCESS POWER ROUTING TERMINAL");
            break;
        case PuzzleSecurity:
            m_interactionPrompt = m_securitySolved ? QStringLiteral("[E] SECURITY TERMINAL [UNLOCKED]")
                                                   : QStringLiteral("[E] ENTER VAULT PASSCODE");
            break;
        case PuzzleAdminClue:
            m_interactionPrompt = QStringLiteral("[E] READ SUPERVISOR DIRECTIVE MEMO");
            break;
        case PuzzleCoolant:
            m_interactionPrompt = m_coolantSolved ? QStringLiteral("[E] COOLANT MANIFOLD [STABILIZED]")
                                                  : QStringLiteral("[E] REGULATE COOLANT VALVES");
            break;
        default:
            m_interactionPrompt.clear();
            break;
        }
        emit interactionPromptChanged();
    }
}

bool PuzzleManager::interact(const QVector3D &playerPos, int currentLevel, bool playerAlive)
{
    Q_UNUSED(playerPos);
    if (!playerAlive || currentLevel != 1 || m_targetPuzzleId == PuzzleNone) {
        return false;
    }

    m_activePuzzle = m_targetPuzzleId;
    emit activePuzzleChanged();
    return true;
}

void PuzzleManager::closeActivePuzzle()
{
    if (m_activePuzzle != PuzzleNone) {
        m_activePuzzle = PuzzleNone;
        emit activePuzzleChanged();
    }
}

// ==================== CRANE PUZZLE IMPLEMENTATION ====================

bool PuzzleManager::selectCraneBay(int bayIndex)
{
    if (bayIndex < 0 || bayIndex >= 6) return false;
    m_craneSelectedBay = bayIndex;
    emit craneStateChanged();
    return true;
}

bool PuzzleManager::grabOrReleaseCrane()
{
    if (m_craneSelectedBay < 0 || m_craneSelectedBay >= 6) return false;

    if (m_craneGrabbed == 0) {
        // Grab from selected bay if not empty
        if (m_bays[m_craneSelectedBay] != 0) {
            m_craneGrabbed = m_bays[m_craneSelectedBay];
            m_bays[m_craneSelectedBay] = 0;
            emit craneStateChanged();
            return true;
        }
        return false;
    } else {
        // Release into selected bay if currently empty
        if (m_bays[m_craneSelectedBay] == 0) {
            m_bays[m_craneSelectedBay] = m_craneGrabbed;
            m_craneGrabbed = 0;
            emit craneStateChanged();

            // Check if all 3 containers match their targets:
            // Container 1 (Alpha) in Bay 3
            // Container 2 (Beta) in Bay 1
            // Container 3 (Gamma) in Bay 5
            if (m_bays[3] == 1 && m_bays[1] == 2 && m_bays[5] == 3 && !m_craneSolved) {
                m_craneSolved = true;
                emit craneSolvedChanged();
                emit puzzleStateChanged();
                emit puzzleCompleted(PuzzleCrane, QStringLiteral("CARGO CRANE ALIGNMENT"));
                emit barrierOpened(1);
                emit puzzleFeedback(QStringLiteral("CARGO CONTAINERS REPOSITIONED — ACCESS KEY B UNLOCKED"), QStringLiteral("#2ecc71"));
            }
            return true;
        }
        return false;
    }
}

void PuzzleManager::resetCrane()
{
    // Initial bays:
    // Bay 0: Container Alpha (1)
    // Bay 2: Container Beta (2)
    // Bay 4: Container Gamma (3)
    // Bays 1, 3, 5: Empty (0)
    m_bays[0] = 1;
    m_bays[1] = 0;
    m_bays[2] = 2;
    m_bays[3] = 0;
    m_bays[4] = 3;
    m_bays[5] = 0;
    m_craneGrabbed = 0;
    m_craneSelectedBay = 0;
    emit craneStateChanged();
}

// ==================== POWER ROUTING CIRCUIT IMPLEMENTATION ====================

bool PuzzleManager::rotateCircuitTile(int tileIndex)
{
    if (tileIndex < 0 || tileIndex >= 9) return false;

    m_circuitRotations[tileIndex] = (m_circuitRotations[tileIndex] + 90) % 360;
    updateCircuitPowerFlow();
    emit circuitStateChanged();

    // Check if power successfully energized Tile 8 and Tile 8 conducts out to EAST
    if (m_circuitEnergized[8] && !m_powerSolved) {
        int mask8 = rotateConnectionMask(BASE_CONNECTIONS[8], m_circuitRotations[8]);
        if (mask8 & DIR_E) {
            m_powerSolved = true;
            emit powerSolvedChanged();
            emit puzzleStateChanged();
            emit puzzleCompleted(PuzzlePower, QStringLiteral("RESEARCH POWER ROUTING"));
            emit barrierOpened(2);
            emit puzzleFeedback(QStringLiteral("CONTAINMENT FIELD DISENGAGED — ACCESS KEY C UNLOCKED"), QStringLiteral("#00e5ff"));
        }
    }

    return true;
}

void PuzzleManager::updateCircuitPowerFlow()
{
    for (int i = 0; i < 9; ++i) {
        m_circuitEnergized[i] = false;
    }

    // Tile 0 must have DIR_W to accept power from West source
    int mask0 = rotateConnectionMask(BASE_CONNECTIONS[0], m_circuitRotations[0]);
    if (!(mask0 & DIR_W)) {
        return;
    }

    // BFS trace energized wires
    std::queue<int> q;
    m_circuitEnergized[0] = true;
    q.push(0);

    const int dr[4] = {-1, 0, 1, 0};
    const int dc[4] = {0, 1, 0, -1};
    const int outDir[4] = {DIR_N, DIR_E, DIR_S, DIR_W};
    const int inDir[4]  = {DIR_S, DIR_W, DIR_N, DIR_E};

    while (!q.empty()) {
        int curr = q.front();
        q.pop();

        int r = curr / 3;
        int c = curr % 3;
        int currMask = rotateConnectionMask(BASE_CONNECTIONS[curr], m_circuitRotations[curr]);

        for (int i = 0; i < 4; ++i) {
            if (!(currMask & outDir[i])) continue;

            int nr = r + dr[i];
            int nc = c + dc[i];
            if (nr < 0 || nr >= 3 || nc < 0 || nc >= 3) continue;

            int nextIdx = nr * 3 + nc;
            int nextMask = rotateConnectionMask(BASE_CONNECTIONS[nextIdx], m_circuitRotations[nextIdx]);

            if ((nextMask & inDir[i]) && !m_circuitEnergized[nextIdx]) {
                m_circuitEnergized[nextIdx] = true;
                q.push(nextIdx);
            }
        }
    }
}

void PuzzleManager::resetCircuit()
{
    // Initial scrambled rotations
    m_circuitRotations[0] = 90;
    m_circuitRotations[1] = 90;
    m_circuitRotations[2] = 180;
    m_circuitRotations[3] = 0;
    m_circuitRotations[4] = 90;
    m_circuitRotations[5] = 270;
    m_circuitRotations[6] = 180;
    m_circuitRotations[7] = 90;
    m_circuitRotations[8] = 90;

    updateCircuitPowerFlow();
    emit circuitStateChanged();
}

// ==================== SECURITY KEYPAD IMPLEMENTATION ====================

void PuzzleManager::enterSecurityDigit(const QString &digit)
{
    if (m_securityEnteredCode.length() < 4) {
        m_securityEnteredCode.append(digit);
        m_securityStatusMessage.clear();
        m_securityErrorFlash = false;
        emit securityStateChanged();
    }
}

void PuzzleManager::clearSecurityCode()
{
    m_securityEnteredCode.clear();
    m_securityStatusMessage.clear();
    m_securityErrorFlash = false;
    emit securityStateChanged();
}

bool PuzzleManager::submitSecurityCode()
{
    if (m_securityEnteredCode.length() != 4) {
        m_securityStatusMessage = QStringLiteral("CODE MUST BE 4 DIGITS");
        m_securityErrorFlash = true;
        emit securityStateChanged();
        return false;
    }

    // Code is 5824 (derived from Directive Memo: Facility Sector 58, Vault Bay 24)
    if (m_securityEnteredCode == QStringLiteral("5824")) {
        m_securitySolved = true;
        m_securityStatusMessage = QStringLiteral("ACCESS GRANTED — VAULT OPEN");
        m_securityErrorFlash = false;
        emit securitySolvedChanged();
        emit puzzleStateChanged();
        emit securityStateChanged();
        emit puzzleCompleted(PuzzleSecurity, QStringLiteral("ADMIN RECORDS VAULT OVERRIDE"));
        emit barrierOpened(3);
        emit puzzleFeedback(QStringLiteral("SECURITY VAULT GATE DISENGAGED — ACCESS KEY D UNLOCKED"), QStringLiteral("#2ecc71"));
        return true;
    } else {
        m_securityStatusMessage = QStringLiteral("ACCESS DENIED — INVALID PASSCODE");
        m_securityErrorFlash = true;
        emit securityStateChanged();
        return false;
    }
}

// ==================== COOLANT REGULATION IMPLEMENTATION ====================

void PuzzleManager::setValve(int valveIndex, int setting)
{
    int s = qBound(0, setting, 3);
    if (valveIndex == 1) m_valve1 = s;
    else if (valveIndex == 2) m_valve2 = s;
    else if (valveIndex == 3) m_valve3 = s;

    updateCoolantMetrics();
    emit coolantStateChanged();

    if (isFlowInRange() && isPressureInRange() && !m_coolantSolved) {
        m_coolantSolved = true;
        emit coolantSolvedChanged();
        emit puzzleStateChanged();
        emit puzzleCompleted(PuzzleCoolant, QStringLiteral("COOLANT SYSTEM REGULATION"));
        emit barrierOpened(4);
        emit puzzleFeedback(QStringLiteral("COOLANT MANIFOLD STABILIZED — ACCESS KEY A UNLOCKED"), QStringLiteral("#2ecc71"));
    }
}

void PuzzleManager::cycleValve(int valveIndex)
{
    if (valveIndex == 1) m_valve1 = (m_valve1 + 1) % 4;
    else if (valveIndex == 2) m_valve2 = (m_valve2 + 1) % 4;
    else if (valveIndex == 3) m_valve3 = (m_valve3 + 1) % 4;

    updateCoolantMetrics();
    emit coolantStateChanged();

    // Check if both flow and pressure are in green range:
    // Flow nominal 75 (70..80) and Pressure nominal 100 (95..105)
    // Solution: V1=2, V2=1, V3=2
    if (isFlowInRange() && isPressureInRange() && !m_coolantSolved) {
        m_coolantSolved = true;
        emit coolantSolvedChanged();
        emit puzzleStateChanged();
        emit puzzleCompleted(PuzzleCoolant, QStringLiteral("COOLANT SYSTEM REGULATION"));
        emit barrierOpened(4);
        emit puzzleFeedback(QStringLiteral("BACKUP GENERATOR SYNCHRONIZED — ACCESS KEY A UNLOCKED"), QStringLiteral("#f1c40f"));
    }
}

void PuzzleManager::updateCoolantMetrics()
{
    // Linear simulation:
    // Flow: base 20.0, V1 adds 20.0, V2 adds 25.0, V3 subtracts 5.0
    // Pressure: base 180.0, V1 relieves -15.0, V2 adds 10.0, V3 relieves -30.0
    m_systemFlow = 20.0f + 20.0f * m_valve1 + 25.0f * m_valve2 - 5.0f * m_valve3;
    m_corePressure = 180.0f - 15.0f * m_valve1 + 10.0f * m_valve2 - 30.0f * m_valve3;
}

void PuzzleManager::resetCoolant()
{
    m_valve1 = 0;
    m_valve2 = 0;
    m_valve3 = 0;
    updateCoolantMetrics();
    emit coolantStateChanged();
}

// ==================== RESET ALL PUZZLES ====================

void PuzzleManager::resetAllPuzzles()
{
    m_craneSolved = false;
    m_powerSolved = false;
    m_securitySolved = false;
    m_coolantSolved = false;
    m_activePuzzle = 0;
    m_targetPuzzleId = 0;
    m_interactionPrompt.clear();

    resetCrane();
    resetCircuit();
    clearSecurityCode();
    resetCoolant();

    emit craneSolvedChanged();
    emit powerSolvedChanged();
    emit securitySolvedChanged();
    emit coolantSolvedChanged();
    emit puzzleStateChanged();
    emit activePuzzleChanged();
    emit targetPuzzleIdChanged();
    emit interactionPromptChanged();
}
