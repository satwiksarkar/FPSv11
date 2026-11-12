import QtQuick
import QtQuick.Controls

/**
 * @brief GameOver.qml handles both GAME OVER and YOU WIN results.
 * 
 * Complies with Stage 8 additions:
 * - Displays "YOU WIN" in brilliant victory green when enemy sniper dies first.
 * - Displays "GAME OVER" in bold crimson red when the player is defeated.
 * - Displays Final Score badge.
 * - Provides Restart Duel and Return to Main Menu actions.
 */
Item {
    id: root
    anchors.fill: parent

    property bool isWon: false
    property int finalScore: 0

    signal restartRequested()
    signal mainMenuRequested()

    // Semi-transparent colored atmosphere backdrop
    Rectangle {
        anchors.fill: parent
        color: root.isWon ? "#d90b2413" : "#d9280d0d"
    }

    Rectangle {
        id: resultCard
        anchors.centerIn: parent
        width: 440
        height: 420
        color: "#ea101216"
        border.color: root.isWon ? "#2ecc71" : "#e74c3c"
        border.width: 2
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

            // Outcome Header Banner
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isWon ? "VANGUARD DESTROYED" : "GAME OVER"
                    color: root.isWon ? "#2ecc71" : "#e74c3c"
                    font.pixelSize: 28
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isWon ? "Thermal Overload Complete. The Logic Core is silenced." : "Systems Terminated. Foundry Seven remains under AI control."
                    color: "#ecf0f1"
                    font.pixelSize: 12
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                    height: 2
                    color: root.isWon ? "#27ae60" : "#c0392b"
                }
            }

            // Score Display Card
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 64
                color: "#181d24"
                border.color: "#34495e"
                border.width: 1
                radius: 0

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "FINAL SCORE"
                        color: "#95a5a6"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.finalScore.toString()
                        color: root.isWon ? "#2ecc71" : "#f1c40f"
                        font.pixelSize: 22
                        font.bold: true
                    }
                }
            }

            Item { width: 1; height: 8 }

            // Restart Button
            Button {
                id: btnRestart
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🔄  PLAY AGAIN / RESTART"
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
                width: 280
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "🏠  RETURN TO MAIN MENU"
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
