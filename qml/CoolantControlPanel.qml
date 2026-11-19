import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CoolantControlPanel.qml provides the 3-valve coolant regulation interface
 * in the Maintenance & Utilities wing for Project VANGUARD Level 1.
 */
Rectangle {
    id: root
    width: 640
    height: 560
    color: "#e610141d"
    border.color: (root.puzzleManager && root.puzzleManager.coolantSolved) ? "#f1c40f" : "#00e5ff"
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
                    text: "MAINTENANCE & POWER // COOLANT REGULATION CONSOLE"
                    color: (root.puzzleManager && root.puzzleManager.coolantSolved) ? "#f1c40f" : "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "BALANCE COOLANT MANIFOLD VALVES TO RESTORE BACKUP GENERATOR"
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

        // Live Simulated Metrics (Dual Gauge Bars)
        Rectangle {
            Layout.fillWidth: true
            height: 120
            color: "#0c0f17"
            border.color: "#2c3e50"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // 1. Coolant Flow Metric
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "COOLANT FLOW RATE:"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: (root.puzzleManager ? root.puzzleManager.systemFlow.toFixed(1) : "20.0") + " L/min"
                            color: (root.puzzleManager && root.puzzleManager.flowInRange) ? "#2ecc71" : "#e74c3c"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "[TARGET RANGE: 70.0 - 80.0 L/min]"
                            color: (root.puzzleManager && root.puzzleManager.flowInRange) ? "#2ecc71" : "#f39c12"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // Flow Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 14
                        color: "#18202c"
                        border.color: "#34495e"
                        border.width: 1

                        // Target Range Indicator
                        Rectangle {
                            x: parent.width * (70.0 / 120.0)
                            width: parent.width * (10.0 / 120.0)
                            height: parent.height
                            color: "#2ecc71"
                            opacity: 0.35
                        }

                        // Current Value Fill
                        Rectangle {
                            width: Math.min(parent.width, Math.max(0, parent.width * ((root.puzzleManager ? root.puzzleManager.systemFlow : 20.0) / 120.0)))
                            height: parent.height
                            color: (root.puzzleManager && root.puzzleManager.flowInRange) ? "#2ecc71" : "#3498db"
                        }
                    }
                }

                // 2. Core Pressure Metric
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CORE PRESSURE:"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: (root.puzzleManager ? root.puzzleManager.corePressure.toFixed(1) : "180.0") + " PSI"
                            color: (root.puzzleManager && root.puzzleManager.pressureInRange) ? "#2ecc71" : "#e74c3c"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "[TARGET RANGE: 95.0 - 105.0 PSI]"
                            color: (root.puzzleManager && root.puzzleManager.pressureInRange) ? "#2ecc71" : "#f39c12"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // Pressure Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 14
                        color: "#18202c"
                        border.color: "#34495e"
                        border.width: 1

                        // Target Range Indicator
                        Rectangle {
                            x: parent.width * (95.0 / 220.0)
                            width: parent.width * (10.0 / 220.0)
                            height: parent.height
                            color: "#2ecc71"
                            opacity: 0.35
                        }

                        // Current Value Fill
                        Rectangle {
                            width: Math.min(parent.width, Math.max(0, parent.width * ((root.puzzleManager ? root.puzzleManager.corePressure : 180.0) / 220.0)))
                            height: parent.height
                            color: (root.puzzleManager && root.puzzleManager.pressureInRange) ? "#2ecc71" : "#e74c3c"
                        }
                    }
                }
            }
        }

        // 3 Interactive Valve Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Valve 1: Cryo Feed Bypass
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#131722"
                border.color: "#34495e"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text { text: "VALVE 01"; color: "#00e5ff"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "CRYO FEED BYPASS"; color: "#95a5a6"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "(+20 FLOW / -15 PSI)"; color: "#7f8c8d"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }

                    Item { Layout.fillHeight: true }

                    // Setting Indicator (0..3)
                    Rectangle {
                        width: 70; height: 50
                        Layout.alignment: Qt.AlignHCenter
                        color: "#0a0d14"
                        border.color: "#00e5ff"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "LVL " + (root.puzzleManager ? root.puzzleManager.valve1 : 0)
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        Layout.fillWidth: true
                        height: 36
                        enabled: root.puzzleManager && !root.puzzleManager.coolantSolved
                        contentItem: Text { text: "[CYCLE VALVE 1]"; color: "#ffffff"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.down ? "#0077b6" : (parent.hovered ? "#1b2838" : "#18202c"); border.color: "#00e5ff"; border.width: 1 }
                        onClicked: { if (root.puzzleManager) root.puzzleManager.cycleValve(1) }
                    }
                }
            }

            // Valve 2: Primary Radiator Pump
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#131722"
                border.color: "#34495e"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text { text: "VALVE 02"; color: "#00e5ff"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "RADIATOR PUMP"; color: "#95a5a6"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "(+25 FLOW / +10 PSI)"; color: "#7f8c8d"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }

                    Item { Layout.fillHeight: true }

                    // Setting Indicator (0..3)
                    Rectangle {
                        width: 70; height: 50
                        Layout.alignment: Qt.AlignHCenter
                        color: "#0a0d14"
                        border.color: "#00e5ff"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "LVL " + (root.puzzleManager ? root.puzzleManager.valve2 : 0)
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        Layout.fillWidth: true
                        height: 36
                        enabled: root.puzzleManager && !root.puzzleManager.coolantSolved
                        contentItem: Text { text: "[CYCLE VALVE 2]"; color: "#ffffff"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.down ? "#0077b6" : (parent.hovered ? "#1b2838" : "#18202c"); border.color: "#00e5ff"; border.width: 1 }
                        onClicked: { if (root.puzzleManager) root.puzzleManager.cycleValve(2) }
                    }
                }
            }

            // Valve 3: Relief Exhaust
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#131722"
                border.color: "#34495e"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text { text: "VALVE 03"; color: "#00e5ff"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "PRESSURE RELIEF"; color: "#95a5a6"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "(-5 FLOW / -30 PSI)"; color: "#7f8c8d"; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }

                    Item { Layout.fillHeight: true }

                    // Setting Indicator (0..3)
                    Rectangle {
                        width: 70; height: 50
                        Layout.alignment: Qt.AlignHCenter
                        color: "#0a0d14"
                        border.color: "#00e5ff"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "LVL " + (root.puzzleManager ? root.puzzleManager.valve3 : 0)
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        Layout.fillWidth: true
                        height: 36
                        enabled: root.puzzleManager && !root.puzzleManager.coolantSolved
                        contentItem: Text { text: "[CYCLE VALVE 3]"; color: "#ffffff"; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.down ? "#0077b6" : (parent.hovered ? "#1b2838" : "#18202c"); border.color: "#00e5ff"; border.width: 1 }
                        onClicked: { if (root.puzzleManager) root.puzzleManager.cycleValve(3) }
                    }
                }
            }
        }

        // Action / Reset Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: (root.puzzleManager && root.puzzleManager.coolantSolved)
                      ? "SYSTEM STATUS: GENERATOR SYNCHRONIZED [KEY A UNLOCKED]"
                      : "ADJUST VALVES UNTIL BOTH FLOW AND PRESSURE REACH GREEN TARGET ZONES"
                color: (root.puzzleManager && root.puzzleManager.coolantSolved) ? "#2ecc71" : "#95a5a6"
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Reset Valves Button
            Button {
                width: 140
                height: 38
                enabled: root.puzzleManager && !root.puzzleManager.coolantSolved
                contentItem: Text {
                    text: "[RESET VALVES]"
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
                        root.puzzleManager.resetCoolant()
                    }
                }
            }
        }
    }
}
