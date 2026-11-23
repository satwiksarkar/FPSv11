#ifndef PUZZLEMANAGER_H
#define PUZZLEMANAGER_H

#include <QObject>
#include <QString>
#include <QVector3D>
#include <QVariantList>
#include <QSet>
#include <QtQml/qqmlregistration.h>

/**
 * @brief The PuzzleManager class coordinates the four interactive environmental
 * puzzles on Level 1 of Project VANGUARD:
 * 1. Cargo Warehouse — Crane Control Puzzle
 * 2. Research Laboratories — Power Routing Puzzle
 * 3. Administration Block — Security Code Puzzle (plus Clue reader)
 * 4. Maintenance & Utilities — Coolant Regulation Puzzle
 *
 * Guarantees:
 * - Deterministic, non-random solutions.
 * - Puzzles are independent and completable in any order.
 * - Each puzzle unlocks exclusively its corresponding access key chamber.
 * - Resets cleanly on Level 1 restart.
 * - Completely inactive on Level 2 and Level 3 (preserving those levels 100%).
 */
class PuzzleManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // High-level puzzle completion states
    Q_PROPERTY(bool craneSolved READ isCraneSolved NOTIFY craneSolvedChanged)
    Q_PROPERTY(bool riddleSolved READ isRiddleSolved NOTIFY riddleSolvedChanged)
    Q_PROPERTY(bool powerSolved READ isPowerSolved NOTIFY powerSolvedChanged)
    Q_PROPERTY(bool securitySolved READ isSecuritySolved NOTIFY securitySolvedChanged)
    Q_PROPERTY(bool coolantSolved READ isCoolantSolved NOTIFY coolantSolvedChanged)
    Q_PROPERTY(int solvedCount READ solvedCount NOTIFY puzzleStateChanged)

    // Riddle puzzle properties (Puzzle 1: Warehouse Riddle Terminal)
    Q_PROPERTY(int selectedRiddleOption READ selectedRiddleOption NOTIFY riddleStateChanged)
    Q_PROPERTY(QString riddleFeedback READ riddleFeedback NOTIFY riddleStateChanged)

    // Active UI state
    Q_PROPERTY(int activePuzzle READ activePuzzle NOTIFY activePuzzleChanged) // 0=None, 1=Crane, 2=Power, 3=Security, 4=Coolant, 5=AdminClue
    Q_PROPERTY(int targetPuzzleId READ targetPuzzleId NOTIFY targetPuzzleIdChanged)
    Q_PROPERTY(QString interactionPrompt READ interactionPrompt NOTIFY interactionPromptChanged)

    // Crane puzzle properties
    Q_PROPERTY(QVariantList craneBays READ craneBays NOTIFY craneStateChanged)
    Q_PROPERTY(int craneGrabbed READ craneGrabbed NOTIFY craneStateChanged) // -1 if empty, or container id (0, 1, 2)
    Q_PROPERTY(int craneSelectedBay READ craneSelectedBay NOTIFY craneStateChanged)
    Q_PROPERTY(int craneMatchedCount READ craneMatchedCount NOTIFY craneStateChanged)

    // Power routing circuit puzzle properties
    Q_PROPERTY(QVariantList circuitRotations READ circuitRotations NOTIFY circuitStateChanged)
    Q_PROPERTY(QVariantList circuitEnergized READ circuitEnergized NOTIFY circuitStateChanged)

    // Security keypad puzzle properties
    Q_PROPERTY(QString securityEnteredCode READ securityEnteredCode NOTIFY securityStateChanged)
    Q_PROPERTY(QString securityStatusMessage READ securityStatusMessage NOTIFY securityStateChanged)
    Q_PROPERTY(bool securityErrorFlash READ securityErrorFlash NOTIFY securityStateChanged)

    // Coolant regulation puzzle properties
    Q_PROPERTY(int valve1 READ valve1 NOTIFY coolantStateChanged)
    Q_PROPERTY(int valve2 READ valve2 NOTIFY coolantStateChanged)
    Q_PROPERTY(int valve3 READ valve3 NOTIFY coolantStateChanged)
    Q_PROPERTY(float systemFlow READ systemFlow NOTIFY coolantStateChanged)
    Q_PROPERTY(float corePressure READ corePressure NOTIFY coolantStateChanged)
    Q_PROPERTY(bool flowInRange READ isFlowInRange NOTIFY coolantStateChanged)
    Q_PROPERTY(bool pressureInRange READ isPressureInRange NOTIFY coolantStateChanged)

    // Manifest verification puzzle properties (Puzzle 1)
    Q_PROPERTY(int manifestAlpha READ manifestAlpha NOTIFY manifestChanged)
    Q_PROPERTY(int manifestBeta READ manifestBeta NOTIFY manifestChanged)
    Q_PROPERTY(int manifestGamma READ manifestGamma NOTIFY manifestChanged)
    Q_PROPERTY(QString manifestFeedback READ manifestFeedback NOTIFY manifestChanged)

    // Fuse inventory & bus coupling properties (Puzzle 2)
    Q_PROPERTY(bool fuseCollected READ fuseCollected NOTIFY fuseChanged)
    Q_PROPERTY(bool fuseInserted READ fuseInserted NOTIFY fuseChanged)

    // Administration investigation clues (Puzzle 3)
    Q_PROPERTY(bool clue1Found READ clue1Found NOTIFY cluesChanged)
    Q_PROPERTY(bool clue2Found READ clue2Found NOTIFY cluesChanged)
    Q_PROPERTY(bool clue3Found READ clue3Found NOTIFY cluesChanged)
    Q_PROPERTY(bool manifestClueFound READ manifestClueFound NOTIFY cluesChanged)
    Q_PROPERTY(int activeClueIndex READ activeClueIndex NOTIFY activeClueChanged)

public:
    enum PuzzleId {
        PuzzleNone = 0,
        PuzzleCrane = 1,        // or PuzzleManifest
        PuzzlePower = 2,
        PuzzleSecurity = 3,
        PuzzleCoolant = 4,
        PuzzleAdminClue = 5,    // Reception Memo / Clue 1
        PuzzleResearchFuse = 6, // 200A Ceramic Fuse in Electrical Control Room
        PuzzleAdminClue2 = 7,   // Supervisor Directive
        PuzzleAdminClue3 = 8,   // Archive Terminal
        PuzzleManifestClue = 9  // Shipping Manifest Log in Warehouse Office
    };
    Q_ENUM(PuzzleId)

    explicit PuzzleManager(QObject *parent = nullptr);

    // Getters
    bool isCraneSolved() const { return m_craneSolved; }
    bool isRiddleSolved() const { return m_craneSolved; }
    int selectedRiddleOption() const { return m_selectedRiddleOption; }
    QString riddleFeedback() const { return m_riddleFeedback; }
    bool isPowerSolved() const { return m_powerSolved; }
    bool isSecuritySolved() const { return m_securitySolved; }
    bool isCoolantSolved() const { return m_coolantSolved; }
    int solvedCount() const;

    int activePuzzle() const { return m_activePuzzle; }
    int targetPuzzleId() const { return m_targetPuzzleId; }
    QString interactionPrompt() const { return m_interactionPrompt; }

    QVariantList craneBays() const;
    int craneGrabbed() const { return m_craneGrabbed; }
    int craneSelectedBay() const { return m_craneSelectedBay; }
    int craneMatchedCount() const;

    QVariantList circuitRotations() const;
    QVariantList circuitEnergized() const;

    QString securityEnteredCode() const { return m_securityEnteredCode; }
    QString securityStatusMessage() const { return m_securityStatusMessage; }
    bool securityErrorFlash() const { return m_securityErrorFlash; }

    int valve1() const { return m_valve1; }
    int valve2() const { return m_valve2; }
    int valve3() const { return m_valve3; }
    float systemFlow() const { return m_systemFlow; }
    float corePressure() const { return m_corePressure; }
    bool isFlowInRange() const;
    bool isPressureInRange() const;

    // Variant getter / setter
    int level1Variant() const { return m_level1Variant; }
    void setLevel1Variant(int variant) { m_level1Variant = variant; }

    // Manifest getters
    int manifestAlpha() const { return m_manifestAlpha; }
    int manifestBeta() const { return m_manifestBeta; }
    int manifestGamma() const { return m_manifestGamma; }
    QString manifestFeedback() const { return m_manifestFeedback; }

    // Fuse getters
    bool fuseCollected() const { return m_fuseCollected; }
    bool fuseInserted() const { return m_fuseInserted; }

    // Clue getters
    bool clue1Found() const { return m_clue1Found; }
    bool clue2Found() const { return m_clue2Found; }
    bool clue3Found() const { return m_clue3Found; }
    bool manifestClueFound() const { return m_manifestClueFound; }
    int activeClueIndex() const { return m_activeClueIndex; }

    // Chamber barrier collision & gating checks
    Q_INVOKABLE bool isBarrierBlocking(int barrierId) const; // 1=Cargo, 2=Research, 3=Admin, 4=Maint
    Q_INVOKABLE bool isPositionBlockedByBarrier(float x, float z) const;

    // Player interaction update called each frame
    Q_INVOKABLE void updateInteraction(float deltaTime,
                                       const QVector3D &cameraPos,
                                       const QVector3D &lookDir,
                                       int currentLevel,
                                       bool playerAlive = true);

    Q_INVOKABLE bool interact(const QVector3D &playerPos, int currentLevel, bool playerAlive = true);
    Q_INVOKABLE void closeActivePuzzle();

    // ==================== RIDDLE PUZZLE API (Puzzle 1) ====================
    Q_INVOKABLE void selectRiddleOption(int index);
    Q_INVOKABLE bool submitRiddleAnswer();
    Q_INVOKABLE bool solveRiddle(int optionIndex);

    // ==================== CARGO MANIFEST PUZZLE API (Puzzle 1) ====================
    Q_INVOKABLE void assignManifest(int containerId, int bayId);
    Q_INVOKABLE bool verifyCargoManifest();
    Q_INVOKABLE void resetManifest();
    Q_INVOKABLE bool verifyManifestDirect(int alphaBay, int betaBay, int gammaBay);

    // ==================== CRANE COMPATIBILITY API ====================
    Q_INVOKABLE bool selectCraneBay(int bayIndex);
    Q_INVOKABLE bool grabOrReleaseCrane();
    Q_INVOKABLE void resetCrane();

    // ==================== POWER ROUTING CIRCUIT API (Puzzle 2) ====================
    Q_INVOKABLE void collectFuse();
    Q_INVOKABLE bool insertFuse();
    Q_INVOKABLE bool rotateCircuitTile(int tileIndex);
    Q_INVOKABLE void resetCircuit();

    // ==================== SECURITY KEYPAD & CLUES API (Puzzle 3) ====================
    Q_INVOKABLE void inspectClue(int clueIndex);
    Q_INVOKABLE void enterSecurityDigit(const QString &digit);
    Q_INVOKABLE void clearSecurityCode();
    Q_INVOKABLE bool submitSecurityCode();

    // ==================== COOLANT REGULATION API ====================
    Q_INVOKABLE void setValve(int valveIndex, int setting); // valveIndex 1..3, setting 0..3
    Q_INVOKABLE void cycleValve(int valveIndex);
    Q_INVOKABLE void resetCoolant();

    // Reset all puzzles (called on Level 1 restart)
    Q_INVOKABLE void resetAllPuzzles();

signals:
    void craneSolvedChanged();
    void riddleSolvedChanged();
    void riddleStateChanged();
    void powerSolvedChanged();
    void securitySolvedChanged();
    void coolantSolvedChanged();
    void puzzleStateChanged();
    void activePuzzleChanged();
    void targetPuzzleIdChanged();
    void interactionPromptChanged();
    void craneStateChanged();
    void circuitStateChanged();
    void securityStateChanged();
    void coolantStateChanged();
    void manifestChanged();
    void fuseChanged();
    void cluesChanged();
    void activeClueChanged();

    void puzzleCompleted(int puzzleId, const QString &name);
    void barrierOpened(int barrierId);
    void puzzleFeedback(const QString &message, const QString &colorHex);

private:
    void updateCircuitPowerFlow();
    void updateCoolantMetrics();
    int findTargetInteractable(const QVector3D &cameraPos, const QVector3D &lookDir, int currentLevel) const;

    // Completion flags
    bool m_craneSolved;
    bool m_powerSolved;
    bool m_securitySolved;
    bool m_coolantSolved;
    int m_level1Variant;

    int m_activePuzzle;
    int m_targetPuzzleId;
    QString m_interactionPrompt;

    // Riddle puzzle state
    int m_selectedRiddleOption;
    QString m_riddleFeedback;

    // Manifest verification state
    int m_manifestAlpha;
    int m_manifestBeta;
    int m_manifestGamma;
    QString m_manifestFeedback;

    // Research fuse state
    bool m_fuseCollected;
    bool m_fuseInserted;

    // Admin investigation clue state
    bool m_clue1Found;
    bool m_clue2Found;
    bool m_clue3Found;
    bool m_manifestClueFound;
    int m_activeClueIndex;

    // Crane state: 6 bays (0..5), storing container id (1=Alpha, 2=Beta, 3=Gamma, 0=Empty)
    // Target configuration: Bay 3=Alpha(1), Bay 1=Beta(2), Bay 5=Gamma(3)
    int m_bays[6];
    int m_craneGrabbed; // 0 if empty, or container id (1, 2, 3)
    int m_craneSelectedBay;

    // Circuit state: 3x3 grid (indices 0..8)
    // Rotations in degrees (0, 90, 180, 270)
    int m_circuitRotations[9];
    bool m_circuitEnergized[9];

    // Security keypad state
    QString m_securityEnteredCode;
    QString m_securityStatusMessage;
    bool m_securityErrorFlash;

    // Coolant regulation state (valves 0..3)
    int m_valve1;
    int m_valve2;
    int m_valve3;
    float m_systemFlow;
    float m_corePressure;
};

#endif // PUZZLEMANAGER_H
