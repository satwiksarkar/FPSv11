import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CargoManifestPanel.qml provides the interactive Sphinx Riddle Terminal
 * for the Key 1 Vault in Project VANGUARD Level 1.
 */
Rectangle {
    id: root
    width: 720
    height: 560
    color: "#e60a1017"
    border.color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00e5ff"
    border.width: 2
    radius: 6

    property var puzzleManager: null
    signal closeRequested()

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        // Terminal Top Banner
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 14
                height: 14
                radius: 3
                color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00e5ff"
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "SECTOR K1 // VAULT SECURITY TERMINAL"
                    color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                Text {
                    text: "SPHINX PROTOCOL — COGNITIVE DECRYPTION GATEWAY"
                    color: "#7f8c8d"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            // Close button
            Rectangle {
                width: 32
                height: 32
                color: closeBtnMouse.containsMouse ? "#e74c3c" : "#1b2631"
                border.color: "#34495e"
                border.width: 1
                radius: 3

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

        // Terminal CRT Screen Display Box
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#05090f"
            border.color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#27ae60" : "#1a3644"
            border.width: 1.5
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // CRT Query Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 115
                    color: "#0a131c"
                    border.color: "#00e5ff"
                    border.width: 1
                    radius: 3

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            text: "> SECURITY CLEARANCE CHALLENGE // VANGUARD RIDDLE ARCHIVE:"
                            color: "#00e5ff"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: root.puzzleManager ? ("\"" + root.puzzleManager.currentRiddleText + "\"") : "INITIALIZING SECURITY ARCHIVE..."
                            color: "#ecf0f1"
                            font.pixelSize: 14
                            font.bold: true
                            font.italic: true
                            lineHeight: 1.3
                        }
                    }
                }

                Text {
                    text: "SELECT VERIFIED COGNITIVE RESPONSE:"
                    color: "#f39c12"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                // Four Interactive Candidate Options
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.puzzleManager ? root.puzzleManager.currentRiddleOptions : []

                        delegate: Rectangle {
                            id: optCard
                            Layout.fillWidth: true
                            height: 42
                            readonly property int optIndex: index
                            readonly property bool isSelected: root.puzzleManager ? (root.puzzleManager.selectedRiddleOption === optIndex) : false
                            readonly property bool isSolved: root.puzzleManager && root.puzzleManager.riddleSolved

                            color: isSolved && isSelected
                                ? "#163a2b"
                                : (isSelected ? "#133140" : (optMouse.containsMouse ? "#101d28" : "#0c151e"))
                            border.color: isSolved && isSelected
                                ? "#2ecc71"
                                : (isSelected ? "#00e5ff" : "#1f2d3d")
                            border.width: isSelected || (isSolved && isSelected) ? 2 : 1
                            radius: 3

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                // Radio indicator
                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: optCard.isSelected ? "#00e5ff" : "transparent"
                                    border.color: optCard.isSelected ? "#00e5ff" : "#566573"
                                    border.width: 1.5

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: optCard.isSolved ? "#2ecc71" : "#ffffff"
                                        visible: optCard.isSelected
                                    }
                                }

                                Text {
                                    readonly property var letters: ["A", "B", "C", "D"]
                                    text: (optIndex < 4 ? letters[optIndex] : "?") + ") "
                                    color: optCard.isSelected ? "#00e5ff" : "#7f8c8d"
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData
                                    color: (optCard.isSolved && optCard.isSelected)
                                        ? "#2ecc71"
                                        : (optCard.isSelected ? "#ffffff" : "#bdc3c7")
                                    font.pixelSize: 13
                                    font.bold: optCard.isSelected
                                }
                            }

                            MouseArea {
                                id: optMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.puzzleManager && !root.puzzleManager.riddleSolved) {
                                        root.puzzleManager.selectRiddleOption(optCard.optIndex)
                                    }
                                }
                            }
                        }
                    }
                }

                // Dynamic Status & Error Feedback
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: (root.puzzleManager && root.puzzleManager.riddleSolved)
                        ? "#142c1f"
                        : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#2b1417" : "#0a131c")
                    border.color: (root.puzzleManager && root.puzzleManager.riddleSolved)
                        ? "#2ecc71"
                        : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#e74c3c" : "#1b2c3a")
                    border.width: 1
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: (root.puzzleManager && root.puzzleManager.riddleSolved)
                                ? "#2ecc71"
                                : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#e74c3c" : "#00e5ff")
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0) {
                                    return root.puzzleManager.riddleFeedback
                                }
                                if (root.puzzleManager && root.puzzleManager.riddleSolved) {
                                    return "VAULT DOOR UNLOCKED: ACCESS KEY 1 CHAMBER ACCESSIBLE."
                                }
                                return "AWAITING SELECTION: Choose correct answer and execute decryption."
                            }
                            color: (root.puzzleManager && root.puzzleManager.riddleSolved)
                                ? "#2ecc71"
                                : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#e74c3c" : "#7f8c8d")
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Action Buttons Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                height: 44
                enabled: root.puzzleManager ? (!root.puzzleManager.riddleSolved && root.puzzleManager.selectedRiddleOption >= 0) : false

                background: Rectangle {
                    color: parent.enabled
                        ? (parent.down ? "#16a085" : (parent.hovered ? "#00c4cc" : "#0097a7"))
                        : "#1c2833"
                    border.color: parent.enabled ? "#00e5ff" : "#2c3e50"
                    border.width: 1.5
                    radius: 3
                }

                contentItem: Text {
                    text: (root.puzzleManager && root.puzzleManager.riddleSolved)
                        ? "DECRYPTION COMPLETE // VAULT UNLOCKED"
                        : "EXECUTE DECRYPTION [SUBMIT]"
                    color: parent.enabled ? "#ffffff" : "#7f8c8d"
                    font.bold: true
                    font.pixelSize: 13
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.submitRiddleAnswer()
                    }
                }
            }

            Button {
                width: 150
                height: 44
                background: Rectangle {
                    color: parent.down ? "#151e27" : (parent.hovered ? "#2c3e50" : "#1f2a36")
                    border.color: "#566573"
                    border.width: 1
                    radius: 3
                }
                contentItem: Text {
                    text: "DISCONNECT [ESC]"
                    color: "#ecf0f1"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.closeRequested()
            }
        }
    }
}
