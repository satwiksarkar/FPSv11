import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief AdminClueDialog.qml displays the environmental directive memo
 * on the supervisor's desk in the Administration Block for Level 1.
 */
Rectangle {
    id: root
    width: 520
    height: 380
    color: "#e610141d"
    border.color: "#f39c12"
    border.width: 2
    radius: 4

    signal closeRequested()

    MouseArea {
        anchors.fill: parent
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
                    text: "ADMIN ARCHIVE // DIRECTIVE MEMORANDUM"
                    color: "#f39c12"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "FOUNDRY SEVEN // INTERNAL SECURITY DIRECTIVE #5824-A"
                    color: "#95a5a6"
                    font.pixelSize: 10
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 30
                height: 30
                color: closeBtnMouse.containsMouse ? "#e74c3c" : "#2c3e50"
                border.color: "#7f8c8d"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "X"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 13
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

        // Memo Content Box
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0a0d14"
            border.color: "#34495e"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "CLASSIFIED // FOR SECTOR SUPERVISORS ONLY"
                    color: "#e74c3c"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Following anomalous behavior in the VANGUARD core neural net, automated security has sealed the Administration Records Vault containing Fabrication Key D.\n\n" +
                          "The emergency manual keypad override has been set to the Facility Sector designation followed by the Vault Bay number:\n\n" +
                          "   • Sector Designation: 58\n" +
                          "   • Records Vault Bay:  24\n\n" +
                          "Enter [ 5 8 2 4 ] on the vault security keypad located outside the restricted records room at row 70."
                    color: "#ecf0f1"
                    font.pixelSize: 12
                    lineHeight: 1.3
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "#1e272e"
                    Text {
                        anchors.centerIn: parent
                        text: "KEYPAD OVERRIDE CODE: 5824"
                        color: "#2ecc71"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
            }
        }

        // Close Button
        Button {
            Layout.fillWidth: true
            height: 38
            contentItem: Text {
                text: "[ACKNOWLEDGE & CLOSE]"
                color: "#ffffff"
                font.bold: true
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.down ? "#d35400" : (parent.hovered ? "#e67e22" : "#b33939")
                border.color: "#f39c12"
                border.width: 1
            }
            onClicked: root.closeRequested()
        }
    }
}
