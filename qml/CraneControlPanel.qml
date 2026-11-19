import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CraneControlPanel.qml provides the interactive crane interface
 * in the Cargo Warehouse for Project VANGUARD Level 1.
 */
Rectangle {
    id: root
    width: 640
    height: 520
    color: "#e610141d"
    border.color: "#00e5ff"
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
                    text: "CARGO WAREHOUSE // OVERHEAD CRANE CONSOLE"
                    color: "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "REPOSITION 3 CARGO CONTAINERS INTO TARGET DESIGNATION BAYS"
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

        // Status Readout Bar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#1b4d3e" : "#1a252f"
            border.color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#34495e"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Text {
                    text: {
                        if (!root.puzzleManager) return ""
                        if (root.puzzleManager.craneSolved) return "SYSTEM STATUS: ALIGNED // PATHWAY CLEARED [KEY B UNLOCKED]"
                        if (root.puzzleManager.craneGrabbed > 0) {
                            var name = (root.puzzleManager.craneGrabbed === 1) ? "ALPHA-1 (RED)" :
                                       (root.puzzleManager.craneGrabbed === 2) ? "BETA-2 (BLUE)" : "GAMMA-3 (YELLOW)"
                            return "HOIST STATUS: HOLDING CONTAINER [" + name + "] — SELECT AN EMPTY BAY TO DEPOSIT"
                        }
                        return "HOIST STATUS: IDLE — SELECT A BAY WITH A CONTAINER TO LIFT"
                    }
                    color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#00e5ff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "TARGET MATCHES: " + (root.puzzleManager ? root.puzzleManager.craneMatchedCount : 0) + " / 3"
                    color: (root.puzzleManager && root.puzzleManager.craneMatchedCount === 3) ? "#2ecc71" : "#f39c12"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // 6-Bay Staging Grid (2 rows x 3 cols)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 14
            columnSpacing: 14

            Repeater {
                model: 6
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: bayBox

                    readonly property int bayIndex: index
                    readonly property int containerId: (root.puzzleManager && root.puzzleManager.craneBays.length > index)
                                                        ? root.puzzleManager.craneBays[index] : 0
                    readonly property bool isSelected: root.puzzleManager && root.puzzleManager.craneSelectedBay === index
                    readonly property int targetContainerId: (index === 3) ? 1 : ((index === 1) ? 2 : ((index === 5) ? 3 : 0))
                    readonly property bool isMatched: (containerId > 0 && containerId === targetContainerId)

                    color: isSelected ? "#243342" : "#151922"
                    border.color: isMatched ? "#2ecc71" : (isSelected ? "#00e5ff" : (targetContainerId > 0 ? "#e67e22" : "#34495e"))
                    border.width: isSelected ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        // Bay Label & Target indicator
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "BAY 0" + (bayBox.bayIndex + 1)
                                color: "#95a5a6"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: bayBox.targetContainerId > 0
                                text: "TARGET: " + (bayBox.targetContainerId === 1 ? "ALPHA" : (bayBox.targetContainerId === 2 ? "BETA" : "GAMMA"))
                                color: bayBox.isMatched ? "#2ecc71" : "#e67e22"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        // Container Visual Representation
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: {
                                if (bayBox.containerId === 1) return "#c0392b" // Red Alpha
                                if (bayBox.containerId === 2) return "#2980b9" // Blue Beta
                                if (bayBox.containerId === 3) return "#f39c12" // Yellow Gamma
                                return "transparent"
                            }
                            border.color: bayBox.containerId > 0 ? "#ffffff" : "transparent"
                            border.width: bayBox.containerId > 0 ? 1 : 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: bayBox.containerId > 0
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: (bayBox.containerId === 1) ? "[ALPHA-1]" :
                                          (bayBox.containerId === 2) ? "[BETA-2]" : "[GAMMA-3]"
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: bayBox.isMatched ? "VERIFIED" : "MISALIGNED"
                                    color: bayBox.isMatched ? "#2ecc71" : "#ffeaa7"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: bayBox.containerId === 0
                                text: bayBox.targetContainerId > 0 ? "[RESERVED SLOT]" : "[EMPTY]"
                                color: bayBox.targetContainerId > 0 ? "#e67e22" : "#4a5568"
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.puzzleManager) {
                                root.puzzleManager.selectCraneBay(bayBox.bayIndex)
                            }
                        }
                    }
                }
            }
        }

        // Action Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Hoist Grab / Release Button
            Button {
                Layout.fillWidth: true
                height: 42
                enabled: root.puzzleManager && !root.puzzleManager.craneSolved
                contentItem: Text {
                    text: {
                        if (!root.puzzleManager) return ""
                        return (root.puzzleManager.craneGrabbed > 0)
                            ? "[ENGAGE CRANE HOIST: LOWER CONTAINER]"
                            : "[ENGAGE CRANE HOIST: LIFT CONTAINER]"
                    }
                    color: root.puzzleManager && !root.puzzleManager.craneSolved ? "#ffffff" : "#7f8c8d"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#16a085" : (parent.hovered ? "#00b4d8" : "#0077b6")
                    border.color: "#00e5ff"
                    border.width: 1
                }
                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.grabOrReleaseCrane()
                    }
                }
            }

            // Reset Staging Button
            Button {
                width: 140
                height: 42
                enabled: root.puzzleManager && !root.puzzleManager.craneSolved
                contentItem: Text {
                    text: "[RESET STAGING]"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.down ? "#7f8c8d" : (parent.hovered ? "#4b6584" : "#2d3436")
                    border.color: "#7f8c8d"
                    border.width: 1
                }
                onClicked: {
                    if (root.puzzleManager) {
                        root.puzzleManager.resetCrane()
                    }
                }
            }
        }
    }
}
