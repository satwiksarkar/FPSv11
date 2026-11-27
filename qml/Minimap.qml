import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FPSLabGame

/**
 * @brief Minimap.qml provides a high-contrast, responsive 2D tactical radar
 * and blueprint facility layout in the HUD for Project VANGUARD.
 *
 * Visual & Functional Specifications:
 * - Displays the complete architectural map layout (structural walls, corridors, rooms).
 * - High-contrast palette: crisp steel-blue walls (#4a6984/#2d4255) over blueprint floor (#1b2838/#121a24).
 * - Real-time Fog of War highlights actively surveyed sectors.
 * - Dynamic door rendering with proper orientation and security color coding (standard, locked, area-locked, exit).
 * - Exact key and puzzle terminal markers with solved status indicators.
 * - Extraction exit platform beacon with amber pulse.
 * - Live enemy sensor blips for active threats in range.
 * - Directional player chevron rotating with player yaw against fixed North.
 * - Supports keyboard [M] toggle and mouse click to expand from compact radar (196x196) to tactical overview (380x380).
 */
Rectangle {
    id: root
    width: isExpanded ? 380 : 196
    height: isExpanded ? 380 : 196
    color: "#e60a0d14"
    border.color: isExpanded ? "#00e5ff" : "#3300e5ff"
    border.width: isExpanded ? 2 : 1
    radius: 4
    clip: true

    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    property var levelManager: null
    property var player: null
    property var puzzleManager: null
    property var enemyManager: null
    property bool isExpanded: false

    readonly property int mapW: levelManager ? levelManager.mapWidth : 80
    readonly property int mapH: levelManager ? levelManager.mapHeight : 80
    readonly property real blockSize: levelManager ? levelManager.blockSize : 100.0

    // Cached Uint8Array map buffer and exploration state
    property var mapBytes: null
    property var exploredTiles: null
    property int lastExploredLevel: -1
    property int lastPlayerCol: -1
    property int lastPlayerRow: -1

    function toggleExpanded() {
        isExpanded = !isExpanded
    }

    function cacheMapData() {
        if (!levelManager) return
        var raw = levelManager.getMapData()
        if (!raw) return

        var bytes = null
        if (raw instanceof ArrayBuffer) {
            bytes = new Uint8Array(raw)
        } else if (raw.buffer && raw.buffer instanceof ArrayBuffer) {
            bytes = new Uint8Array(raw.buffer)
        } else if (typeof raw === "string") {
            bytes = new Uint8Array(raw.length)
            for (var i = 0; i < raw.length; ++i) {
                bytes[i] = raw.charCodeAt(i)
            }
        } else {
            bytes = new Uint8Array(raw)
        }
        mapBytes = bytes
        mapCanvas.requestPaint()
    }

    function initExploration() {
        if (!levelManager) return
        var size = mapW * mapH
        exploredTiles = new Uint8Array(size)
        lastExploredLevel = levelManager.currentLevel
        lastPlayerCol = -1
        lastPlayerRow = -1
        cacheMapData()
        mapCanvas.requestPaint()
    }

    onMapWChanged: initExploration()
    onMapHChanged: initExploration()
    onWidthChanged: {
        mapCanvas.requestPaint()
        enemyBlipCanvas.requestPaint()
    }
    onHeightChanged: {
        mapCanvas.requestPaint()
        enemyBlipCanvas.requestPaint()
    }

    Connections {
        target: levelManager
        function onCurrentLevelChanged() {
            root.initExploration()
        }
        function onDoorsChanged() {
            mapCanvas.requestPaint()
        }
        function onLevelKeysChanged() {
            mapCanvas.requestPaint()
        }
    }

    Connections {
        target: puzzleManager
        function onPuzzleStateChanged() { mapCanvas.requestPaint() }
        function onCraneSolvedChanged() { mapCanvas.requestPaint() }
        function onPowerSolvedChanged() { mapCanvas.requestPaint() }
        function onSecuritySolvedChanged() { mapCanvas.requestPaint() }
        function onCoolantSolvedChanged() { mapCanvas.requestPaint() }
    }

    // Dynamic Fog of War update as player moves
    function updateFogOfWar() {
        if (!player || !exploredTiles || !levelManager) return

        var px = player.position.x
        var pz = player.position.z
        var pCol = Math.floor(px / blockSize)
        var pRow = Math.floor(pz / blockSize)

        if (pCol === lastPlayerCol && pRow === lastPlayerRow) {
            return
        }

        lastPlayerCol = pCol
        lastPlayerRow = pRow

        var revealRadius = 10
        var r0 = Math.max(0, pRow - revealRadius)
        var r1 = Math.min(mapH - 1, pRow + revealRadius)
        var c0 = Math.max(0, pCol - revealRadius)
        var c1 = Math.min(mapW - 1, pCol + revealRadius)

        var newReveals = false
        var radSq = revealRadius * revealRadius

        for (var r = r0; r <= r1; ++r) {
            var dr = r - pRow
            for (var c = c0; c <= c1; ++c) {
                var dc = c - pCol
                if (dr * dr + dc * dc <= radSq) {
                    var idx = r * mapW + c
                    if (exploredTiles[idx] === 0) {
                        exploredTiles[idx] = 1
                        newReveals = true
                    }
                }
            }
        }

        if (newReveals) {
            mapCanvas.requestPaint()
        }
    }

    Connections {
        target: player
        function onPositionChanged() {
            root.updateFogOfWar()
            enemyBlipCanvas.requestPaint()
        }
    }

    Component.onCompleted: {
        initExploration()
        updateFogOfWar()
    }

    // ==================== LAYER 1: BASE MAP CANVAS ====================
    Canvas {
        id: mapCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (!levelManager) return
            if (!mapBytes) {
                root.cacheMapData()
                if (!mapBytes) return
            }

            var w = root.mapW
            var h = root.mapH
            var tileW = width / w
            var tileH = height / h

            // 1. Draw complete architectural floorplan
            for (var r = 0; r < h; ++r) {
                var rOffset = r * w
                var y = r * tileH
                for (var c = 0; c < w; ++c) {
                    var idx = rOffset + c
                    var tile = mapBytes[idx]
                    var x = c * tileW
                    var isExplored = (root.exploredTiles && root.exploredTiles[idx] > 0)

                    if (tile === 1 || tile === 9 || tile === 12) {
                        // Structural Walls: Wall(1), CoreWall(9), DoorPocket(12)
                        // Distinct steel blue lines defining rooms and corridors clearly
                        ctx.fillStyle = isExplored ? "#4a6984" : "#2d4255"
                        ctx.fillRect(x, y, Math.ceil(tileW), Math.ceil(tileH))
                    } else if (tile === 2) {
                        // Crate obstacle
                        ctx.fillStyle = isExplored ? "#6b7b8c" : "#3d4b58"
                        ctx.fillRect(x, y, Math.ceil(tileW), Math.ceil(tileH))
                    } else if (tile === 4 || tile === 6 || tile === 11) {
                        // Level Exit extraction platform
                        ctx.fillStyle = "#f39c12"
                        ctx.fillRect(x, y, Math.ceil(tileW), Math.ceil(tileH))
                    } else if (tile === 3) {
                        // Spawn platform
                        ctx.fillStyle = "#27ae60"
                        ctx.fillRect(x, y, Math.ceil(tileW), Math.ceil(tileH))
                    } else {
                        // Walkable floor / corridor / pickup / trigger
                        // Blueprint floor (#121a24), illuminated explored floor (#1b2838)
                        ctx.fillStyle = isExplored ? "#1b2838" : "#121a24"
                        ctx.fillRect(x, y, Math.ceil(tileW), Math.ceil(tileH))
                    }
                }
            }

            // 2. Draw Doors with orientation and security status
            if (levelManager.doors) {
                for (var d = 0; d < levelManager.doors.length; ++d) {
                    var door = levelManager.doors[d]
                    if (!door) continue

                    var dx = door.col * tileW
                    var dy = door.row * tileH

                    if (door.isOpen) {
                        ctx.fillStyle = "#2ecc71" // Green when open
                    } else if (door.doorType === 4) {
                        ctx.fillStyle = "#f1c40f" // Gold for Freight Elevator exit
                    } else if (door.doorType === 3) {
                        ctx.fillStyle = "#9b59b6" // Purple for AreaLocked door
                    } else if (door.isLocked) {
                        ctx.fillStyle = "#e67e22" // Orange for KeyLocked door
                    } else {
                        ctx.fillStyle = "#00e5ff" // Cyan standard door
                    }

                    if (door.axis === 90.0) {
                        // Vertical doorway along Z axis
                        ctx.fillRect(dx + tileW * 0.2, dy, Math.max(2.0, tileW * 0.6), Math.ceil(tileH))
                    } else {
                        // Horizontal doorway along X axis
                        ctx.fillRect(dx, dy + tileH * 0.2, Math.ceil(tileW), Math.max(2.0, tileH * 0.6))
                    }
                }
            }

            // 3. Draw Level 1 Puzzle Consoles & Stations
            if (levelManager.currentLevel === 1 && puzzleManager) {
                var isV2 = (levelManager.level1Variant === 2)
                var puzzles = isV2 ? [
                    { r: 30, c: 8, solved: puzzleManager.craneSolved, color: "#3498db", label: "RIDDLE" },
                    { r: 6, c: 36, solved: puzzleManager.powerSolved, color: "#f39c12", label: "SWITCHBOARD" },
                    { r: 27, c: 41, solved: (levelManager && !levelManager.laserCageActive), color: "#e74c3c", label: "LASER CAGE" }
                ] : [
                    { r: 30, c: 8, solved: puzzleManager.craneSolved, color: "#3498db", label: "RIDDLE" },
                    { r: 6, c: 36, solved: puzzleManager.powerSolved, color: "#f39c12", label: "SWITCHBOARD" },
                    { r: 27, c: 41, solved: (levelManager && !levelManager.laserCageActive), color: "#e74c3c", label: "LASER CAGE" }
                ]

                for (var p = 0; p < puzzles.length; ++p) {
                    var pz = puzzles[p]
                    var pzx = (pz.c + 0.5) * tileW
                    var pzy = (pz.r + 0.5) * tileH
                    var pzSize = Math.max(3.5, tileW * 1.5)

                    ctx.fillStyle = pz.solved ? "#2ecc71" : pz.color
                    ctx.strokeStyle = "#ffffff"
                    ctx.lineWidth = 1.0

                    // Diamond shape for console
                    ctx.beginPath()
                    ctx.moveTo(pzx, pzy - pzSize)
                    ctx.lineTo(pzx + pzSize, pzy)
                    ctx.lineTo(pzx, pzy + pzSize)
                    ctx.lineTo(pzx - pzSize, pzy)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()

                    if (root.isExpanded) {
                        ctx.fillStyle = "#ffffff"
                        ctx.font = "bold 8px sans-serif"
                        ctx.fillText(pz.label, pzx + pzSize + 2, pzy + 3)
                    }
                }
            }

            // 3.5 Facility Sector / Room Purpose Labels
            if (root.isExpanded && levelManager.currentLevel === 1) {
                var isV2Labels = (levelManager.level1Variant === 2)
                var roomLabels = isV2Labels ? [
                    { name: "CENTRAL SPINE",          r: 24, c: 23, col: "#90caf9" },
                    { name: "SPAWN AIRLOCK",          r: 42, c: 23, col: "#a5d6a7" },
                    { name: "SECTOR K1: SPHINX VAULT", r: 31, c: 10, col: "#ef9a9a" },
                    { name: "SECTOR K2: SHOOTING RANGE", r: 31, c: 38, col: "#ffe082" },
                    { name: "SECTOR K3: SENTINEL PATROL", r: 11, c: 10, col: "#ce93d8" },
                    { name: "SECTOR K4: SWITCHBOARD & CATWALK", r: 11, c: 38, col: "#80deea" },
                    { name: "STORAGE WAREHOUSE",      r: 10, c: 23, col: "#b0bec5" },
                    { name: "EXIT ELEVATOR",          r: 4,  c: 23, col: "#ffcc80" }
                ] : [
                    { name: "CENTRAL SPINE",          r: 24, c: 23, col: "#90caf9" },
                    { name: "SPAWN AIRLOCK",          r: 42, c: 23, col: "#a5d6a7" },
                    { name: "SECTOR K1: SPHINX VAULT", r: 31, c: 10, col: "#ef9a9a" },
                    { name: "SECTOR K2: SHOOTING RANGE", r: 31, c: 38, col: "#ffe082" },
                    { name: "SECTOR K3: SENTINEL PATROL", r: 11, c: 10, col: "#ce93d8" },
                    { name: "SECTOR K4: SWITCHBOARD & CATWALK", r: 11, c: 38, col: "#80deea" },
                    { name: "STORAGE WAREHOUSE",      r: 10, c: 23, col: "#b0bec5" },
                    { name: "EXIT ELEVATOR",          r: 4,  c: 23, col: "#ffcc80" }
                ]

                ctx.textAlign = "center"
                for (var rl = 0; rl < roomLabels.length; ++rl) {
                    var rItem = roomLabels[rl]
                    var rx = (rItem.c + 0.5) * tileW
                    var ry = (rItem.r + 0.5) * tileH
                    ctx.fillStyle = rItem.col
                    ctx.font = "bold 7px sans-serif"
                    ctx.fillText(rItem.name, rx, ry)
                }
                ctx.textAlign = "left"
            }

            // 4. Draw Access Keys
            if (levelManager.levelKeys) {
                var keyColors = ["#e74c3c", "#2ecc71", "#3498db", "#f1c40f"] // Red, Green, Blue, Yellow
                for (var k = 0; k < levelManager.levelKeys.length; ++k) {
                    var keyObj = levelManager.levelKeys[k]
                    if (!keyObj || keyObj.collected) continue

                    var kCol = keyObj.position.x / root.blockSize
                    var kRow = keyObj.position.z / root.blockSize
                    var kx = kCol * tileW
                    var ky = kRow * tileH
                    var kIdx = (keyObj.keyIndex !== undefined) ? keyObj.keyIndex : k
                    var kColor = keyColors[kIdx % 4]

                    ctx.fillStyle = kColor
                    ctx.strokeStyle = "#ffffff"
                    ctx.lineWidth = 1.0
                    ctx.beginPath()
                    ctx.arc(kx, ky, Math.max(3.0, tileW * 1.3), 0, Math.PI * 2)
                    ctx.fill()
                    ctx.stroke()

                    if (root.isExpanded) {
                        ctx.fillStyle = kColor
                        ctx.font = "bold 8px sans-serif"
                        ctx.fillText("K" + kIdx, kx + tileW * 1.5, ky + 3)
                    }
                }
            }

            // 5. Draw Extraction Exit Beacon
            var exitTileCode = (levelManager.currentLevel === 1) ? 4 : ((levelManager.currentLevel === 2) ? 6 : 11)
            for (var er = 0; er < h; ++er) {
                for (var ec = 0; ec < w; ++ec) {
                    if (mapBytes[er * w + ec] === exitTileCode) {
                        var ex = (ec + 0.5) * tileW
                        var ey = (er + 0.5) * tileH
                        ctx.fillStyle = "#f39c12"
                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = 1.2
                        ctx.beginPath()
                        ctx.arc(ex, ey, Math.max(4.0, tileW * 1.8), 0, Math.PI * 2)
                        ctx.fill()
                        ctx.stroke()

                        if (root.isExpanded) {
                            ctx.fillStyle = "#f39c12"
                            ctx.font = "bold 8px sans-serif"
                            ctx.fillText("EXIT", ex + tileW * 2.0, ey + 3)
                        }
                    }
                }
            }

            // 6. Draw Gas Emergency Hazard Beacon
            if (levelManager.currentLevel === 1 && levelManager.gasLeakActive) {
                var gCol = levelManager.gasStationPosition.x / root.blockSize
                var gRow = levelManager.gasStationPosition.z / root.blockSize
                var gx = (gCol + 0.5) * tileW
                var gy = (gRow + 0.5) * tileH

                ctx.fillStyle = "#e74c3c"
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.arc(gx, gy, Math.max(5.0, tileW * 2.2), 0, Math.PI * 2)
                ctx.fill()
                ctx.stroke()

                if (root.isExpanded) {
                    ctx.fillStyle = "#ff5252"
                    ctx.font = "bold 8px sans-serif"
                    ctx.fillText("! GAS LEAK !", gx + tileW * 2.0, gy + 3)
                }
            }
        }
    }

    // ==================== LAYER 2: NEARBY ENEMY RADAR BLIPS ====================
    Canvas {
        id: enemyBlipCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Immediate
        visible: root.enemyManager !== null

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!player || !enemyManager) return

            var pPos = player.position
            var tileW = width / root.mapW
            var tileH = height / root.mapH
            var maxDetectDistSq = 2200.0 * 2200.0 // ~22 tiles radar range

            if (typeof enemyManager.getEnemyList === "function") {
                var enemies = enemyManager.getEnemyList()
                if (enemies) {
                    for (var i = 0; i < enemies.length; ++i) {
                        var e = enemies[i]
                        if (!e || !e.isActive || e.isDead) continue

                        var dx = e.position.x - pPos.x
                        var dz = e.position.z - pPos.z
                        if (dx * dx + dz * dz > maxDetectDistSq) continue

                        var eCol = e.position.x / root.blockSize
                        var eRow = e.position.z / root.blockSize
                        var bx = eCol * tileW
                        var by = eRow * tileH

                        ctx.fillStyle = "#e74c3c"
                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = 0.8
                        ctx.beginPath()
                        ctx.arc(bx, by, Math.max(2.5, tileW * 1.1), 0, Math.PI * 2)
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            }
        }
    }

    // ==================== LAYER 3: PLAYER POSITION & DIRECTION CHEVRON ====================
    Item {
        id: playerMarker
        width: Math.max(14, (root.width / root.mapW) * 4.5)
        height: Math.max(14, (root.height / root.mapH) * 4.5)

        readonly property real px: player ? player.position.x : 0
        readonly property real pz: player ? player.position.z : 0
        readonly property real colFrac: px / (root.mapW * root.blockSize)
        readonly property real rowFrac: pz / (root.mapH * root.blockSize)

        x: Math.max(0, Math.min(root.width - width, colFrac * root.width - width / 2))
        y: Math.max(0, Math.min(root.height - height, rowFrac * root.height - height / 2))

        // Fixed-North HUD: arrow rotates directly with player's horizontal view yaw
        rotation: player ? player.yaw : 0.0

        Canvas {
            anchors.fill: parent
            renderStrategy: Canvas.Immediate
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "#00e5ff"
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 1.4
                ctx.beginPath()
                ctx.moveTo(width / 2, 0)
                ctx.lineTo(width - 1, height - 1)
                ctx.lineTo(width / 2, height * 0.65)
                ctx.lineTo(1, height - 1)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }
        }
    }

    // ==================== LAYER 4: COMPASS & STATUS OVERLAYS ====================
    // Top-Center: Fixed North Indicator
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        width: 14
        height: 12
        color: "#d9101216"
        border.color: "#00e5ff"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "N"
            color: "#00e5ff"
            font.pixelSize: 8
            font.bold: true
        }
    }

    // Top-Left: Level & Tactical Badge
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 2
        height: 12
        width: labelText.width + 8
        color: "#cc101216"
        border.color: "#3300e5ff"
        border.width: 1
        visible: root.isExpanded

        Text {
            id: labelText
            anchors.centerIn: parent
            text: levelManager ? levelManager.currentLevelName.toUpperCase() : "FACILITY RADAR"
            color: "#00e5ff"
            font.pixelSize: 7
            font.bold: true
        }
    }

    // Bottom-Center: Expand/Minimize Hotkey Button
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 3
        width: root.isExpanded ? 80 : 64
        height: 13
        color: "#d9101216"
        border.color: "#3300e5ff"
        border.width: 1
        radius: 2

        Text {
            anchors.centerIn: parent
            text: root.isExpanded ? "[M] MINIMIZE" : "[M] EXPAND"
            color: "#00e5ff"
            font.pixelSize: 7
            font.bold: true
        }
    }

    // Click anywhere on minimap to toggle expanded view
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggleExpanded()
        }
    }
}
