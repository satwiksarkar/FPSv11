import QtQuick
import QtQuick.Controls

/**
 * @brief StoryScreen.qml displays the Project VANGUARD narrative and mission briefing.
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
        width: Math.min(880, parent.width - 32)
        height: Math.min(640, parent.height - 32)
        color: "#0c0e14"
        border.color: root.isWin ? "#2ecc71" : "#e67e22"
        border.width: 2
        radius: 0 // Hard pixel corners

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

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
                    text: root.isWin ? "SYSTEM TRANSMISSION // OVERRIDE COMPLETE" : "SECURE TERMINAL // MISSION OPERATIONAL DIRECTIVE"
                    color: root.isWin ? "#2ecc71" : "#f39c12"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2
                }
            }

            // Level / Mission Title
            Text {
                text: root.title
                color: "#ffffff"
                font.pixelSize: 24
                font.bold: true
                font.letterSpacing: 1
            }

            // Decorative separator line
            Rectangle {
                width: parent.width
                height: 1
                color: "#282c37"
            }

            // Mission Story & Operational Instructions Content
            Flickable {
                id: flickArea
                width: parent.width
                height: parent.height - 180
                contentWidth: width
                contentHeight: storyContentText.paintedHeight + 20
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

                Text {
                    id: storyContentText
                    width: parent.width - 20
                    text: root.storyText
                    color: "#d0d4dc"
                    font.pixelSize: 14
                    lineHeight: 1.45
                    wrapMode: Text.WordWrap
                }
            }

            // Bottom Continue Prompt Button
            Button {
                id: btnProceed
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: root.isWin ? "RETURN TO MAIN MENU [ENTER]" : "▶  BEGIN MISSION [ENTER]"
                    color: root.isWin ? "#2ecc71" : (btnProceed.hovered ? "#ffffff" : "#f39c12")
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.5
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnProceed.down ? "#7e3c00" : (btnProceed.hovered ? "#d35400" : "#181b24")
                    border.color: root.isWin ? "#2ecc71" : "#e67e22"
                    border.width: 2
                }
                onClicked: root.continueRequested()
            }
        }
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
