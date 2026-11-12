import QtQuick
import QtQuick.Controls

/**
 * @brief PauseMenu.qml provides the in-game pause overlay.
 * 
 * Displayed when the player presses Escape or clicks Pause.
 * Allows resuming gameplay, restarting the duel, or returning to the Main Menu.
 */
Item {
    id: root
    anchors.fill: parent

    signal resumeRequested()
    signal restartRequested()
    signal mainMenuRequested()
    signal changeLevelRequested(int level)

    property var gameManager: null
    property int currentLevel: 1

    // Semi-transparent dark vignette backdrop
    Rectangle {
        anchors.fill: parent
        color: "#c0090c10"
    }

    Rectangle {
        id: pauseCard
        anchors.centerIn: parent
        width: 380
        height: 460
        color: "#ea101216"
        border.color: "#3498db" // Cool blue border
        border.width: 2
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            // Header
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "GAME PAUSED"
                    color: "#3498db"
                    font.pixelSize: 24
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Press Esc or Resume to return to combat"
                    color: "#95a5a6"
                    font.pixelSize: 11
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 180
                    height: 2
                    color: "#2980b9"
                }
            }

            Item { width: 1; height: 6 }

            // Resume Button
            Button {
                id: btnResume
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 42
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "▶  RESUME GAME"
                    color: btnResume.hovered ? "#ffffff" : "#2ecc71"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnResume.hovered ? "#27ae60" : "#14251a"
                    border.color: "#2ecc71"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.resumeRequested()
                }
            }

            // Mission / Level Select Button
            Button {
                id: btnSkipLevel
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 40
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🗺  MISSION: [ LVL " + root.currentLevel + (root.currentLevel === 1 ? ": FABRICATION" : (root.currentLevel === 2 ? ": ARMORY" : ": LOGIC CORE")) + " ]"
                    color: btnSkipLevel.hovered ? "#ffffff" : "#f1c40f"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnSkipLevel.hovered ? "#3d3210" : "#181408"
                    border.color: "#f1c40f"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    var nextLvl = (root.currentLevel % 3) + 1
                    root.changeLevelRequested(nextLvl)
                }
            }

            // Difficulty Button
            Button {
                id: btnDiffPause
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 40
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
                    color: btnDiffPause.hovered ? "#1f2937" : "#131720"
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

            // Restart Button
            Button {
                id: btnRestart
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🔄  RESTART DUEL"
                    color: btnRestart.hovered ? "#ffffff" : "#f39c12"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnRestart.hovered ? "#d35400" : "#281e14"
                    border.color: "#f39c12"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.restartRequested()
                }
            }

            // Main Menu Button
            Button {
                id: btnMainMenu
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🏠  MAIN MENU"
                    color: btnMainMenu.hovered ? "#ffffff" : "#bdc3c7"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnMainMenu.hovered ? "#4a5568" : "#1c222b"
                    border.color: "#718096"
                    border.width: 1
                    radius: 0
                }
                onClicked: {
                    root.mainMenuRequested()
                }
            }
        }
    }
}
