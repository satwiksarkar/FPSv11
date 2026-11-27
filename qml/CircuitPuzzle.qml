import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CircuitPuzzle.qml provides the Among Us / Sci-Fi wire-matching minigame
 * for the Sector K4 Electrical Switchboard in Project VANGUARD Level 1.
 * Faithfully matches reference image media_1795781599172_61c11268.jpg.
 */
Rectangle {
    id: root
    width: 660
    height: 700
    color: "#0f1115"
    border.color: "#38414e"
    border.width: 3
    radius: 8

    property var puzzleManager: null
    signal closeRequested()

    // 4 Wires definition matching the reference image:
    // 0: Yellow (○ circle)
    // 1: Blue   (✕ cross)
    // 2: Red    (△ triangle)
    // 3: Magenta (☆ star)
    readonly property var wireColors: ["#f1c40f", "#0066ff", "#e74c3c", "#d926a9"]
    readonly property var wireHighlightColors: ["#fff3b0", "#80b3ff", "#ff8080", "#f5a3e8"]
    readonly property var wireSymbols: ["○", "✕", "△", "☆"]
    readonly property var wireNames: ["YELLOW", "BLUE", "RED", "MAGENTA"]

    // Right-side terminals order (matches screenshot exactly):
    // Row 0: Red (index 2)
    // Row 1: Blue (index 1)
    // Row 2: Yellow (index 0)
    // Row 3: Magenta (index 3)
    property var rightOrder: [2, 1, 0, 3]

    // Connections array: index is left terminal (0..3), value is connected right row (0..3) or -1
    property var connections: [-1, -1, -1, -1]

    // Active drag state
    property int draggingWireIndex: -1
    property point dragCurrentPos: Qt.point(0, 0)
    property int selectedLeftIndex: -1

    // Solved state tracking
    readonly property int connectedCount: {
        let count = 0
        for (let i = 0; i < connections.length; ++i) {
            if (connections[i] !== -1) count++
        }
        return count
    }
    readonly property bool isFullyConnected: connectedCount === 4

    // Spark particles for electric zap effects
    property var sparkParticles: []

    // Coordinates configuration normalized to the 943x943 reference art
    readonly property real normLeftTipX: 125.0 / 943.0
    readonly property real normRightTipX: 800.0 / 943.0
    readonly property var normLeftRowY: [190.0 / 943.0, 387.0 / 943.0, 581.0 / 943.0, 773.0 / 943.0]
    readonly property var normRightRowY: [192.0 / 943.0, 387.0 / 943.0, 583.0 / 943.0, 773.0 / 943.0]

    // Normalized Indicator Tab Rectangles (top-left of each left terminal)
    // [yStart, height] in normalized coordinates
    readonly property real normTabX: 9.0 / 943.0
    readonly property real normTabW: 51.0 / 943.0
    readonly property var normTabY: [149.0 / 943.0, 345.0 / 943.0, 537.0 / 943.0, 729.0 / 943.0]
    readonly property var normTabH: [20.0 / 943.0, 19.0 / 943.0, 21.0 / 943.0, 21.0 / 943.0]

    // Synchronize with puzzleManager if already solved
    Component.onCompleted: {
        shuffleRightOrder()
        if (puzzleManager && puzzleManager.powerSolved) {
            restoreSolvedConnections()
        }
    }

    Connections {
        target: root.puzzleManager
        function onPowerSolvedChanged() {
            if (root.puzzleManager && root.puzzleManager.powerSolved) {
                root.restoreSolvedConnections()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (puzzleManager && puzzleManager.powerSolved) {
                restoreSolvedConnections()
            } else if (connectedCount === 0) {
                shuffleRightOrder()
            }
            wireCanvas.requestPaint()
        }
    }

    function shuffleRightOrder() {
        rightOrder = [2, 1, 0, 3]
        connections = [-1, -1, -1, -1]
        draggingWireIndex = -1
        selectedLeftIndex = -1
        wireCanvas.requestPaint()
    }

    function restoreSolvedConnections() {
        let newConn = [-1, -1, -1, -1]
        for (let leftIdx = 0; leftIdx < 4; ++leftIdx) {
            for (let rightRow = 0; rightRow < 4; ++rightRow) {
                if (rightOrder[rightRow] === leftIdx) {
                    newConn[leftIdx] = rightRow
                    break
                }
            }
        }
        connections = newConn
        wireCanvas.requestPaint()
    }

    function resetWires() {
        if (puzzleManager && puzzleManager.powerSolved) return
        connections = [-1, -1, -1, -1]
        draggingWireIndex = -1
        selectedLeftIndex = -1
        wireCanvas.requestPaint()
    }

    function addSparks(cx, cy, color) {
        let list = sparkParticles.slice()
        for (let p = 0; p < 22; ++p) {
            let angle = Math.random() * 2 * Math.PI
            let speed = 40 + Math.random() * 110
            list.push({
                x: cx,
                y: cy,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life: 0.40,
                maxLife: 0.40,
                color: color
            })
        }
        sparkParticles = list
        sparkTimer.restart()
    }

    function checkSuccess() {
        wireCanvas.requestPaint()
        if (isFullyConnected) {
            if (root.puzzleManager && !root.puzzleManager.powerSolved) {
                root.puzzleManager.solveWiring()
            }
        }
    }

    Timer {
        id: sparkTimer
        interval: 16
        repeat: true
        running: root.sparkParticles.length > 0
        onTriggered: {
            let list = []
            let dt = 0.016
            for (let i = 0; i < root.sparkParticles.length; ++i) {
                let sp = root.sparkParticles[i]
                sp.life -= dt
                if (sp.life > 0) {
                    sp.x += sp.vx * dt
                    sp.y += sp.vy * dt
                    sp.vy += 90 * dt
                    list.push(sp)
                }
            }
            root.sparkParticles = list
            wireCanvas.requestPaint()
        }
    }

    // Outer Container Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header Bar
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 4
                height: 34
                color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00f0ff"
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "SECTOR K4 // JUNCTION BOX 04-B"
                    color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00f0ff"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "ELECTRICAL REPAIR // FIX WIRING [CONNECT MATCHING TERMINALS]"
                    color: "#95a5a6"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            // Status Badge
            Rectangle {
                width: 135
                height: 28
                color: root.isFullyConnected ? "#103820" : "#1a252f"
                border.color: root.isFullyConnected ? "#2ecc71" : "#34495e"
                border.width: 1
                radius: 3

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.isFullyConnected ? "#2ecc71" : "#e74c3c"
                    }
                    Text {
                        text: root.isFullyConnected ? "ONLINE: 4 / 4" : ("CONNECTED: " + root.connectedCount + " / 4")
                        color: root.isFullyConnected ? "#2ecc71" : "#00f0ff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // Close Button
            Rectangle {
                width: 30
                height: 30
                color: closeBtnMouse.containsMouse ? "#e74c3c" : "#242a32"
                border.color: "#4a5568"
                border.width: 1
                radius: 3

                Text {
                    anchors.centerIn: parent
                    text: "✕"
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

        // ==================== MAIN WIRE FIXING CHAMBER ====================
        Rectangle {
            id: chamber
            Layout.fillWidth: true
            Layout.preferredHeight: width
            color: "#0a0c0e"
            border.color: "#2c323b"
            border.width: 2
            radius: 6
            clip: true

            // Pixel-Perfect Authentic Among Us Background Art
            Image {
                id: bgArt
                anchors.fill: parent
                source: "../assets/textures/wire_puzzle_bg.png"
                fillMode: Image.Stretch
                smooth: true
                mipmap: true
            }

            // Glowing Indicator Overlays (lit green when terminal connected)
            Repeater {
                model: 4
                Rectangle {
                    readonly property int rowIdx: index
                    readonly property bool isConn: root.connections[rowIdx] !== -1

                    x: chamber.width * root.normTabX
                    y: chamber.height * root.normTabY[rowIdx]
                    width: chamber.width * root.normTabW
                    height: chamber.height * root.normTabH[rowIdx]
                    radius: 2
                    visible: isConn
                    color: "#39ff14"
                    border.color: "#a8ffb2"
                    border.width: 1.5
                    opacity: 0.95

                    // Outer neon glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height + 6
                        radius: 4
                        color: "transparent"
                        border.color: "#2ecc71"
                        border.width: 2
                        opacity: 0.6
                    }
                }
            }

            // Selection Highlight Rings on Left Terminals
            Repeater {
                model: 4
                Rectangle {
                    readonly property int rowIdx: index
                    readonly property bool isSel: root.selectedLeftIndex === rowIdx

                    x: chamber.width * 0.015
                    y: chamber.height * (root.normLeftRowY[rowIdx] - 0.055)
                    width: chamber.width * 0.13
                    height: chamber.height * 0.11
                    radius: 4
                    visible: isSel
                    color: "transparent"
                    border.color: "#00f0ff"
                    border.width: 2
                }
            }

            // Interactive Wire Canvas
            Canvas {
                id: wireCanvas
                anchors.fill: parent

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    let cw = width
                    let ch = height

                    // Helper to draw a thick, stylized connecting wire matching Among Us aesthetics
                    function drawStylizedWire(x1, y1, x2, y2, color, highlightColor) {
                        ctx.save()
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        let dx = x2 - x1
                        let dy = y2 - y1
                        let dist = Math.sqrt(dx * dx + dy * dy)

                        // Natural horizontal exit tangent with subtle gravitational droop
                        let sag = Math.max(10, Math.min(50, dist * 0.11))
                        let span = Math.max(30, dx * 0.45)
                        let cp1x = x1 + span
                        let cp1y = y1 + sag
                        let cp2x = x2 - span
                        let cp2y = y2 + sag

                        // Layer 1: Dark outer border / casing (Among Us cartoon outline)
                        ctx.beginPath()
                        ctx.moveTo(x1, y1)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2)
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = 19
                        ctx.stroke()

                        // Layer 2: Main vibrant wire insulation
                        ctx.beginPath()
                        ctx.moveTo(x1, y1)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2)
                        ctx.strokeStyle = color
                        ctx.lineWidth = 13
                        ctx.stroke()

                        // Layer 3: Upper specular highlight stripe
                        ctx.beginPath()
                        ctx.moveTo(x1, y1 - 2.5)
                        ctx.bezierCurveTo(cp1x, cp1y - 2.5, cp2x, cp2y - 2.5, x2, y2 - 2.5)
                        ctx.strokeStyle = highlightColor
                        ctx.lineWidth = 3
                        ctx.stroke()

                        ctx.restore()
                    }

                    // 1. Draw all established connections
                    for (let leftIdx = 0; leftIdx < 4; ++leftIdx) {
                        let rightRow = root.connections[leftIdx]
                        if (rightRow !== -1) {
                            let x1 = cw * root.normLeftTipX
                            let y1 = ch * root.normLeftRowY[leftIdx]
                            let x2 = cw * root.normRightTipX
                            let y2 = ch * root.normRightRowY[rightRow]
                            drawStylizedWire(x1, y1, x2, y2, root.wireColors[leftIdx], root.wireHighlightColors[leftIdx])
                        }
                    }

                    // 2. Draw active dragging wire
                    if (root.draggingWireIndex !== -1) {
                        let activeIdx = root.draggingWireIndex
                        let x1 = cw * root.normLeftTipX
                        let y1 = ch * root.normLeftRowY[activeIdx]
                        let x2 = root.dragCurrentPos.x
                        let y2 = root.dragCurrentPos.y
                        drawStylizedWire(x1, y1, x2, y2, root.wireColors[activeIdx], root.wireHighlightColors[activeIdx])

                        // Draw exposed copper tip tracking mouse cursor
                        ctx.save()
                        let angle = Math.atan2(y2 - y1, x2 - x1)
                        ctx.translate(x2, y2)
                        ctx.rotate(angle)

                        // Copper coils at tip
                        ctx.fillStyle = "#b85d19"
                        ctx.fillRect(-10, -6, 12, 12)
                        ctx.fillStyle = "#e67e22"
                        ctx.fillRect(-8, -5, 3, 10)
                        ctx.fillRect(-4, -5, 3, 10)
                        ctx.fillRect(0, -5, 3, 10)
                        // Frayed copper tips
                        ctx.fillStyle = "#f39c12"
                        ctx.beginPath()
                        ctx.moveTo(2, -4); ctx.lineTo(8, -6); ctx.lineTo(4, -2); ctx.fill()
                        ctx.beginPath()
                        ctx.moveTo(2, -1); ctx.lineTo(9, 0);  ctx.lineTo(4, 2);  ctx.fill()
                        ctx.beginPath()
                        ctx.moveTo(2, 3);  ctx.lineTo(8, 5);  ctx.lineTo(4, 4);  ctx.fill()
                        ctx.restore()
                    }

                    // 3. Draw electric spark particles
                    for (let s = 0; s < root.sparkParticles.length; ++s) {
                        let sp = root.sparkParticles[s]
                        let alpha = Math.max(0, sp.life / sp.maxLife)
                        ctx.save()
                        ctx.globalAlpha = alpha
                        ctx.fillStyle = sp.color
                        ctx.beginPath()
                        ctx.arc(sp.x, sp.y, 2.5, 0, 2 * Math.PI)
                        ctx.fill()
                        ctx.restore()
                    }
                }
            }

            // ==================== INTERACTION MOUSE AREA ====================
            MouseArea {
                id: interactionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.draggingWireIndex !== -1 ? Qt.ClosedHandCursor : Qt.ArrowCursor

                onPressed: function(mouse) {
                    if (root.puzzleManager && root.puzzleManager.powerSolved) return

                    let cw = chamber.width
                    let ch = chamber.height

                    // Check if pressed on a Left Terminal
                    for (let i = 0; i < 4; ++i) {
                        let ly = ch * root.normLeftRowY[i]
                        if (mouse.x <= cw * 0.16 && Math.abs(mouse.y - ly) <= ch * 0.055) {
                            root.draggingWireIndex = i
                            root.selectedLeftIndex = i
                            root.dragCurrentPos = Qt.point(mouse.x, mouse.y)

                            // If already connected, disconnect it to allow re-wiring
                            if (root.connections[i] !== -1) {
                                let newConns = root.connections.slice()
                                newConns[i] = -1
                                root.connections = newConns
                            }
                            wireCanvas.requestPaint()
                            return
                        }
                    }

                    // Check if clicked directly on a Right Terminal while a left terminal is selected
                    if (root.selectedLeftIndex !== -1) {
                        for (let j = 0; j < 4; ++j) {
                            let ry = ch * root.normRightRowY[j]
                            if (mouse.x >= cw * 0.82 && Math.abs(mouse.y - ry) <= ch * 0.055) {
                                if (root.rightOrder[j] === root.selectedLeftIndex) {
                                    // MATCH!
                                    let newConns = root.connections.slice()
                                    newConns[root.selectedLeftIndex] = j
                                    root.connections = newConns
                                    let rx = cw * root.normRightTipX
                                    root.addSparks(rx, ry, root.wireColors[root.selectedLeftIndex])
                                    root.selectedLeftIndex = -1
                                    root.draggingWireIndex = -1
                                    root.checkSuccess()
                                    return
                                }
                            }
                        }
                    }

                    root.selectedLeftIndex = -1
                }

                onPositionChanged: function(mouse) {
                    if (root.draggingWireIndex !== -1) {
                        root.dragCurrentPos = Qt.point(mouse.x, mouse.y)
                        wireCanvas.requestPaint()
                    }
                }

                onReleased: function(mouse) {
                    if (root.draggingWireIndex !== -1) {
                        let activeIdx = root.draggingWireIndex
                        let cw = chamber.width
                        let ch = chamber.height

                        // Check if released on/near matching right terminal
                        for (let j = 0; j < 4; ++j) {
                            let ry = ch * root.normRightRowY[j]
                            if (mouse.x >= cw * 0.80 && Math.abs(mouse.y - ry) <= ch * 0.065) {
                                if (root.rightOrder[j] === activeIdx) {
                                    // SUCCESS MATCH!
                                    let newConns = root.connections.slice()
                                    newConns[activeIdx] = j
                                    root.connections = newConns
                                    let rx = cw * root.normRightTipX
                                    root.addSparks(rx, ry, root.wireColors[activeIdx])
                                    root.checkSuccess()
                                    break
                                }
                            }
                        }

                        root.draggingWireIndex = -1
                        wireCanvas.requestPaint()
                    }
                }
            }

            // ==================== SOLVED OVERLAY BANNER ====================
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.85
                height: 130
                visible: root.isFullyConnected
                color: "#f00a1f14"
                border.color: "#2ecc71"
                border.width: 2
                radius: 6
                z: 20

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Rectangle { width: 12; height: 12; radius: 6; color: "#2ecc71" }
                        Text {
                            text: "WIRING RESTORED // CONTINUITY 100%"
                            color: "#2ecc71"
                            font.pixelSize: 16
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "BULKHEAD ACCESS INTERLOCK RELEASED — CARD READERS ONLINE"
                        color: "#a8ffb2"
                        font.pixelSize: 11
                    }

                    Item { height: 2 }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        contentItem: Text {
                            text: "[RETURN TO FACILITY]"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 32
                            color: parent.down ? "#1e8449" : (parent.hovered ? "#2ecc71" : "#27ae60")
                            border.color: "#2ecc71"
                            border.width: 1
                            radius: 3
                        }
                        onClicked: root.closeRequested()
                    }
                }
            }
        }

        // ==================== FOOTER CONTROLS ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: root.isFullyConnected
                      ? "TASK COMPLETED: ALL FOUR CIRCUITS SECURED"
                      : "INSTRUCTION: DRAG COPPER WIRE FROM LEFT TO MATCHING RIGHT SYMBOL/COLOR"
                color: root.isFullyConnected ? "#2ecc71" : "#7f8c8d"
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            // Reset Wires Button
            Button {
                enabled: !root.isFullyConnected && !(root.puzzleManager && root.puzzleManager.powerSolved)
                contentItem: Text {
                    text: "[RESET WIRES]"
                    color: parent.enabled ? "#ffffff" : "#636e72"
                    font.bold: true
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 110
                    implicitHeight: 28
                    color: parent.down ? "#7f8c8d" : (parent.hovered ? "#4b6584" : "#242a32")
                    border.color: parent.enabled ? "#4a5568" : "#2d3436"
                    border.width: 1
                    radius: 3
                }
                onClicked: root.resetWires()
            }
        }
    }
}
