#include "PuzzleManager.h"
#include <QDebug>
#include <QtMath>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QCoreApplication>
#include <QRandomGenerator>
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
    , m_level1Variant(1)
    , m_activePuzzle(0)
    , m_targetPuzzleId(0)
    , m_currentRiddleCorrectIndex(0)
    , m_selectedRiddleOption(-1)
    , m_manifestAlpha(0)
    , m_manifestBeta(0)
    , m_manifestGamma(0)
    , m_fuseCollected(true)
    , m_fuseInserted(true)
    , m_clue1Found(false)
    , m_clue2Found(false)
    , m_clue3Found(false)
    , m_manifestClueFound(false)
    , m_activeClueIndex(1)
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
    Q_UNUSED(x);
    Q_UNUSED(z);
    return false;
}

int PuzzleManager::findTargetInteractable(const QVector3D &cameraPos, const QVector3D &lookDir, int currentLevel) const
{
    if (currentLevel != 1) {
        return PuzzleNone;
    }

    // Key 1 Vault Sphinx Riddle Terminal mounted on Vault Front Face at (755.0f, 115.0f, 2980.0f)
    QVector3D terminalPos(755.0f, 115.0f, 2980.0f);
    QVector3D toTerminal = terminalPos - cameraPos;
    float dist = toTerminal.length();
    if (dist <= 260.0f) {
        QVector3D normDir = lookDir.normalized();
        float dot = QVector3D::dotProduct(normDir, toTerminal.normalized());
        if (dot > 0.55f) {
            return PuzzleCrane;
        }
    }

    // Sector K4 Wall-Mounted Electrical Switchboard & Breaker Panel at (3650.0f, 135.0f, 615.0f)
    QVector3D wiringPos(3650.0f, 135.0f, 615.0f);
    QVector3D toWiring = wiringPos - cameraPos;
    float distWiring = toWiring.length();
    if (distWiring <= 260.0f) {
        QVector3D normDir = lookDir.normalized();
        float dot = QVector3D::dotProduct(normDir, toWiring.normalized());
        if (dot > 0.45f) {
            return PuzzlePower;
        }
    }

    return PuzzleNone;
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
            m_interactionPrompt = m_craneSolved ? QStringLiteral("[E] VAULT TERMINAL [UNLOCKED]")
                                                : QStringLiteral("[E] ACCESS VAULT TERMINAL");
            break;
        case PuzzlePower:
            m_interactionPrompt = m_powerSolved ? QStringLiteral("[E] ELECTRICAL SWITCHBOARD [REPAIRED]")
                                                : QStringLiteral("[E] ACCESS ELECTRICAL SWITCHBOARD");
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

    // Fast pickups or special handling
    if (m_targetPuzzleId == PuzzleResearchFuse) {
        collectFuse();
        return false;
    }

    if (m_targetPuzzleId == PuzzleAdminClue) {
        inspectClue(1);
        m_activePuzzle = PuzzleAdminClue;
        emit activePuzzleChanged();
        return true;
    }

    if (m_targetPuzzleId == PuzzleAdminClue2) {
        inspectClue(2);
        m_activePuzzle = PuzzleAdminClue;
        emit activePuzzleChanged();
        return true;
    }

    if (m_targetPuzzleId == PuzzleAdminClue3) {
        inspectClue(3);
        m_activePuzzle = PuzzleAdminClue;
        emit activePuzzleChanged();
        return true;
    }

    if (m_targetPuzzleId == PuzzleManifestClue) {
        inspectClue(4);
        m_activePuzzle = PuzzleAdminClue;
        emit activePuzzleChanged();
        return true;
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

// ==================== RIDDLE & CARGO PUZZLE IMPLEMENTATION (Puzzle 1) ====================

void PuzzleManager::loadRiddles()
{
    m_riddles.clear();

    QStringList searchPaths = {
        QDir::current().filePath(QStringLiteral("vanguard_riddles.csv")),
        QCoreApplication::applicationDirPath() + QStringLiteral("/vanguard_riddles.csv"),
        QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../vanguard_riddles.csv")),
        QDir::current().filePath(QStringLiteral("../vanguard_riddles.csv"))
    };

    QFile file;
    for (const QString &path : searchPaths) {
        if (QFile::exists(path)) {
            file.setFileName(path);
            if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                qDebug() << "[PuzzleManager] Loaded riddles from:" << path;
                break;
            }
        }
    }

    if (file.isOpen()) {
        QTextStream in(&file);
        bool headerSkipped = false;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.isEmpty()) continue;
            if (!headerSkipped) {
                headerSkipped = true;
                continue;
            }
            QStringList tokens;
            bool inQuotes = false;
            QString currentToken;
            for (int i = 0; i < line.length(); ++i) {
                QChar c = line[i];
                if (c == QLatin1Char('"')) {
                    inQuotes = !inQuotes;
                } else if (c == QLatin1Char(',') && !inQuotes) {
                    tokens.append(currentToken.trimmed());
                    currentToken.clear();
                } else {
                    currentToken.append(c);
                }
            }
            tokens.append(currentToken.trimmed());

            if (tokens.size() >= 3) {
                RiddleEntry entry;
                entry.id = tokens[0].toInt();
                entry.riddle = tokens[1];
                entry.answer = tokens[2];
                m_riddles.append(entry);
            }
        }
        file.close();
    }

    if (m_riddles.isEmpty()) {
        m_riddles = {
            { 1, QStringLiteral("I have keys but open no locks. I have space but no room. You can enter, but cannot go inside. What am I?"), QStringLiteral("Keyboard") },
            { 2, QStringLiteral("The more you take from me, the bigger I become. What am I?"), QStringLiteral("A hole") },
            { 3, QStringLiteral("I speak without a mouth and hear without ears. I have no body, but come alive with sound. What am I?"), QStringLiteral("Echo") },
            { 4, QStringLiteral("I have hands but cannot clap. I have a face but cannot smile. What am I?"), QStringLiteral("Clock") },
            { 5, QStringLiteral("I get wetter the more I dry. What am I?"), QStringLiteral("Towel") },
            { 6, QStringLiteral("What has many teeth but cannot bite?"), QStringLiteral("Comb") },
            { 7, QStringLiteral("What can travel around the world while staying in one corner?"), QStringLiteral("Stamp") },
            { 8, QStringLiteral("I have cities but no houses, forests but no trees, and rivers but no water. What am I?"), QStringLiteral("Map") },
            { 9, QStringLiteral("What belongs to you but other people use it more than you do?"), QStringLiteral("Your name") },
            { 10, QStringLiteral("The more there is of me, the less you can see. What am I?"), QStringLiteral("Darkness") }
        };
    }
}

void PuzzleManager::pickRandomRiddle()
{
    if (m_riddles.isEmpty()) {
        loadRiddles();
    }
    if (m_riddles.isEmpty()) return;

    int rIdx = QRandomGenerator::global()->bounded(static_cast<int>(m_riddles.size()));
    const RiddleEntry &chosen = m_riddles[rIdx];
    m_currentRiddleText = chosen.riddle;

    QStringList otherAnswers;
    for (int i = 0; i < m_riddles.size(); ++i) {
        if (i != rIdx) {
            otherAnswers.append(m_riddles[i].answer);
        }
    }
    for (int i = otherAnswers.size() - 1; i > 0; --i) {
        int j = QRandomGenerator::global()->bounded(i + 1);
        otherAnswers.swapItemsAt(i, j);
    }

    QStringList options;
    options.append(chosen.answer);
    for (int i = 0; i < 3 && i < otherAnswers.size(); ++i) {
        options.append(otherAnswers[i]);
    }

    for (int i = options.size() - 1; i > 0; --i) {
        int j = QRandomGenerator::global()->bounded(i + 1);
        options.swapItemsAt(i, j);
    }

    m_currentRiddleOptions = options;
    m_currentRiddleCorrectIndex = options.indexOf(chosen.answer);
    m_selectedRiddleOption = -1;
    m_riddleFeedback.clear();

    qDebug() << "[PuzzleManager] Picked riddle #" << chosen.id << ":" << chosen.riddle
             << "Answer:" << chosen.answer << "Correct Index:" << m_currentRiddleCorrectIndex;

    emit riddleStateChanged();
}

void PuzzleManager::selectRiddleOption(int index)
{
    m_selectedRiddleOption = index;
    m_riddleFeedback.clear();
    emit riddleStateChanged();
}

bool PuzzleManager::solveRiddle(int optionIndex)
{
    if (optionIndex < 0 || optionIndex >= m_currentRiddleOptions.size()) {
        m_riddleFeedback = QStringLiteral("ERROR: SELECT A RESPONSE BEFORE SUBMITTING.");
        emit riddleStateChanged();
        return false;
    }

    if (optionIndex == m_currentRiddleCorrectIndex) {
        m_craneSolved = true;
        m_riddleFeedback = QStringLiteral("ACCESS GRANTED: IDENTITY CONFIRMED. DISENGAGING VAULT DOOR...");
        emit craneSolvedChanged();
        emit riddleSolvedChanged();
        emit riddleStateChanged();
        emit puzzleCompleted(PuzzleCrane, QStringLiteral("Vault Security Riddle"));
        emit puzzleFeedback(QStringLiteral("VAULT ACCESS GRANTED: Vault Door Disengaged!"), QStringLiteral("#2ecc71"));
        return true;
    }

    m_riddleFeedback = QStringLiteral("ACCESS DENIED: INCORRECT RESPONSE. RE-EVALUATE COGNITIVE QUERY.");
    emit riddleStateChanged();
    emit puzzleFeedback(QStringLiteral("ACCESS DENIED — INCORRECT RESPONSE"), QStringLiteral("#e74c3c"));
    return false;
}

bool PuzzleManager::submitRiddleAnswer()
{
    return solveRiddle(m_selectedRiddleOption);
}

void PuzzleManager::assignManifest(int containerId, int bayId)
{
    if (containerId == 1) m_manifestAlpha = bayId;
    else if (containerId == 2) m_manifestBeta = bayId;
    else if (containerId == 3) m_manifestGamma = bayId;
    m_manifestFeedback.clear();
    emit manifestChanged();
}

bool PuzzleManager::verifyCargoManifest()
{
    // Solution derived from Shipping Manifest #804-V in Warehouse Office:
    // Container Alpha (1, #A-101) -> Bay 3 (Heavy Fab)
    // Container Beta  (2, #B-204) -> Bay 1 (Staging Bay)
    // Container Gamma (3, #G-309) -> Bay 5 (Cryogenic Storage)
    if (m_manifestAlpha == 3 && m_manifestBeta == 1 && m_manifestGamma == 5) {
        m_craneSolved = true;
        m_bays[3] = 1;
        m_bays[1] = 2;
        m_bays[5] = 3;
        m_manifestFeedback = QStringLiteral("MANIFEST VERIFIED: Container routing approved. K1 chamber barrier disengaged.");
        emit craneSolvedChanged();
        emit craneStateChanged();
        emit manifestChanged();
        emit puzzleStateChanged();
        emit puzzleCompleted(PuzzleCrane, QStringLiteral("CARGO MANIFEST VERIFICATION"));
        emit barrierOpened(1);
        emit puzzleFeedback(QStringLiteral("CARGO MANIFEST ROUTED — ACCESS KEY B UNLOCKED"), QStringLiteral("#2ecc71"));
        return true;
    }

    m_manifestFeedback = QStringLiteral("MANIFEST ERROR: Destination discrepancy detected. Re-check warehouse shipping logs and re-route containers.");
    emit manifestChanged();
    return false;
}

void PuzzleManager::resetManifest()
{
    m_manifestAlpha = 0;
    m_manifestBeta = 0;
    m_manifestGamma = 0;
    m_manifestFeedback.clear();
    emit manifestChanged();
}

bool PuzzleManager::verifyManifestDirect(int alphaBay, int betaBay, int gammaBay)
{
    m_manifestAlpha = alphaBay;
    m_manifestBeta = betaBay;
    m_manifestGamma = gammaBay;
    return verifyCargoManifest();
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
                m_manifestAlpha = 3;
                m_manifestBeta = 1;
                m_manifestGamma = 5;
                m_manifestFeedback = QStringLiteral("MANIFEST VERIFIED: Container routing approved. K1 chamber barrier disengaged.");
                emit craneSolvedChanged();
                emit manifestChanged();
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

void PuzzleManager::collectFuse()
{
    if (!m_fuseCollected) {
        m_fuseCollected = true;
        emit fuseChanged();
        emit puzzleFeedback(QStringLiteral("COLLECTED 200A BUS FUSE FROM ELECTRICAL CONTROL ROOM"), QStringLiteral("#00e5ff"));
    }
}

bool PuzzleManager::insertFuse()
{
    if (m_fuseCollected && !m_fuseInserted) {
        m_fuseInserted = true;
        emit fuseChanged();
        updateCircuitPowerFlow();
        emit circuitStateChanged();
        emit puzzleFeedback(QStringLiteral("200A FUSE INSTALLED INTO POWER BUS COUPLER"), QStringLiteral("#2ecc71"));

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
    return false;
}

bool PuzzleManager::rotateCircuitTile(int tileIndex)
{
    if (tileIndex < 0 || tileIndex >= 9) return false;

    m_circuitRotations[tileIndex] = (m_circuitRotations[tileIndex] + 90) % 360;
    updateCircuitPowerFlow();
    emit circuitStateChanged();

    // Check if power successfully energized Tile 8 and Tile 8 conducts out to EAST
    if (m_circuitEnergized[8] && !m_powerSolved && m_fuseInserted) {
        int mask8 = rotateConnectionMask(BASE_CONNECTIONS[8], m_circuitRotations[8]);
        if (mask8 & DIR_E) {
            m_powerSolved = true;
            emit powerSolvedChanged();
            emit puzzleStateChanged();
            emit puzzleCompleted(PuzzlePower, QStringLiteral("ELECTRICAL WIRING REPAIRED"));
            emit barrierOpened(2);
            emit puzzleFeedback(QStringLiteral("ELECTRICAL WIRING RESTORED — BULKHEAD CARD READER ONLINE!"), QStringLiteral("#2ecc71"));
        }
    }

    return true;
}

void PuzzleManager::updateCircuitPowerFlow()
{
    for (int i = 0; i < 9; ++i) {
        m_circuitEnergized[i] = false;
    }

    // Power requires both the fuse to be inserted and Tile 0 to face West
    if (!m_fuseInserted) {
        return;
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

bool PuzzleManager::solveWiring()
{
    if (!m_powerSolved) {
        m_powerSolved = true;
        emit powerSolvedChanged();
        emit puzzleStateChanged();
        emit puzzleCompleted(PuzzlePower, QStringLiteral("ELECTRICAL WIRING RESTORED"));
        emit barrierOpened(2);
        emit puzzleFeedback(QStringLiteral("ELECTRICAL WIRING RESTORED — BULKHEAD CARD READER ONLINE!"), QStringLiteral("#2ecc71"));
        return true;
    }
    return true;
}

void PuzzleManager::setPowerSolved(bool solved)
{
    if (m_powerSolved != solved) {
        m_powerSolved = solved;
        emit powerSolvedChanged();
        emit puzzleStateChanged();
        if (solved) {
            emit puzzleCompleted(PuzzlePower, QStringLiteral("ELECTRICAL WIRING RESTORED"));
            emit barrierOpened(2);
            emit puzzleFeedback(QStringLiteral("ELECTRICAL WIRING RESTORED — BULKHEAD CARD READER ONLINE!"), QStringLiteral("#2ecc71"));
        }
    }
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

// ==================== ADMINISTRATION INVESTIGATION CLUES ====================

void PuzzleManager::inspectClue(int clueIndex)
{
    m_activeClueIndex = clueIndex;
    if (clueIndex == 1) m_clue1Found = true;
    else if (clueIndex == 2) m_clue2Found = true;
    else if (clueIndex == 3) m_clue3Found = true;
    else if (clueIndex == 4) m_manifestClueFound = true;
    emit cluesChanged();
    emit activeClueChanged();
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

    m_selectedRiddleOption = -1;
    m_riddleFeedback.clear();
    pickRandomRiddle();
    resetManifest();
    resetCrane();
    m_fuseCollected = false;
    m_fuseInserted = false;
    m_clue1Found = false;
    m_clue2Found = false;
    m_clue3Found = false;
    m_manifestClueFound = false;
    m_activeClueIndex = 1;
    resetCircuit();
    clearSecurityCode();
    resetCoolant();

    emit craneSolvedChanged();
    emit riddleSolvedChanged();
    emit riddleStateChanged();
    emit powerSolvedChanged();
    emit securitySolvedChanged();
    emit coolantSolvedChanged();
    emit puzzleStateChanged();
    emit activePuzzleChanged();
    emit targetPuzzleIdChanged();
    emit interactionPromptChanged();
    emit manifestChanged();
    emit fuseChanged();
    emit cluesChanged();
    emit activeClueChanged();
}
