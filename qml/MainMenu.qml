import QtQuick
import QtQuick.Controls

/**
 * @brief MainMenu.qml displays the retro voxel-themed title and menu screen.
 * 
 * Provides:
 * - Game Title and Subtitle with Minecraft/voxel aesthetic
 * - Start Game button
 * - How to Play / Instructions modal dialog listing all controls
 * - Exit Application button
 */
Item {
    id: root
    anchors.fill: parent

    signal startGameRequested()
    signal startLevelRequested(int level)
    signal exitRequested()

    property bool showInstructions: false
    property var gameManager: null
    property int selectedLevel: 1

    // Dark semi-transparent atmospheric backdrop overlay
    Rectangle {
        anchors.fill: parent
        color: "#d90b0d11"
    }

    // ==================== MAIN MENU CONTAINER ====================
    Rectangle {
        id: menuCard
        anchors.centerIn: parent
        width: 440
        height: 570
        color: "#ea101216"
        border.color: "#e67e22" // Warm voxel orange border
        border.width: 2
        radius: 0 // Hard pixel corners

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 12

            // Title Banner
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "VOXEL SNIPER"
                    color: "#f39c12"
                    font.pixelSize: 34
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "COLLEGE LAB FPS PROJECT - QT 6"
                    color: "#7f8c8d"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 220
                    height: 2
                    color: "#e67e22"
                }
            }

            Item { width: 1; height: 6 }

            // Start Game Button
            Button {
                id: btnStart
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 48
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "▶  START MISSION"
                    color: btnStart.hovered ? "#ffffff" : "#2ecc71"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnStart.hovered ? "#27ae60" : "#1a251e"
                    border.color: "#2ecc71"
                    border.width: 2
                    radius: 0
                }
                onClicked: {
                    root.startLevelRequested(root.selectedLevel)
                }
            }

            // Mission / Level Select Button
            Button {
                id: btnLevel
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 42
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🗺  MISSION: [ " + (root.selectedLevel === 1 ? "1: FABRICATION" : (root.selectedLevel === 2 ? "2: THE ARMORY" : "3: THE LOGIC CORE")) + " ]"
                    color: btnLevel.hovered ? "#ffffff" : "#f1c40f"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnLevel.hovered ? "#3d3210" : "#181408"
                    border.color: "#f1c40f"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.selectedLevel = (root.selectedLevel % 3) + 1
                }
            }

            // Difficulty Selection Button
            Button {
                id: btnDifficulty
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 42
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "⚙  DIFFICULTY:  [ " + (root.gameManager ? root.gameManager.difficultyName : "EASY") + " ]"
                    color: (root.gameManager && root.gameManager.difficultyName === "HARD") ? "#e74c3c" : "#00e5ff"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnDifficulty.hovered ? "#1f2937" : "#131720"
                    border.color: (root.gameManager && root.gameManager.difficultyName === "HARD") ? "#e74c3c" : "#00e5ff"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    if (root.gameManager) {
                        root.gameManager.toggleDifficulty()
                    }
                }
            }

            // Instructions Button
            Button {
                id: btnInstructions
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "📖  INSTRUCTIONS & CONTROLS"
                    color: btnInstructions.hovered ? "#ffffff" : "#3498db"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnInstructions.hovered ? "#2980b9" : "#14212b"
                    border.color: "#3498db"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.showInstructions = true
                }
            }

            // Exit Button
            Button {
                id: btnExit
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "✕  EXIT GAME"
                    color: btnExit.hovered ? "#ffffff" : "#e74c3c"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnExit.hovered ? "#c0392b" : "#241618"
                    border.color: "#e74c3c"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.exitRequested()
                }
            }

            Item { width: 1; height: 10 }

            // Footer note
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Built with Qt Quick 3D & C++17 • Stage 8 Complete"
                color: "#566573"
                font.pixelSize: 10
            }
        }
    }

    // ==================== INSTRUCTIONS MODAL OVERLAY ====================
    Rectangle {
        id: instructionsOverlay
        anchors.fill: parent
        color: "#ee0a0c10"
        visible: root.showInstructions
        z: 50

        // Intercept clicks outside the card
        MouseArea {
            anchors.fill: parent
            onClicked: root.showInstructions = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 520
            height: 440
            color: "#ea101216"
            border.color: "#3498db"
            border.width: 2
            radius: 0

            MouseArea {
                anchors.fill: parent
                // Absorb click inside modal so clicking inside doesn't close it
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "MISSION INSTRUCTIONS & CONTROLS"
                    color: "#3498db"
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#2c3e50"
                }

                // Controls Grid
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 20

                    Text { text: "WASD"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Walk Forward / Left / Back / Right"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "Mouse Look"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "First-person camera rotation (Yaw / Pitch)"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "Space"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Jump with gravity physics"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "Ctrl / C"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Crouch (lowers camera height & speed)"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "LMB (Left Click)"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Shoot Sniper Rifle (Door & Enemy)"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "RMB / Q / Z"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Aim / Scope Zoom optic sight"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "R"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Reload 5-round bolt-action magazine"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "E"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Interact with Start Room wooden door"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "Esc / P"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Pause / Resume Game & Release Mouse"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "1 / 2 / 3"; color: "#f39c12"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Food Pack / Bandage / Medkit (Stage 11)"; color: "#95a5a6"; font.pixelSize: 12 }

                    Text { text: "F"; color: "#00e5ff"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Toggle Tactical Camera Flashlight"; color: "#ecf0f1"; font.pixelSize: 12 }

                    Text { text: "H"; color: "#2ecc71"; font.bold: true; font.pixelSize: 12 }
                    Text { text: "Toggle Atmospheric Dark Hallway Shaders"; color: "#ecf0f1"; font.pixelSize: 12 }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#2c3e50"
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140
                    height: 36
                    focusPolicy: Qt.NoFocus
                    contentItem: Text {
                        text: "CLOSE"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#34495e"
                        border.color: "#7f8c8d"
                        border.width: 1
                        radius: 0
                    }
                    onClicked: root.showInstructions = false
                }
            }
        }
    }
}
