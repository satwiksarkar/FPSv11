import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief AdminClueDialog.qml displays the environmental directive memos
 * and terminals across Level 1 for Project VANGUARD.
 */
Rectangle {
    id: root
    width: 560
    height: 420
    color: "#e610141d"
    border.color: "#f39c12"
    border.width: 2
    radius: 4

    property var puzzleManager: null
    signal closeRequested()

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    readonly property int clueIndex: puzzleManager ? puzzleManager.activeClueIndex : 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text {
                    text: {
                        if (root.clueIndex === 1) return "ADMIN RECEPTION // SECTOR DIRECTIVE"
                        if (root.clueIndex === 2) return "SUPERVISOR DESK // SECURITY MEMO"
                        if (root.clueIndex === 3) return "ARCHIVE TERMINAL // VAULT INDEX"
                        if (root.clueIndex === 4) return "WAREHOUSE OFFICE // SHIPPING MANIFEST"
                        return "FACILITY DOCUMENT ARCHIVE"
                    }
                    color: "#f39c12"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: {
                        if (root.clueIndex === 1) return "DOCUMENT CLUE 1 OF 3 — FACILITY SECTOR DESIGNATION"
                        if (root.clueIndex === 2) return "DOCUMENT CLUE 2 OF 3 — SECURITY SUB-LEVEL"
                        if (root.clueIndex === 3) return "DOCUMENT CLUE 3 OF 3 — RECORDS VAULT BAY"
                        if (root.clueIndex === 4) return "SHIPPING MANIFEST #804-V // LOGISTICS ROUTING"
                        return "VANGUARD INDUSTRIAL RESEARCH FACILITY"
                    }
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

        // Investigation Progress Indicator Bar
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#151922"
            border.color: "#2c3e50"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 12

                Text {
                    text: "INVESTIGATION PROGRESS:"
                    color: "#95a5a6"
                    font.pixelSize: 9
                    font.bold: true
                }

                Rectangle {
                    width: 70
                    height: 16
                    color: (root.puzzleManager && root.puzzleManager.clue1Found) ? "#27ae60" : "#2c3e50"
                    Text { anchors.centerIn: parent; text: "CLUE 1: " + ((root.puzzleManager && root.puzzleManager.clue1Found) ? "[5]" : "?"); color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                }

                Rectangle {
                    width: 70
                    height: 16
                    color: (root.puzzleManager && root.puzzleManager.clue2Found) ? "#27ae60" : "#2c3e50"
                    Text { anchors.centerIn: parent; text: "CLUE 2: " + ((root.puzzleManager && root.puzzleManager.clue2Found) ? "[8]" : "?"); color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                }

                Rectangle {
                    width: 80
                    height: 16
                    color: (root.puzzleManager && root.puzzleManager.clue3Found) ? "#27ae60" : "#2c3e50"
                    Text { anchors.centerIn: parent; text: "CLUE 3: " + ((root.puzzleManager && root.puzzleManager.clue3Found) ? "[24]" : "?"); color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: (root.puzzleManager && root.puzzleManager.clue1Found && root.puzzleManager.clue2Found && root.puzzleManager.clue3Found)
                          ? "FULL CODE: [ 5 8 2 4 ]"
                          : "SEARCH ADMIN ROOMS FOR CLUES"
                    color: (root.puzzleManager && root.puzzleManager.clue1Found && root.puzzleManager.clue2Found && root.puzzleManager.clue3Found) ? "#2ecc71" : "#f39c12"
                    font.pixelSize: 9
                    font.bold: true
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
                    text: root.clueIndex === 4 ? "WAREHOUSE LOGISTICS RECORD // RESTRICTED ACCESS" : "CLASSIFIED // ADMINISTRATION INVESTIGATION RECORD"
                    color: "#e74c3c"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: {
                        if (root.clueIndex === 1) {
                            return "RECEPTION DESK LOG — MEMORANDUM PART 1:\n\n" +
                                   "Following anomalous behavior in the VANGUARD core neural net, automated security has sealed the Administration Records Vault containing Fabrication Key D.\n\n" +
                                   "The 4-digit keypad override has been partitioned across administrative desks:\n\n" +
                                   "   • FACILITY SECTOR DESIGNATION: [ 5 ]\n\n" +
                                   "Inspect the Supervisor's Desk in the West Office and the Archive Terminal in the South Office to locate the remaining digits."
                        } else if (root.clueIndex === 2) {
                            return "SUPERVISOR DESK — DIRECTIVE #5824-B (MEMORANDUM PART 2):\n\n" +
                                   "Sector Supervisor Directive regarding the restricted records vault:\n\n" +
                                   "   • SECURITY SUB-LEVEL: [ 8 ]\n\n" +
                                   "Combined with the Reception memo [5], the first two digits of the keypad override are confirmed as [ 5 8 ].\n" +
                                   "Refer to the Archive Terminal for the Vault Bay designation."
                        } else if (root.clueIndex === 3) {
                            return "ARCHIVE TERMINAL — VAULT STORAGE CATALOG (MEMORANDUM PART 3):\n\n" +
                                   "Facility Vault Database Query Result:\n\n" +
                                   "   • RECORDS VAULT BAY DESIGNATION: [ 2 4 ]\n\n" +
                                   "The full keypad override sequence is Sector + Sub-Level + Bay:\n" +
                                   "Code: [ 5 8 2 4 ]\n\n" +
                                   "Enter [ 5 8 2 4 ] on the Security Keypad outside the vault door at row 70 to open the chamber."
                        } else if (root.clueIndex === 4) {
                            return "LOGISTICS DIRECTIVE #402-V (SECURITY RIDDLE BRIEFING):\n\n" +
                                   "Following automated lockdown, the Key 1 alcove is guarded by the Chief Engineer's Sphinx Protocol riddle terminal.\n\n" +
                                   "The terminal poses the facility riddle:\n" +
                                   "   \"I have teeth that never bite,\n" +
                                   "    I turn in darkness day and night.\n" +
                                   "    I drive the iron, winch, and gear,\n" +
                                   "    Name my core to enter here.\"\n\n" +
                                   "ENGINEERING OVERRIDE NOTE:\n" +
                                   "   • CORRECT RIDDLE IDENTIFIER: [ THE DRIVE GEAR ]\n\n" +
                                   "Select 'THE DRIVE GEAR' on the security terminal at (850, 950) to disengage the barrier."
                        }
                        return ""
                    }
                    color: "#ecf0f1"
                    font.pixelSize: 12
                    lineHeight: 1.3
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    color: "#1e272e"
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (root.clueIndex === 1) return "CLUE RECORDED: DIGIT 1 = [ 5 ]"
                            if (root.clueIndex === 2) return "CLUE RECORDED: DIGIT 2 = [ 8 ]  (PREFIX: 58)"
                            if (root.clueIndex === 3) return "CLUE RECORDED: DIGITS 3 & 4 = [ 2 4 ]  (FULL CODE: 5824)"
                            if (root.clueIndex === 4) return "RIDDLE CLUE RECORDED: CORRECT IDENTITY = [ THE DRIVE GEAR ]"
                            return ""
                        }
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
