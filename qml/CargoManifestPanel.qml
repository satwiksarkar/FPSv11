import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CargoManifestPanel.qml provides the interactive Security Riddle Terminal
 * in the Cargo Warehouse for Project VANGUARD Level 1 (replacing the crane puzzle).
 */
Rectangle {
    id: root
    width: 680
    height: 580
    color: "#e610141d"
    border.color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#00e5ff"
    border.width: 2
    radius: 4

    property var puzzleManager: null
    signal closeRequested()

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text {
                    text: "CARGO WAREHOUSE // SECURITY RIDDLE ARCHIVE"
                    color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "SPHINX PROTOCOL — COGNITIVE SECURITY ACCESS CHALLENGE"
                    color: "#95a5a6"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

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

        // Warehouse Office Clue Status Strip
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: (root.puzzleManager && root.puzzleManager.manifestClueFound) ? "#16281e" : "#1a252f"
            border.color: (root.puzzleManager && root.puzzleManager.manifestClueFound) ? "#2ecc71" : "#34495e"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    width: 10
                    height: 10
                    radius: 2
                    color: (root.puzzleManager && root.puzzleManager.manifestClueFound) ? "#2ecc71" : "#f39c12"
                }

                Text {
                    text: (root.puzzleManager && root.puzzleManager.manifestClueFound)
                        ? "LOGISTICS MEMO #402-V RECOVERED: The Chief Engineer's clue points to heavy transmission parts."
                        : "OPTIONAL CLUE: Logistics Directive #402-V is available on the office desk at (1950, 850)."
                    color: (root.puzzleManager && root.puzzleManager.manifestClueFound) ? "#2ecc71" : "#bdc3c7"
                    font.pixelSize: 11
                }
            }
        }

        // Terminal Riddle Screen Box
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0a0e14"
            border.color: "#34495e"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // CRT Inscribed Riddle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 125
                    color: "#0f171e"
                    border.color: "#00e5ff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Text {
                            text: "LOGISTICS SECURITY ARCHIVE // ANCIENT TECHNICIAN'S RIDDLE:"
                            color: "#00e5ff"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "\"I have teeth that never bite,\n I turn in darkness day and night.\n I drive the iron, winch, and gear,\n Name my core to enter here.\""
                            color: "#ecf0f1"
                            font.pixelSize: 14
                            font.bold: true
                            font.italic: true
                            lineHeight: 1.3
                        }
                    }
                }

                Text {
                    text: "SELECT THE CORRECT FACILITY IDENTITY:"
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
                        model: [
                            { id: 0, text: "A) THE DRIVE GEAR  —  Rotates mechanical winches, conveyors & gear trains" },
                            { id: 1, text: "B) THE COOLANT PUMP — Circulates chilled fluorocarbon through heat sinks" },
                            { id: 2, text: "C) THE PLASMA RELAY — Directs high-voltage energy to containment fields" },
                            { id: 3, text: "D) THE TURBINE ROTOR — Spins generators to maintain auxiliary power" }
                        ]

                        delegate: Rectangle {
                            id: optCard
                            Layout.fillWidth: true
                            height: 40
                            readonly property bool isSelected: root.puzzleManager ? (root.puzzleManager.selectedRiddleOption === modelData.id) : false
                            readonly property bool isSolved: root.puzzleManager && root.puzzleManager.craneSolved

                            color: isSolved && modelData.id === 0
                                ? "#1b4d3e"
                                : (isSelected ? "#1a3a4a" : (optMouse.containsMouse ? "#1c2630" : "#131b24"))
                            border.color: isSolved && modelData.id === 0
                                ? "#2ecc71"
                                : (isSelected ? "#00e5ff" : "#2c3e50")
                            border.width: isSelected || (isSolved && modelData.id === 0) ? 2 : 1
                            radius: 2

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: optCard.isSelected || (optCard.isSolved && modelData.id === 0) ? "#00e5ff" : "transparent"
                                    border.color: optCard.isSelected || (optCard.isSolved && modelData.id === 0) ? "#00e5ff" : "#7f8c8d"
                                    border.width: 1.5

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: optCard.isSolved && modelData.id === 0 ? "#2ecc71" : "#ffffff"
                                        visible: optCard.isSelected || (optCard.isSolved && modelData.id === 0)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    color: (optCard.isSolved && modelData.id === 0)
                                        ? "#2ecc71"
                                        : (optCard.isSelected ? "#00e5ff" : "#ecf0f1")
                                    font.pixelSize: 12
                                    font.bold: optCard.isSelected || (optCard.isSolved && modelData.id === 0)
                                }
                            }

                            MouseArea {
                                id: optMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.puzzleManager && !root.puzzleManager.craneSolved) {
                                        root.puzzleManager.selectRiddleOption(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // Dynamic Status & Error Feedback
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: (root.puzzleManager && root.puzzleManager.craneSolved)
                        ? "#16281e"
                        : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#2c1517" : "#10161d")
                    border.color: (root.puzzleManager && root.puzzleManager.craneSolved)
                        ? "#2ecc71"
                        : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#e74c3c" : "#2c3e50")
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (root.puzzleManager && root.puzzleManager.craneSolved) {
                                return "STATUS: ACCESS GRANTED // K1 CHAMBER BARRIER DISENGAGED"
                            }
                            if (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0) {
                                return root.puzzleManager.riddleFeedback
                            }
                            return "SELECT AN OPTION AND SUBMIT TO ATTEMPT COGNITIVE OVERRIDE"
                        }
                        color: (root.puzzleManager && root.puzzleManager.craneSolved)
                            ? "#2ecc71"
                            : (root.puzzleManager && root.puzzleManager.riddleFeedback.length > 0 ? "#e74c3c" : "#7f8c8d")
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // Bottom Action Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                height: 42
                enabled: root.puzzleManager ? (!root.puzzleManager.craneSolved && root.puzzleManager.selectedRiddleOption >= 0) : false

                background: Rectangle {
                    color: parent.enabled
                        ? (parent.down ? "#16a085" : (parent.hovered ? "#00adb5" : "#00838f"))
                        : "#2c3e50"
                    border.color: parent.enabled ? "#00e5ff" : "#34495e"
                    border.width: 1
                    radius: 2
                }

                contentItem: Text {
                    text: (root.puzzleManager && root.puzzleManager.craneSolved) ? "RIDDLE SOLVED [ACCESS KEY B READY]" : "SUBMIT RIDDLE ANSWER"
                    color: parent.enabled ? "#ffffff" : "#7f8c8d"
                    font.bold: true
                    font.pixelSize: 13
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
                width: 130
                height: 42
                background: Rectangle {
                    color: parent.down ? "#1a252f" : (parent.hovered ? "#34495e" : "#2c3e50")
                    border.color: "#7f8c8d"
                    border.width: 1
                    radius: 2
                }
                contentItem: Text {
                    text: "CLOSE [ESC]"
                    color: "#ffffff"
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
