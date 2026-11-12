import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * @brief HUD.qml provides the heads-up display overlay for the FPS game.
 * 
 * Adheres to the Minecraft/pixel-art aesthetic:
 * - Crisp hard-edged rectangular bars (orange for player, red for enemy)
 * - 5 blocky bullet indicators for the sniper magazine
 * - Retro score badge and ammo counters
 * - Precision center crosshair (hides when scoped)
 * - Reloading indicator and objective prompts
 */
Item {
    id: root
    anchors.fill: parent

    // Properties bound to C++ game entities
    property int playerHealth: 100
    property int playerMaxHealth: 100
    property int ammo: 5
    property int maxAmmo: 5
    property int reserveAmmo: 20
    property bool isReloading: false
    property bool isScoped: false
    property int score: 0
    property int enemyHealth: 100
    property int enemyMaxHealth: 100
    property bool enemyDead: false
    property string enemyState: "IDLE"
    property string enemyType: "NONE"
    property int activeEnemyCount: 0
    property string objectiveText: ""
    property string hitFeedbackText: ""
    property color hitFeedbackColor: "#ffffff"

    // Weapon & Arsenal Info (Stage V6)
    property int weaponIndex: 0
    property bool hasHeavyWeapon: false
    property string weaponName: "SNIPER RIFLE"
    property int sniperAmmo: 5
    property int sniperReserve: 20
    property int heavyAmmo: 30
    property int heavyReserve: 90

    // Inventory Item Counters (Stage 11)
    property int foodPacks: 1
    property int bandages: 1
    property int medkits: 0

    // Level 3 Boss Arena Info (Stage V7)
    property bool isLevel3: false
    property int activeVents: 4
    property int totalVents: 4
    property int totalVentHp: 600
    property int maxTotalVentHp: 600
    property var bossArenaRef: null

    // Level Identification & Performance (Stage V8)
    property string levelName: "FABRICATION FLOORS"
    property string difficultyName: "EASY"
    property int fps: 60
    property real damageFlashIntensity: 0.0
    property real healFlashIntensity: 0.0

    // Hallway Darkness & Tactical Flashlight Status
    property bool flashlightActive: true
    property bool hallwayDarknessActive: true

    // Contextual Door Interaction Prompt (continuously updated when targeting a door)
    property string interactionPrompt: ""

    // Four-Key Mission & Extraction Progress (Day 2)
    property int collectedKeysCount: 0
    property int totalKeysRequired: 4
    property int collectedKeysMask: 0
    property bool bossCompleted: false
    property bool extractionAvailable: false

    // ==================== FULLSCREEN DAMAGE & HEAL FLASHES ====================
    Rectangle {
        id: damageOverlay
        anchors.fill: parent
        color: "#e74c3c"
        opacity: Math.min(0.6, root.damageFlashIntensity * 0.6)
        visible: opacity > 0.01
        z: 99
    }

    Rectangle {
        id: healOverlay
        anchors.fill: parent
        color: "#2ecc71"
        opacity: Math.min(0.35, root.healFlashIntensity * 0.35)
        visible: opacity > 0.01
        z: 99
    }

    // ==================== TOP-CENTER: LEVEL NAME BADGE ====================
    Rectangle {
        id: levelNameCard
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        width: levelRow.width + 32
        height: 34
        color: "#d9101216"
        border.color: root.isLevel3 ? "#e74c3c" : "#3498db"
        border.width: 2
        radius: 0

        Row {
            id: levelRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                color: root.isLevel3 ? "#e74c3c" : "#3498db"
            }

            Text {
                text: root.levelName.toUpperCase()
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 2
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 12
                color: "#4a4f59"
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: diffText.width + 10
                height: 18
                color: root.difficultyName.toUpperCase() === "HARD" ? "#40e74c3c" : "#402ecc71"
                border.color: root.difficultyName.toUpperCase() === "HARD" ? "#e74c3c" : "#2ecc71"
                border.width: 1

                Text {
                    id: diffText
                    anchors.centerIn: parent
                    text: root.difficultyName.toUpperCase()
                    color: root.difficultyName.toUpperCase() === "HARD" ? "#ff7675" : "#2ecc71"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1
                }
            }
        }
    }

    // ==================== TOP-CENTER: LEVEL 3 BOSS HEALTH PANEL ====================
    Rectangle {
        id: bossHealthPanel
        anchors.top: levelNameCard.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 6
        width: 460
        height: 64
        color: "#f00c0f14"
        border.color: (root.totalVentHp <= 0) ? "#2ecc71" : "#00e5ff"
        border.width: 2
        visible: root.isLevel3
        z: 10

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 3

            // Row 1: Title & Overall HP Counter
            Row {
                width: parent.width

                Row {
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        color: (root.totalVentHp <= 0) ? "#2ecc71" : "#00e5ff"
                    }
                    Text {
                        text: "VANGUARD MAINFRAME // COOLANT INTEGRITY"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }

                Item {
                    width: parent.width - 290
                    height: 1
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.totalVentHp + " / " + root.maxTotalVentHp + " HP"
                    color: root.totalVentHp > 250 ? "#00e5ff" : (root.totalVentHp > 100 ? "#f39c12" : "#e74c3c")
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            // Row 2: Master Coolant Health Bar
            Rectangle {
                width: parent.width
                height: 12
                color: "#161920"
                border.color: "#343840"
                border.width: 1

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width: Math.max(0, (parent.width - 2) * (root.totalVentHp / Math.max(1, root.maxTotalVentHp)))
                    color: root.totalVentHp > 300 ? "#00e5ff" : (root.totalVentHp > 150 ? "#f39c12" : "#e74c3c")

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                }
            }

            // Row 3: 4 Individual Vent Micro-Indicators
            Row {
                width: parent.width
                spacing: 5

                Repeater {
                    model: 4
                    Rectangle {
                        width: (parent.width - 15) / 4
                        height: 18
                        readonly property bool isDestroyed: root.bossArenaRef ? root.bossArenaRef.isVentDestroyed(index) : false
                        readonly property int ventHp: root.bossArenaRef ? root.bossArenaRef.ventHealth(index) : 150
                        color: isDestroyed ? "#16181d" : "#1c222b"
                        border.color: isDestroyed ? "#2ecc71" : "#00e5ff"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: parent.isDestroyed ? ("VENT " + (index + 1) + ": DOWN") : ("VENT " + (index + 1) + ": " + parent.ventHp)
                            color: parent.isDestroyed ? "#2ecc71" : "#ffffff"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    // ==================== TOP-LEFT: PLAYER HEALTH BAR ====================
    Rectangle {
        id: healthCard
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 24
        anchors.leftMargin: 24
        width: 240
        height: 54
        color: "#d9101216"
        border.color: "#343840"
        border.width: 2
        radius: 0 // Hard pixel edges

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Row {
                width: parent.width
                spacing: 6

                Text {
                    text: "PLAYER"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { width: healthCard.width - 130 }

                Text {
                    text: root.playerHealth + " / " + root.playerMaxHealth + " HP"
                    color: "#e67e22"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            // Outer Health Bar Frame
            Rectangle {
                width: parent.width
                height: 18
                color: "#20242b"
                border.color: "#4a4f59"
                border.width: 1
                radius: 0

                // Inner Orange Health Bar Fill (Dynamic Width)
                Rectangle {
                    id: healthFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * (root.playerHealth / root.playerMaxHealth))
                    color: root.playerHealth > 25 ? "#e67e22" : "#e74c3c" // Orange, turns red on critical low HP

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }

    // ==================== TOP-LEFT: ACCESS KEYS MISSION PROGRESS (DAY 2) ====================
    Rectangle {
        id: accessKeysCard
        anchors.top: healthCard.bottom
        anchors.left: healthCard.left
        anchors.topMargin: 8
        width: 240
        height: 46
        color: "#d9101216"
        border.color: (root.collectedKeysCount >= root.totalKeysRequired) ? "#2ecc71" : "#343840"
        border.width: 2
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Row {
                width: parent.width

                Text {
                    text: "ACCESS KEYS"
                    color: "#95a5a6"
                    font.pixelSize: 10
                    font.bold: true
                }

                Item { width: accessKeysCard.width - 132; height: 1 }

                Text {
                    text: root.collectedKeysCount + "/" + root.totalKeysRequired
                    color: (root.collectedKeysCount >= root.totalKeysRequired) ? "#2ecc71" : "#00e5ff"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            Row {
                spacing: 6

                Repeater {
                    model: 4

                    Rectangle {
                        readonly property bool keyHeld: (root.collectedKeysMask & (1 << index)) !== 0
                        readonly property color keyAccent: {
                            switch (index) {
                            case 0: return "#00e5ff"
                            case 1: return "#2ecc71"
                            case 2: return "#f1c40f"
                            default: return "#e056fd"
                            }
                        }

                        width: 52
                        height: 16
                        color: keyHeld ? "#1b2832" : "#181b21"
                        border.color: keyHeld ? keyAccent : "#343840"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: keyHeld ? ("KEY " + (index + 1)) : ("K" + (index + 1))
                            color: keyHeld ? parent.keyAccent : "#636e72"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    // ==================== LEVEL 3: EXTRACTION CHECKLIST ====================
    Rectangle {
        id: extractionChecklistCard
        anchors.top: accessKeysCard.bottom
        anchors.left: healthCard.left
        anchors.topMargin: 8
        width: 240
        height: 82
        visible: root.isLevel3
        color: "#d9101216"
        border.color: root.extractionAvailable ? "#2ecc71" : "#343840"
        border.width: 1
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 3

            Text {
                text: "EXTRACTION PROTOCOL"
                color: root.extractionAvailable ? "#2ecc71" : "#00e5ff"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
            }

            Text {
                readonly property bool done: root.collectedKeysCount >= root.totalKeysRequired
                text: "KEYS: " + root.collectedKeysCount + "/" + root.totalKeysRequired
                color: done ? "#2ecc71" : "#ecf0f1"
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                readonly property int destroyedVents: root.totalVents - root.activeVents
                readonly property bool done: root.activeVents === 0
                text: "COOLING VENTS: " + destroyedVents + "/" + root.totalVents
                color: done ? "#2ecc71" : "#ecf0f1"
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                text: "CORE: " + (root.bossCompleted ? "OVERLOADED" : "ACTIVE")
                      + "  |  EXIT: " + (root.extractionAvailable ? "AVAILABLE" : "LOCKED")
                color: root.extractionAvailable ? "#2ecc71" : "#f39c12"
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    // ==================== TOP-RIGHT: SCORE & ENEMY STATUS ====================
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24
        anchors.rightMargin: 24
        spacing: 8

        // Real-Time FPS Badge (Stage V8)
        Rectangle {
            anchors.right: parent.right
            width: 90
            height: 26
            color: "#d9101216"
            border.color: "#343840"
            border.width: 1
            radius: 0

            Row {
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    color: root.fps >= 50 ? "#2ecc71" : (root.fps >= 30 ? "#f1c40f" : "#e74c3c")
                }

                Text {
                    text: "FPS: " + root.fps
                    color: root.fps >= 50 ? "#2ecc71" : (root.fps >= 30 ? "#f1c40f" : "#e74c3c")
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // Tactical Flashlight & Dark Hallway Shader Status Badges
        Row {
            anchors.right: parent.right
            spacing: 6

            // Flashlight Status [F]
            Rectangle {
                width: 95
                height: 24
                color: root.flashlightActive ? "#e60f2838" : "#d9101216"
                border.color: root.flashlightActive ? "#00e5ff" : "#343840"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5
                        height: 5
                        color: root.flashlightActive ? "#00e5ff" : "#636e72"
                    }
                    Text {
                        text: "[F] LIGHT: " + (root.flashlightActive ? "ON" : "OFF")
                        color: root.flashlightActive ? "#00e5ff" : "#7f8c8d"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            // Hallway Shader Status [H]
            Rectangle {
                width: 112
                height: 24
                color: root.hallwayDarknessActive ? "#e61a2618" : "#d9101216"
                border.color: root.hallwayDarknessActive ? "#2ecc71" : "#343840"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5
                        height: 5
                        color: root.hallwayDarknessActive ? "#2ecc71" : "#636e72"
                    }
                    Text {
                        text: "[H] SHADER: " + (root.hallwayDarknessActive ? "ON" : "OFF")
                        color: root.hallwayDarknessActive ? "#2ecc71" : "#7f8c8d"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        // Score Badge
        Rectangle {
            anchors.right: parent.right
            width: 180
            height: 38
            color: "#d9101216"
            border.color: "#343840"
            border.width: 2
            radius: 0

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "SCORE"
                    color: "#95a5a6"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    text: root.score.toString()
                    color: "#2ecc71"
                    font.pixelSize: 16
                    font.bold: true
                }
            }
        }

        // Active Enemy Counter
        Rectangle {
            anchors.right: parent.right
            width: 120
            height: 28
            color: "#d9101216"
            border.color: root.activeEnemyCount > 0 ? "#e74c3c" : "#343840"
            border.width: 1
            radius: 0

            Row {
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    color: root.activeEnemyCount > 0 ? "#e74c3c" : "#636e72"
                }

                Text {
                    text: "HOSTILES: " + root.activeEnemyCount
                    color: root.activeEnemyCount > 0 ? "#e74c3c" : "#636e72"
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }

        // Nearest Enemy Target Health Bar
        Rectangle {
            anchors.right: parent.right
            width: 220
            height: root.isLevel3 ? 62 : 52
            color: "#d9101216"
            border.color: "#343840"
            border.width: 2
            radius: 0
            visible: root.activeEnemyCount > 0 || !root.enemyDead

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: (root.enemyType === "NONE")
                              ? "NO TARGET"
                              : (root.enemyDead
                                 ? (root.enemyType + " [ELIMINATED]")
                                 : (root.isLevel3 ? (root.enemyType + " [MINION]") : (root.enemyType + " [" + root.enemyState + "]")))
                        color: (root.enemyType === "NONE") ? "#95a5a6" : (root.enemyDead ? "#2ecc71" : "#e74c3c")
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true; width: 6 }

                    Text {
                        text: (root.enemyType === "NONE") ? "" : (root.enemyHealth + " / " + root.enemyMaxHealth + " HP")
                        color: root.enemyDead ? "#2ecc71" : "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                // Red Enemy Health Fill
                Rectangle {
                    width: parent.width
                    height: 14
                    color: "#20242b"
                    border.color: "#4a4f59"
                    border.width: 1
                    radius: 0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: Math.max(0, (parent.width - 2) * (root.enemyHealth / Math.max(1, root.enemyMaxHealth)))
                        color: "#c0392b"

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                }

                Text {
                    text: "PERIMETER DEFENSE (RESPAWNS)"
                    color: "#f39c12"
                    font.pixelSize: 8
                    font.bold: true
                    visible: root.isLevel3 && !root.enemyDead
                }
            }
        }
    }

    // ==================== BOTTOM-RIGHT: WEAPON & AMMO DISPLAY ====================
    Rectangle {
        id: ammoCard
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 24
        anchors.rightMargin: 24
        width: 230
        height: root.hasHeavyWeapon ? 96 : 76
        color: "#d9101216"
        border.color: root.isReloading ? "#f39c12" : (root.weaponIndex === 1 ? "#00e5ff" : "#343840")
        border.width: 2
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 4

            // Top Header: Active Weapon Name & Switch Prompt
            Row {
                width: parent.width
                spacing: 6

                Text {
                    text: root.weaponName
                    color: root.weaponIndex === 1 ? "#00e5ff" : "#e67e22"
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { width: 1; height: 1 }

                Text {
                    text: root.hasHeavyWeapon ? "[Q] SWITCH" : ""
                    color: "#95a5a6"
                    font.pixelSize: 10
                    font.bold: true
                    visible: root.hasHeavyWeapon
                }
            }

            // Main Ammo Numbers & Reload State
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // Loaded Ammo
                Text {
                    text: root.ammo.toString()
                    color: root.ammo > 0 ? (root.weaponIndex === 1 ? "#00e5ff" : "#ffffff") : "#e74c3c"
                    font.pixelSize: 24
                    font.bold: true
                }

                // Reserve Ammo
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    text: "/ " + root.reserveAmmo
                    color: "#7f8c8d"
                    font.pixelSize: 13
                    font.bold: true
                }

                Item { width: 6 }

                // Reloading Status Badge
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isReloading ? "RELOADING" : (root.ammo === 0 ? "PRESS R" : "")
                    color: root.isReloading ? "#f39c12" : "#e74c3c"
                    font.pixelSize: 10
                    font.bold: true
                    visible: text.length > 0
                }
            }

            // Magazine Gauge: Discrete Pips for Sniper (<=10) or Segmented Plasma Bar (>10)
            Item {
                width: parent.width
                height: 8

                // 1. Discrete bullet squares for Sniper Rifle (5 to 10 rounds)
                Row {
                    anchors.centerIn: parent
                    spacing: root.maxAmmo > 5 ? 3 : 4
                    visible: root.maxAmmo <= 10

                    Repeater {
                        model: root.maxAmmo
                        Rectangle {
                            width: root.maxAmmo > 5 ? 12 : 16
                            height: 7
                            radius: 0
                            color: index < root.ammo ? "#e67e22" : "#2c3e50"
                            border.color: index < root.ammo ? "#d35400" : "#1a252f"
                            border.width: 1
                        }
                    }
                }

                // 2. Segmented Plasma Bar for Heavy Weapon (30 rounds)
                Rectangle {
                    anchors.fill: parent
                    visible: root.maxAmmo > 10
                    color: "#1a252f"
                    border.color: "#2c3e50"
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: Math.max(0, (parent.width - 2) * (root.ammo / Math.max(1, root.maxAmmo)))
                        color: "#00e5ff"
                    }
                }
            }

            // Dual Arsenal Mini-Status Bar (shows both weapons when Heavy Weapon is owned)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                visible: root.hasHeavyWeapon

                Rectangle {
                    width: 102
                    height: 16
                    color: root.weaponIndex === 0 ? "#33e67e22" : "#101216"
                    border.color: root.weaponIndex === 0 ? "#e67e22" : "#2c3e50"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "1: SNIPER " + root.sniperAmmo + "/" + root.sniperReserve
                        color: root.weaponIndex === 0 ? "#ffffff" : "#7f8c8d"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Rectangle {
                    width: 102
                    height: 16
                    color: root.weaponIndex === 1 ? "#3300e5ff" : "#101216"
                    border.color: root.weaponIndex === 1 ? "#00e5ff" : "#2c3e50"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "2: PLASMA " + root.heavyAmmo + "/" + root.heavyReserve
                        color: root.weaponIndex === 1 ? "#ffffff" : "#7f8c8d"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }
        }
    }

    // ==================== CENTER: PIXEL CROSSHAIR ====================
    Item {
        id: crosshair
        anchors.centerIn: parent
        width: 24
        height: 24
        visible: !root.isScoped // Hidden when zoomed into the sniper scope

        // Center Pixel Dot
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: 2
            color: "#ffffff"
        }

        // Top tick
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: 4
            width: 2
            height: 6
            color: "#ffffff"
        }

        // Bottom tick
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 4
            width: 2
            height: 6
            color: "#ffffff"
        }

        // Left tick
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 4
            width: 6
            height: 2
            color: "#ffffff"
        }

        // Right tick
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 4
            width: 6
            height: 2
            color: "#ffffff"
        }
    }

    // ==================== CENTER: SCOPED RED AIM POINT (+) ====================
    Item {
        id: scopedAimPoint
        anchors.centerIn: parent
        width: 24
        height: 24
        visible: root.isScoped // Active when right-clicking to aim/scope

        // Center red precision dot
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            color: "#ff0033"
            radius: 2
        }

        // Horizontal red cross tick (+)
        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 2
            color: "#ff0033"
        }

        // Vertical red cross tick (+)
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: 16
            color: "#ff0033"
        }
    }

    // ==================== CENTER: HIT NOTIFICATION FEEDBACK ====================
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -65
        text: root.hitFeedbackText
        color: root.hitFeedbackColor
        font.pixelSize: 16
        font.bold: true
        visible: text.length > 0
    }

    // ==================== CENTER-LOWER: CONTEXTUAL DOOR INTERACTION PROMPT ====================
    Rectangle {
        id: doorPromptBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 72
        width: doorPromptText.implicitWidth + 28
        height: 30
        visible: root.interactionPrompt.length > 0
        color: "#e6101216"
        border.width: 1
        border.color: {
            if (root.interactionPrompt.indexOf("[LOCKED]") !== -1)
                return "#e74c3c"
            if (root.interactionPrompt.indexOf("OBSTRUCTED") !== -1)
                return "#e67e22"
            if (root.interactionPrompt.indexOf("EXTRACTION AVAILABLE") !== -1)
                return "#2ecc71"
            return "#00e5ff"
        }
        radius: 0

        Text {
            id: doorPromptText
            anchors.centerIn: parent
            text: root.interactionPrompt
            color: {
                if (root.interactionPrompt.indexOf("[LOCKED]") !== -1)
                    return "#ff7675"
                if (root.interactionPrompt.indexOf("OBSTRUCTED") !== -1)
                    return "#f39c12"
                if (root.interactionPrompt.indexOf("EXTRACTION AVAILABLE") !== -1)
                    return "#2ecc71"
                return "#ffffff"
            }
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1
        }
    }

    // ==================== LEVEL 3: COOLING VENTS STATUS BADGE (STAGE V7) ====================
    Rectangle {
        id: ventsStatusCard
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 68
        width: ventsRow.width + 24
        height: 38
        color: "#e6101216"
        border.color: (root.totalVents - root.activeVents === root.totalVents) ? "#2ecc71" : "#00e5ff"
        border.width: 1
        radius: 0
        visible: root.isLevel3

        Row {
            id: ventsRow
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                color: (root.totalVents - root.activeVents === root.totalVents) ? "#2ecc71" : "#00e5ff"
            }

            Text {
                text: "COOLING VENTS DESTROYED: " + (root.totalVents - root.activeVents) + "/" + root.totalVents + " (DESTROY ALL 4 TO OVERLOAD CORE)"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Repeater {
                    model: root.totalVents
                    Rectangle {
                        width: 12
                        height: 12
                        color: index < (root.totalVents - root.activeVents) ? "#2ecc71" : "#ff3d00"
                        border.color: "#ffffff"
                        border.width: 1
                    }
                }
            }
        }
    }

    // ==================== BOTTOM-CENTER: OBJECTIVE BANNER ====================
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        width: objRow.width + 28
        height: 36
        color: "#e6101216"
        border.color: "#343840"
        border.width: 1
        radius: 0
        visible: root.objectiveText.length > 0

        Row {
            id: objRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                color: "#e67e22"
            }

            Text {
                text: root.objectiveText
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // ==================== BOTTOM-LEFT: INVENTORY HOTBAR (STAGE 11) ====================
    Rectangle {
        id: inventoryCard
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 24
        anchors.leftMargin: 24
        width: 290
        height: 64
        color: "#d9101216"
        border.color: "#343840"
        border.width: 2
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Row {
                width: parent.width
                Text {
                    text: "INVENTORY / RECOVERY [KEYS 1, 2, 3]"
                    color: "#95a5a6"
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // Slot 1: Food Pack (+20 HP)
                Rectangle {
                    width: 88
                    height: 36
                    color: root.foodPacks > 0 ? "#202820" : "#1a1c20"
                    border.color: root.foodPacks > 0 ? "#27ae60" : "#343840"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "[1]"
                            color: "#f39c12"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Column {
                            spacing: 1
                            Text {
                                text: "FOOD +20"
                                color: root.foodPacks > 0 ? "#ffffff" : "#636e72"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Text {
                                text: "x" + root.foodPacks
                                color: root.foodPacks > 0 ? "#2ecc71" : "#7f8c8d"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }

                // Slot 2: Bandage (+30 HP)
                Rectangle {
                    width: 88
                    height: 36
                    color: root.bandages > 0 ? "#1c2430" : "#1a1c20"
                    border.color: root.bandages > 0 ? "#2980b9" : "#343840"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "[2]"
                            color: "#3498db"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Column {
                            spacing: 1
                            Text {
                                text: "BANDAGE +30"
                                color: root.bandages > 0 ? "#ffffff" : "#636e72"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Text {
                                text: "x" + root.bandages
                                color: root.bandages > 0 ? "#3498db" : "#7f8c8d"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }

                // Slot 3: Medkit (+50 HP)
                Rectangle {
                    width: 88
                    height: 36
                    color: root.medkits > 0 ? "#2e1c24" : "#1a1c20"
                    border.color: root.medkits > 0 ? "#e74c3c" : "#343840"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "[3]"
                            color: "#e74c3c"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Column {
                            spacing: 1
                            Text {
                                text: "MEDKIT +50"
                                color: root.medkits > 0 ? "#ffffff" : "#636e72"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            Text {
                                text: "x" + root.medkits
                                color: root.medkits > 0 ? "#e74c3c" : "#7f8c8d"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
