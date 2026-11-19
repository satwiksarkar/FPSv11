import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief SecurityTerminal.qml provides the 4-digit keypad terminal
 * in the Administration Block for Project VANGUARD Level 1.
 */
Rectangle {
    id: root
    width: 480
    height: 540
    color: "#e610141d"
    border.color: (root.puzzleManager && root.puzzleManager.securityErrorFlash) ? "#e74c3c" : "#00e5ff"
    border.width: 2
    radius: 4

    property var puzzleManager: null
    signal closeRequested()

    MouseArea {
        anchors.fill: parent
        // Prevent click-through
        onClicked: {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text {
                    text: "ADMIN RECORDS // SECURITY KEYPAD"
                    color: "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "RESTRICTED VAULT SECURITY OVERRIDE SYSTEM"
                    color: "#95a5a6"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            // Close Button
            Rectangle {
                width: 32
                height: 32
                color: closeBtnMouse.containsMouse ? "#e74c3c" : "#2c3e50"
                border.color: "#7f8c8d"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "X"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 14
                }

                MouseArea {
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // Passcode Digital Display
        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: "#0a0d14"
            border.color: (root.puzzleManager && root.puzzleManager.securityErrorFlash) ? "#e74c3c" :
                          ((root.puzzleManager && root.puzzleManager.securitySolved) ? "#2ecc71" : "#1b3a4b")
            border.width: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                // 4 Digit Boxes
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 36
                            height: 38
                            color: "#151922"
                            border.color: (root.puzzleManager && root.puzzleManager.securitySolved) ? "#2ecc71" : "#00e5ff"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!root.puzzleManager) return "_"
                                    var code = root.puzzleManager.securityEnteredCode
                                    if (index < code.length) {
                                        return code.charAt(index)
                                    }
                                    return "_"
                                }
                                color: (root.puzzleManager && root.puzzleManager.securitySolved) ? "#2ecc71" : "#00e5ff"
                                font.pixelSize: 22
                                font.bold: true
                            }
                        }
                    }
                }

                // Status Message
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!root.puzzleManager) return ""
                        if (root.puzzleManager.securitySolved) return "VAULT ACCESS GRANTED [KEY D UNLOCKED]"
                        if (root.puzzleManager.securityStatusMessage.length > 0) return root.puzzleManager.securityStatusMessage
                        return "ENTER 4-DIGIT AUTHORIZATION OVERRIDE"
                    }
                    color: {
                        if (!root.puzzleManager) return "#95a5a6"
                        if (root.puzzleManager.securitySolved) return "#2ecc71"
                        if (root.puzzleManager.securityErrorFlash) return "#e74c3c"
                        return "#95a5a6"
                    }
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }
            }
        }

        // Keypad Grid (3 columns x 4 rows)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 10
            columnSpacing: 10

            // Digits 1-9
            Repeater {
                model: [
                    { label: "1", val: "1" },
                    { label: "2", val: "2" },
                    { label: "3", val: "3" },
                    { label: "4", val: "4" },
                    { label: "5", val: "5" },
                    { label: "6", val: "6" },
                    { label: "7", val: "7" },
                    { label: "8", val: "8" },
                    { label: "9", val: "9" }
                ]

                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    enabled: root.puzzleManager && !root.puzzleManager.securitySolved
                    contentItem: Text {
                        text: modelData.label
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.down ? "#0077b6" : (parent.hovered ? "#1b2838" : "#18202c")
                        border.color: parent.hovered ? "#00e5ff" : "#34495e"
                        border.width: 1
                    }
                    onClicked: {
                        if (root.puzzleManager) {
                            root.puzzleManager.enterSecurityDigit(modelData.val)
                        }
                    }
                }
            }

            // Bottom row: CLEAR, 0, ENTER
            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.puzzleManager && !root.puzzleManager.securitySolved
                contentItem: Text {
                    text: "[CLEAR]"
                    color: "#e74c3c"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#4a1212" : (parent.hovered ? "#2c1818" : "#1c1414")
                    border.color: parent.hovered ? "#e74c3c" : "#7f1d1d"
                    border.width: 1
                }
                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.clearSecurityCode()
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.puzzleManager && !root.puzzleManager.securitySolved
                contentItem: Text {
                    text: "0"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#0077b6" : (parent.hovered ? "#1b2838" : "#18202c")
                    border.color: parent.hovered ? "#00e5ff" : "#34495e"
                    border.width: 1
                }
                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.enterSecurityDigit("0")
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.puzzleManager && !root.puzzleManager.securitySolved
                contentItem: Text {
                    text: "[ENTER]"
                    color: "#2ecc71"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#16a085" : (parent.hovered ? "#143a28" : "#11261b")
                    border.color: parent.hovered ? "#2ecc71" : "#1b5e20"
                    border.width: 1
                }
                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.submitSecurityCode()
                    }
                }
            }
        }

        // Environmental Clue Hint Banner
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#131b26"
            border.color: "#2c3e50"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Rectangle { width: 6; height: 6; color: "#f39c12" }

                Text {
                    text: "PASSCODE CLUE LOGGED IN SUPERVISOR DIRECTIVE MEMO (DESK AT ROW 64, COL 8)"
                    color: "#f39c12"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }
    }
}
