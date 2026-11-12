import QtQuick
import QtQuick.Controls

/**
 * @brief StoryScreen.qml displays the Project VANGUARD narrative briefing.
 * 
 * Displayed before each level and after campaign victory.
 * Halts active gameplay while the user reads the mission objectives.
 * Adheres strictly to the pixel/retro aesthetic with crisp hard-edged borders.
 */
Item {
    id: root
    anchors.fill: parent

    property string title: "PROJECT VANGUARD"
    property string storyText: ""
    property bool isWin: false

    signal continueRequested()

    // Pure black retro sci-fi background
    Rectangle {
        anchors.fill: parent
        color: "#050608"
    }

    // Atmospheric subtle grid lines (retro terminal feel)
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(840, parent.width - 40)
        height: Math.min(560, parent.height - 40)
        color: "#0c0e14"
        border.color: root.isWin ? "#2ecc71" : "#e67e22"
        border.width: 2
        radius: 0 // Hard pixel corners

        Column {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 24

            // Top Header: Terminal Classification
            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    color: root.isWin ? "#2ecc71" : "#e67e22"
                }

                Text {
                    text: root.isWin ? "SYSTEM TRANSMISSION // OVERRIDE COMPLETE" : "SECURE TERMINAL // FOUNDRY SEVEN INTEL"
                    color: root.isWin ? "#2ecc71" : "#f39c12"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                }
            }

            // Level / Mission Title
            Text {
                text: root.title
                color: "#ffffff"
                font.pixelSize: 26
                font.bold: true
                font.letterSpacing: 1
            }

            // Decorative separator line
            Rectangle {
                width: parent.width
                height: 1
                color: "#282c37"
            }

            // Mission Story Content
            Flickable {
                width: parent.width
                height: 240
                contentWidth: width
                contentHeight: storyContentText.paintedHeight
                clip: true

                Text {
                    id: storyContentText
                    width: parent.width
                    text: root.storyText
                    color: "#d0d4dc"
                    font.pixelSize: 15
                    lineHeight: 1.5
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                height: 8
            }

            // Bottom Continue Prompt (Pulsing / Blinking)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: promptText.width + 36
                height: 42
                color: "#181b24"
                border.color: root.isWin ? "#27ae60" : "#d35400"
                border.width: 1

                Text {
                    id: promptText
                    anchors.centerIn: parent
                    text: "PRESS ENTER / CLICK TO PROCEED"
                    color: root.isWin ? "#2ecc71" : "#f39c12"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 550; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 550; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }

    // Input handlers (Enter, Return, Space, or Mouse Click)
    MouseArea {
        anchors.fill: parent
        onClicked: root.continueRequested()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.continueRequested()
            event.accepted = true
        }
    }

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
        }
    }
}
