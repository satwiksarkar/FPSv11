import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CircuitPuzzle.qml provides the rotatable 3x3 power routing puzzle
 * in the Research Laboratories for Project VANGUARD Level 1.
 */
Rectangle {
    id: root
    width: 600
    height: 580
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
                    text: "RESEARCH LABS // POWER ROUTING TERMINAL"
                    color: "#00e5ff"
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "ROTATE CONDUITS TO ROUTE AUXILIARY POWER [IN] TO CONTAINMENT CHAMBER [OUT]"
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
            height: 36
            color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#1b4d3e" : "#1a252f"
            border.color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#34495e"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Text {
                    text: (root.puzzleManager && root.puzzleManager.powerSolved)
                          ? "CIRCUIT STATUS: BUS ENERGIZED // CONTAINMENT OPEN [KEY C UNLOCKED]"
                          : "CIRCUIT STATUS: OPEN LOOP // TRACE CONTINUOUS ELECTRICAL PATH"
                    color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00e5ff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: (root.puzzleManager && root.puzzleManager.powerSolved) ? "CONTINUITY: 100%" : "CONTINUITY: BROKEN"
                    color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#e74c3c"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // Circuit Canvas Area with IN / OUT indicators
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Power IN Badge (West)
            Rectangle {
                width: 44
                height: 60
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 28
                color: "#0077b6"
                border.color: "#00e5ff"
                border.width: 1
                Column {
                    anchors.centerIn: parent
                    Text { text: "PWR"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "IN"; color: "#00e5ff"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: ">>>"; color: "#ffffff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            // 3x3 Circuit Grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: 9
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: tileBox

                        readonly property int tileIndex: index
                        readonly property int rot: (root.puzzleManager && root.puzzleManager.circuitRotations.length > index)
                                                    ? root.puzzleManager.circuitRotations[index] : 0
                        readonly property bool isEnergized: (root.puzzleManager && root.puzzleManager.circuitEnergized.length > index)
                                                            ? root.puzzleManager.circuitEnergized[index] : false

                        color: isEnergized ? "#102a38" : "#131722"
                        border.color: isEnergized ? "#00e5ff" : (tileMouse.containsMouse ? "#4b6584" : "#2d3436")
                        border.width: isEnergized ? 2 : 1

                        // Rotating Wire Graphic
                        Item {
                            anchors.centerIn: parent
                            width: 70
                            height: 70
                            rotation: tileBox.rot

                            Behavior on rotation {
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }

                            // Center junction hub
                            Rectangle {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                color: tileBox.isEnergized ? "#00e5ff" : "#4a5568"
                                radius: 2
                            }

                            // Base wire types:
                            // 0, 2, 5, 6: Corner (N & E)
                            // 1, 3, 7, 8: Straight (W & E)
                            // 4: T-Junction (W, N, E)
                            readonly property bool hasNorth: (tileBox.tileIndex === 0 || tileBox.tileIndex === 2 || tileBox.tileIndex === 5 || tileBox.tileIndex === 6 || tileBox.tileIndex === 4)
                            readonly property bool hasEast: (tileBox.tileIndex === 0 || tileBox.tileIndex === 1 || tileBox.tileIndex === 2 || tileBox.tileIndex === 3 || tileBox.tileIndex === 4 || tileBox.tileIndex === 5 || tileBox.tileIndex === 6 || tileBox.tileIndex === 7 || tileBox.tileIndex === 8)
                            readonly property bool hasSouth: false // Corner at 0 deg has N|E; straight has W|E
                            readonly property bool hasWest: (tileBox.tileIndex === 1 || tileBox.tileIndex === 3 || tileBox.tileIndex === 4 || tileBox.tileIndex === 7 || tileBox.tileIndex === 8)

                            // North arm
                            Rectangle {
                                visible: tileBox.hasNorth
                                x: 29; y: 0; width: 12; height: 35
                                color: tileBox.isEnergized ? "#00e5ff" : "#4a5568"
                            }
                            // East arm
                            Rectangle {
                                visible: tileBox.hasEast
                                x: 35; y: 29; width: 35; height: 12
                                color: tileBox.isEnergized ? "#00e5ff" : "#4a5568"
                            }
                            // West arm
                            Rectangle {
                                visible: tileBox.hasWest
                                x: 0; y: 29; width: 35; height: 12
                                color: tileBox.isEnergized ? "#00e5ff" : "#4a5568"
                            }
                        }

                        // Rotation Indicator
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 4
                            text: tileBox.rot + "°"
                            color: "#636e72"
                            font.pixelSize: 9
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.puzzleManager && !root.puzzleManager.powerSolved
                            onClicked: {
                                if (root.puzzleManager) {
                                    root.puzzleManager.rotateCircuitTile(tileBox.tileIndex)
                                }
                            }
                        }
                    }
                }
            }

            // Power OUT Badge (East)
            Rectangle {
                width: 44
                height: 60
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 28
                color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#1b4d3e" : "#2d3436"
                border.color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#7f8c8d"
                border.width: 1
                Column {
                    anchors.centerIn: parent
                    Text { text: ">>>"; color: "#ffffff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "BUS"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "OUT"; color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#95a5a6"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }

        // Action Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "CLICK ANY CONDUIT TILE TO ROTATE 90 DEGREES CLOCKWISE"
                color: "#7f8c8d"
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            // Reset Circuit Button
            Button {
                width: 140
                height: 38
                enabled: root.puzzleManager && !root.puzzleManager.powerSolved
                contentItem: Text {
                    text: "[RESET CONDUITS]"
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
                        root.puzzleManager.resetCircuit()
                    }
                }
            }
        }
    }
}
