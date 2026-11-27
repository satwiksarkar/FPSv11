import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief CircuitPuzzle.qml provides the Among Us / Sci-Fi wire-matching minigame
 * for the Sector K4 Electrical Switchboard in Project VANGUARD Level 1.
 * Matches reference media_1795781599172_61c11268.jpg faithfully.
 */
Rectangle {
    id: root
    width: 680
    height: 680
    color: "#121519"
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

    // Right-side terminals order (scrambled permutation matching screenshot):
    // Row 0: Red (2)
    // Row 1: Blue (1)
    // Row 2: Yellow (0)
    // Row 3: Magenta (3)
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

    // Coordinates configuration
    readonly property int chamberWidth: 620
    readonly property int chamberHeight: 520
    readonly property int leftTipX: 98
    readonly property int rightTipX: chamberWidth - 98

    // Row Y positions inside the chamber
    readonly property var rowYPositions: [80, 195, 310, 425]

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
        // Scrambled permutation matching screenshot by default: [2, 1, 0, 3]
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
        for (let p = 0; p < 18; ++p) {
            let angle = Math.random() * 2 * Math.PI
            let speed = 40 + Math.random() * 90
            list.push({
                x: cx,
                y: cy,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life: 0.35,
                maxLife: 0.35,
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
            completionSoundTimer.restart()
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
                    sp.vy += 80 * dt // subtle gravity
                    list.push(sp)
                }
            }
            root.sparkParticles = list
            wireCanvas.requestPaint()
        }
    }

    Timer {
        id: completionSoundTimer
        interval: 1500
        repeat: false
        onTriggered: {
            // Optional delayed feedback
        }
    }

    // Outer Container Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header Bar
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 4
                height: 36
                color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00f0ff"
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "SECTOR K4 // JUNCTION BOX 04-B"
                    color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00f0ff"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "ELECTRICAL REPAIR // CONNECT MATCHING CONDUCTORS [LEFT -> RIGHT]"
                    color: "#95a5a6"
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            // Status Badge
            Rectangle {
                width: 140
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
                width: 32
                height: 32
                color: closeBtnMouse.containsMouse ? "#e74c3c" : "#242a32"
                border.color: "#4a5568"
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

        // ==================== MAIN WIRE FIXING CHAMBER ====================
        Rectangle {
            id: chamber
            Layout.fillWidth: true
            Layout.preferredHeight: root.chamberHeight
            color: "#181b20"
            border.color: "#2c323b"
            border.width: 2
            radius: 6
            clip: true

            // Interactive Wire Canvas
            Canvas {
                id: wireCanvas
                anchors.fill: parent

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    // 1. Draw central cylindrical conduit column
                    let colW = 280
                    let colX = (width - colW) / 2
                    let colGrad = ctx.createLinearGradient(colX, 0, colX + colW, 0)
                    colGrad.addColorStop(0.0, "#101215")
                    colGrad.addColorStop(0.15, "#1d2127")
                    colGrad.addColorStop(0.5, "#2a2f38")
                    colGrad.addColorStop(0.85, "#1d2127")
                    colGrad.addColorStop(1.0, "#101215")
                    ctx.fillStyle = colGrad
                    ctx.fillRect(colX, 0, colW, height)

                    // Conduit column edge shadow lines
                    ctx.fillStyle = "#0c0e11"
                    ctx.fillRect(colX - 2, 0, 2, height)
                    ctx.fillRect(colX + colW, 0, 2, height)

                    // 2. Draw background dangling cable bundles from top (authentic Among Us art)
                    ctx.save()
                    ctx.lineCap = "round"

                    // Top bracket clamps
                    ctx.fillStyle = "#4a5260"
                    ctx.strokeStyle = "#1b1f24"
                    ctx.lineWidth = 2
                    // Clamp 1
                    ctx.fillRect(colX + 75, 40, 32, 14)
                    ctx.strokeRect(colX + 75, 40, 32, 14)
                    // Clamp 2
                    ctx.fillRect(colX + 155, 25, 32, 14)
                    ctx.strokeRect(colX + 155, 25, 32, 14)

                    // Clamp screws
                    ctx.fillStyle = "#1e2229"
                    ctx.beginPath()
                    ctx.arc(colX + 81, 47, 2.5, 0, 2 * Math.PI)
                    ctx.arc(colX + 101, 47, 2.5, 0, 2 * Math.PI)
                    ctx.arc(colX + 161, 32, 2.5, 0, 2 * Math.PI)
                    ctx.arc(colX + 181, 32, 2.5, 0, 2 * Math.PI)
                    ctx.fill()

                    // Background bundle cable curves
                    function drawBundleCable(startX, startY, cp1x, cp1y, cp2x, cp2y, endX, endY, color, widthVal) {
                        ctx.beginPath()
                        ctx.moveTo(startX, startY)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endX, endY)
                        ctx.strokeStyle = "#08090b"
                        ctx.lineWidth = widthVal + 4
                        ctx.stroke()
                        ctx.strokeStyle = color
                        ctx.lineWidth = widthVal
                        ctx.stroke()
                    }

                    // Background cables coming from ceiling through clamps
                    drawBundleCable(colX + 90, 0, colX + 90, 80, colX + 50, 160, colX + 40, 320, "#8b1e1e", 11) // Red cable
                    drawBundleCable(colX + 170, 0, colX + 175, 90, colX + 185, 220, colX + 190, 520, "#8a6d1a", 13) // Gold cable
                    drawBundleCable(colX + 85, 0, colX + 88, 120, colX + 75, 280, colX + 70, 520, "#1c1e22", 10) // Black cable
                    drawBundleCable(colX + 93, 0, colX + 95, 140, colX + 60, 260, colX + 30, 280, "#194d82", 11) // Blue cable
                    drawBundleCable(colX + 175, 0, colX + 170, 110, colX + 165, 300, colX + 168, 520, "#8b1e1e", 9) // Thin red cable
                    drawBundleCable(colX + 160, 0, colX + 155, 130, colX + 140, 360, colX + 140, 520, "#194d82", 10) // Center blue cable
                    ctx.restore()

                    // 3. Helper to draw a thick, stylized connecting wire
                    function drawStylizedWire(x1, y1, x2, y2, color, highlightColor) {
                        ctx.save()
                        ctx.lineCap = "round"

                        let dx = x2 - x1
                        let dy = y2 - y1
                        let dist = Math.sqrt(dx * dx + dy * dy)

                        // Natural drooping curve control points
                        let sag = Math.max(12, Math.min(60, dist * 0.12))
                        let cp1x = x1 + dx * 0.40
                        let cp1y = y1 + dy * 0.20 + sag
                        let cp2x = x1 + dx * 0.65
                        let cp2y = y2 - dy * 0.15 + sag

                        // Layer 1: Dark outer border / casing
                        ctx.beginPath()
                        ctx.moveTo(x1, y1)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2)
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = 18
                        ctx.stroke()

                        // Layer 2: Main vibrant wire insulation
                        ctx.beginPath()
                        ctx.moveTo(x1, y1)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2)
                        ctx.strokeStyle = color
                        ctx.lineWidth = 13
                        ctx.stroke()

                        // Layer 3: Upper specular highlight
                        ctx.beginPath()
                        ctx.moveTo(x1, y1 - 2)
                        ctx.bezierCurveTo(cp1x, cp1y - 2, cp2x, cp2y - 2, x2, y2 - 2)
                        ctx.strokeStyle = highlightColor
                        ctx.lineWidth = 3.5
                        ctx.stroke()

                        ctx.restore()
                    }

                    // 4. Draw all established connections
                    for (let leftIdx = 0; leftIdx < 4; ++leftIdx) {
                        let rightRow = root.connections[leftIdx]
                        if (rightRow !== -1) {
                            let x1 = root.leftTipX
                            let y1 = root.rowYPositions[leftIdx]
                            let x2 = root.rightTipX
                            let y2 = root.rowYPositions[rightRow]
                            drawStylizedWire(x1, y1, x2, y2, root.wireColors[leftIdx], root.wireHighlightColors[leftIdx])
                        }
                    }

                    // 5. Draw active dragging wire
                    if (root.draggingWireIndex !== -1) {
                        let activeIdx = root.draggingWireIndex
                        let x1 = root.leftTipX
                        let y1 = root.rowYPositions[activeIdx]
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
                        ctx.moveTo(2, -4); ctx.lineTo(7, -6); ctx.lineTo(4, -2); ctx.fill()
                        ctx.beginPath()
                        ctx.moveTo(2, -1); ctx.lineTo(8, 0);  ctx.lineTo(4, 2);  ctx.fill()
                        ctx.beginPath()
                        ctx.moveTo(2, 3);  ctx.lineTo(7, 5);  ctx.lineTo(4, 4);  ctx.fill()
                        ctx.restore()
                    }

                    // 6. Draw electric spark particles
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

            // ==================== LEFT TERMINALS REPEATER ====================
            Repeater {
                model: 4
                Item {
                    id: leftItem
                    readonly property int wireIdx: index
                    readonly property int centerY: root.rowYPositions[index]
                    readonly property bool isConnected: root.connections[wireIdx] !== -1
                    readonly property bool isDragging: root.draggingWireIndex === wireIdx
                    readonly property bool isSelected: root.selectedLeftIndex === wireIdx

                    x: 10
                    y: centerY - 18
                    width: 90
                    height: 36

                    // Base mounting plate
                    Rectangle {
                        anchors.fill: parent
                        color: "#16191d"
                        border.color: isSelected ? "#00f0ff" : "#2d333b"
                        border.width: isSelected ? 2 : 1
                        radius: 3
                    }

                    // Left Terminal Colored Body Bar
                    Rectangle {
                        id: leftBar
                        x: 4
                        y: 4
                        width: 68
                        height: 28
                        color: root.wireColors[wireIdx]
                        border.color: "#0a0c0e"
                        border.width: 2
                        radius: 2

                        // Top tab marker (characteristic detail from Among Us)
                        Rectangle {
                            x: 0
                            y: -5
                            width: 14
                            height: 6
                            color: root.wireColors[wireIdx]
                            border.color: "#0a0c0e"
                            border.width: 1
                        }

                        // Symbol glyph (○, ✕, △, ☆)
                        Text {
                            anchors.centerIn: parent
                            text: root.wireSymbols[wireIdx]
                            color: "#000000"
                            font.pixelSize: 17
                            font.bold: true
                        }
                    }

                    // Stripped Copper Wire Tip (protruding rightwards)
                    Item {
                        x: 72
                        y: 8
                        width: 20
                        height: 20

                        // Copper wire end coils
                        Rectangle {
                            x: 0; y: 4; width: 12; height: 12
                            color: "#b85d19"
                            border.color: "#6e330a"
                            border.width: 1
                            radius: 1
                        }
                        // Strands detail
                        Rectangle { x: 2; y: 5; width: 2.5; height: 10; color: "#f39c12" }
                        Rectangle { x: 6; y: 5; width: 2.5; height: 10; color: "#e67e22" }

                        // Frayed copper threads extending into canvas
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                let c = getContext("2d")
                                c.clearRect(0, 0, width, height)
                                c.strokeStyle = "#e67e22"
                                c.lineWidth = 1.8
                                c.beginPath()
                                c.moveTo(12, 6);  c.lineTo(18, 5)
                                c.moveTo(12, 10); c.lineTo(19, 10)
                                c.moveTo(12, 14); c.lineTo(18, 15)
                                c.stroke()
                            }
                        }
                    }

                    // Status Indicator LED on left
                    Rectangle {
                        x: -4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 14
                        radius: 2
                        color: leftItem.isConnected ? "#2ecc71" : "#57606f"
                        border.color: leftItem.isConnected ? "#a8ffb2" : "#2f3542"
                        border.width: 1
                    }
                }
            }

            // ==================== RIGHT TERMINALS REPEATER ====================
            Repeater {
                model: 4
                Item {
                    id: rightItem
                    readonly property int rightRow: index
                    readonly property int targetWireIdx: root.rightOrder[rightRow]
                    readonly property int centerY: root.rowYPositions[rightRow]
                    readonly property bool isConnected: {
                        for (let i = 0; i < root.connections.length; ++i) {
                            if (root.connections[i] === rightRow) return true
                        }
                        return false
                    }

                    x: chamber.width - 100
                    y: centerY - 18
                    width: 90
                    height: 36

                    // Base mounting plate
                    Rectangle {
                        anchors.fill: parent
                        color: "#16191d"
                        border.color: rightItem.isConnected ? "#2ecc71" : "#2d333b"
                        border.width: rightItem.isConnected ? 2 : 1
                        radius: 3
                    }

                    // Stripped Copper Wire Tip (pointing leftwards towards center)
                    Item {
                        x: -2
                        y: 8
                        width: 20
                        height: 20

                        Rectangle {
                            x: 6; y: 4; width: 12; height: 12
                            color: "#b85d19"
                            border.color: "#6e330a"
                            border.width: 1
                            radius: 1
                        }
                        Rectangle { x: 8; y: 5; width: 2.5; height: 10; color: "#e67e22" }
                        Rectangle { x: 12; y: 5; width: 2.5; height: 10; color: "#f39c12" }

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                let c = getContext("2d")
                                c.clearRect(0, 0, width, height)
                                c.strokeStyle = "#e67e22"
                                c.lineWidth = 1.8
                                c.beginPath()
                                c.moveTo(6, 6);  c.lineTo(1, 5)
                                c.moveTo(6, 10); c.lineTo(0, 10)
                                c.moveTo(6, 14); c.lineTo(1, 15)
                                c.stroke()
                            }
                        }
                    }

                    // Right Terminal Colored Body Bar
                    Rectangle {
                        x: 18
                        y: 4
                        width: 68
                        height: 28
                        color: root.wireColors[targetWireIdx]
                        border.color: "#0a0c0e"
                        border.width: 2
                        radius: 2

                        // Top tab marker
                        Rectangle {
                            x: parent.width - 14
                            y: -5
                            width: 14
                            height: 6
                            color: root.wireColors[targetWireIdx]
                            border.color: "#0a0c0e"
                            border.width: 1
                        }

                        // Symbol glyph
                        Text {
                            anchors.centerIn: parent
                            text: root.wireSymbols[targetWireIdx]
                            color: "#000000"
                            font.pixelSize: 17
                            font.bold: true
                        }
                    }

                    // Status Indicator LED on right (glows bright green when connected!)
                    Rectangle {
                        x: parent.width - 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 14
                        radius: 2
                        color: rightItem.isConnected ? "#2ecc71" : "#57606f"
                        border.color: rightItem.isConnected ? "#a8ffb2" : "#2f3542"
                        border.width: 1
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

                    // Check if pressed on a Left Terminal
                    for (let i = 0; i < 4; ++i) {
                        let ly = root.rowYPositions[i]
                        if (mouse.x <= 130 && Math.abs(mouse.y - ly) <= 32) {
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

                    // Check if clicked directly on a Right Terminal while left is selected
                    if (root.selectedLeftIndex !== -1) {
                        for (let j = 0; j < 4; ++j) {
                            let ry = root.rowYPositions[j]
                            if (mouse.x >= chamber.width - 130 && Math.abs(mouse.y - ry) <= 32) {
                                if (root.rightOrder[j] === root.selectedLeftIndex) {
                                    // MATCH!
                                    let newConns = root.connections.slice()
                                    newConns[root.selectedLeftIndex] = j
                                    root.connections = newConns
                                    root.addSparks(root.rightTipX, ry, root.wireColors[root.selectedLeftIndex])
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
                        let connected = false

                        // Check if released on/near matching right terminal
                        for (let j = 0; j < 4; ++j) {
                            let ry = root.rowYPositions[j]
                            if (mouse.x >= chamber.width - 150 && Math.abs(mouse.y - ry) <= 36) {
                                if (root.rightOrder[j] === activeIdx) {
                                    // SUCCESS MATCH!
                                    let newConns = root.connections.slice()
                                    newConns[activeIdx] = j
                                    root.connections = newConns
                                    root.addSparks(root.rightTipX, ry, root.wireColors[activeIdx])
                                    connected = true
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
                width: 480
                height: 140
                visible: root.isFullyConnected
                color: "#e60a1f14"
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
                            font.pixelSize: 18
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "BULKHEAD ACCESS INTERLOCK RELEASED — CARD READERS ONLINE"
                        color: "#a8ffb2"
                        font.pixelSize: 12
                    }

                    Item { height: 4 }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        contentItem: Text {
                            text: "[RETURN TO FACILITY]"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            implicitWidth: 190
                            implicitHeight: 34
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
                    implicitWidth: 120
                    implicitHeight: 32
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
