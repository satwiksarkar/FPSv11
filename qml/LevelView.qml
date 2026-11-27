import QtQuick
import QtQuick3D
import FPSLabGame

/**
 * @brief LevelView.qml handles 3D voxel rendering for active Project VANGUARD levels.
 * 
 * Uses C++ TileMapInstancing (subclass of QQuick3DInstancing) to render wall blocks,
 * crates, and core blocks as instanced 3D voxel models with 16x16 Nearest-filtered textures.
 * Floors and ceilings are single large flat boxes per level to maximize framerates.
 */
Node {
    id: root

    property var levelManager: null
    property var player: null
    property var bossArena: null
    property var animationManager: null
    property var puzzleManager: null
    property real cameraYaw: 0.0
    property bool gasLeakActive: false
    property int gasLeakSector: 1 // 1=Maintenance, 2=Research

    readonly property real mapWidthUnits: levelManager ? levelManager.mapWidth * levelManager.blockSize : 1600.0
    readonly property real mapHeightUnits: levelManager ? levelManager.mapHeight * levelManager.blockSize : 1600.0

    // ==================== 16x16 / 64x64 NEAREST-FILTERED TEXTURES ====================
    Texture {
        id: texSteelWall
        source: "../assets/textures/steel_wall.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texStoneWall
        source: "../assets/textures/stone_wall.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texStoneWallAlt
        source: "../assets/textures/stone_wall_alt.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texCrate
        source: "../assets/textures/crate.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texFloorPlate
        source: "../assets/textures/floor_plate.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
        scaleU: Math.max(1.0, root.mapWidthUnits / 100.0)
        scaleV: Math.max(1.0, root.mapHeightUnits / 100.0)
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
    }

    Texture {
        id: texFloorDeck
        source: "../assets/textures/floor_deck.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
        scaleU: Math.max(1.0, root.mapWidthUnits / 100.0)
        scaleV: Math.max(1.0, root.mapHeightUnits / 100.0)
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
    }

    Texture {
        id: texFloorHallway
        source: "../assets/textures/floor_hallway.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
    }

    Texture {
        id: texExitElevator
        source: "../assets/textures/exit_elevator.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texCoreWall
        source: "../assets/textures/core_wall.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texAmmoBox
        source: "../assets/textures/ammo_box.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    Texture {
        id: texContainerRed
        source: "../assets/textures/container_red.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    Texture {
        id: texContainerBlue
        source: "../assets/textures/container_blue.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    Texture {
        id: texContainerOrange
        source: "../assets/textures/container_orange.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    Texture {
        id: texContainerGreen
        source: "../assets/textures/container_green.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    // ==================== 3D FLOATING OBJECTIVE ARROW COMPONENT ====================
    component TaskArrow: Node {
        id: arrowNode
        property color arrowColor: "#00f0ff"
        property real baseHeight: 0
        property real bobDistance: 10
        property real bobSpeed: 900
        property bool active: true

        visible: active

        NumberAnimation on y {
            from: arrowNode.baseHeight
            to: arrowNode.baseHeight + arrowNode.bobDistance
            duration: arrowNode.bobSpeed
            loops: Animation.Infinite
            running: arrowNode.visible
            easing.type: Easing.InOutQuad
        }

        NumberAnimation on eulerRotation.y {
            from: 0
            to: 360
            duration: 3500
            loops: Animation.Infinite
            running: arrowNode.visible
        }

        // Upper Shaft
        Model {
            position: Qt.vector3d(0, 16, 0)
            source: "#Cylinder"
            scale: Qt.vector3d(0.07, 0.22, 0.07)
            materials: [
                PrincipledMaterial {
                    baseColor: arrowNode.arrowColor
                    lighting: PrincipledMaterial.NoLighting
                    emissiveFactor: Qt.vector3d(1.0, 1.0, 1.0)
                }
            ]
        }

        // Downward Pointing Cone Head
        Model {
            position: Qt.vector3d(0, 4, 0)
            eulerRotation: Qt.vector3d(180, 0, 0)
            source: "#Cone"
            scale: Qt.vector3d(0.24, 0.20, 0.24)
            materials: [
                PrincipledMaterial {
                    baseColor: arrowNode.arrowColor
                    lighting: PrincipledMaterial.NoLighting
                    emissiveFactor: Qt.vector3d(1.0, 1.0, 1.0)
                }
            ]
        }

        // Pulsing Holographic Ring
        Model {
            position: Qt.vector3d(0, -2, 0)
            source: "#Cylinder"
            scale: Qt.vector3d(0.32, 0.012, 0.32)
            materials: [
                PrincipledMaterial {
                    baseColor: arrowNode.arrowColor
                    lighting: PrincipledMaterial.NoLighting
                    opacity: 0.6
                }
            ]
        }
    }

    // ==================== ATMOSPHERIC CEILING LIGHT FIXTURE COMPONENT ====================
    component CeilingLightFixture: Node {
        id: fixture
        property color fixtureColor: "#FF1E1E"
        property vector3d emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
        property color pointLightColor: "#FF2A2A"
        property real lightBrightness: 3.5
        property real cullDistance: 1600.0

        // Recessed Dark Steel Housing flush against ceiling
        Model {
            position: Qt.vector3d(0, 4, 0)
            source: "#Cube"
            scale: Qt.vector3d(0.9, 0.08, 1.5)
            materials: [
                PrincipledMaterial {
                    baseColor: "#1a202c"
                    metalness: 0.8
                    roughness: 0.3
                }
            ]
        }

        // Emissive Light Lens (Flush against Ceiling)
        Model {
            position: Qt.vector3d(0, 0, 0)
            source: "#Cube"
            scale: Qt.vector3d(0.7, 0.04, 1.3)
            materials: [
                PrincipledMaterial {
                    baseColor: fixture.fixtureColor
                    lighting: PrincipledMaterial.NoLighting
                    emissiveFactor: fixture.emissiveFactor
                }
            ]
        }

        // Downward PointLight with Distance Culling for Performance (40+ FPS)
        PointLight {
            position: Qt.vector3d(0, -15, 0)
            color: fixture.pointLightColor
            brightness: fixture.lightBrightness
            quadraticFade: 0.00018
            constantFade: 1.0
            linearFade: 0.0
            visible: {
                if (!root.player || !root.player.position) return true;
                var ppos = root.player.position;
                var fx = (fixture.position ? fixture.position.x : fixture.x);
                var fz = (fixture.position ? fixture.position.z : fixture.z);
                var dx = fx - ppos.x;
                var dz = fz - ppos.z;
                return (dx * dx + dz * dz) < (fixture.cullDistance * fixture.cullDistance);
            }
        }
    }

    // ==================== WALL PRINCIPLED MATERIALS ====================
    // Steel Wall Material: high metalness (~0.75), low roughness (~0.35) for flashlight and light reflection
    PrincipledMaterial {
        id: matSteelWall
        baseColorMap: texSteelWall
        baseColor: "#e0e4eb"
        metalness: 0.75
        roughness: 0.35
    }

    // Stone/Concrete Wall Material (Bolted panels)
    PrincipledMaterial {
        id: matStoneWall
        baseColorMap: texStoneWall
        baseColor: "#d5d8de"
        metalness: 0.15
        roughness: 0.85
    }

    // Stone/Concrete Wall Material (Plain un-riveted variant)
    PrincipledMaterial {
        id: matStoneWallAlt
        baseColorMap: texStoneWallAlt
        baseColor: "#d5d8de"
        metalness: 0.15
        roughness: 0.85
    }

    // Level 1 & Level 2 Dark Industrial Metal Deck-Plate Floor Material
    PrincipledMaterial {
        id: matFloorDeck
        baseColorMap: texFloorDeck
        metalness: 0.55
        roughness: 0.45
    }

    // Hallway Walkway Floor Material
    PrincipledMaterial {
        id: matFloorHallway
        baseColorMap: texFloorHallway
        metalness: 0.55
        roughness: 0.45
    }

    // Level 3 Floor Material (Original untouched)
    PrincipledMaterial {
        id: matFloorLevel3
        baseColorMap: texFloorPlate
        roughness: 0.88
        metalness: 0.2
    }

    // ==================== INSTANCED VOXEL BLOCK TABLES ====================
    // 1. Solid Walls - Steel Walls (Corridors, Central Spine, outer bypasses, security corridors; and all walls in Level 3)
    TileMapInstancing {
        id: steelWallInstancing
        levelManager: root.levelManager
        tileType: 1
        wallMaterialType: (root.levelManager && root.levelManager.currentLevel === 3) ? 0 : 1
        blockHeight: (root.levelManager && root.levelManager.currentLevel === 3) ? 6 : 3
        baseColor: "#e0e4eb"
    }

    Model {
        id: steelWallModel
        source: "#Cube"
        instancing: steelWallInstancing
        materials: [ matSteelWall ]
    }

    // 2. Solid Walls - Stone/Concrete Bolted Walls (Standard Rooms)
    TileMapInstancing {
        id: stoneWallInstancing
        levelManager: root.levelManager
        tileType: 1
        wallMaterialType: 2
        blockHeight: (root.levelManager && root.levelManager.currentLevel === 3) ? 6 : 3
        baseColor: "#d5d8de"
    }

    Model {
        id: stoneWallModel
        source: "#Cube"
        instancing: stoneWallInstancing
        visible: root.levelManager && root.levelManager.currentLevel !== 3
        materials: [ matStoneWall ]
    }

    // 3. Solid Walls - Stone/Concrete Plain Un-riveted Walls (Alternating every 2-3 tiles in Standard Rooms)
    TileMapInstancing {
        id: stoneWallAltInstancing
        levelManager: root.levelManager
        tileType: 1
        wallMaterialType: 3
        blockHeight: (root.levelManager && root.levelManager.currentLevel === 3) ? 6 : 3
        baseColor: "#d5d8de"
    }

    Model {
        id: stoneWallAltModel
        source: "#Cube"
        instancing: stoneWallAltInstancing
        visible: root.levelManager && root.levelManager.currentLevel !== 3
        materials: [ matStoneWallAlt ]
    }

    // 2. Shipping Crates (Tile 2, Height 2 blocks = 200 units)
    TileMapInstancing {
        id: crateInstancing
        levelManager: root.levelManager
        tileType: 2
        blockHeight: 2
        baseColor: "#f0d0a0"
    }

    Model {
        id: crateModel
        source: "#Cube"
        instancing: crateInstancing
        materials: [
            PrincipledMaterial {
                baseColorMap: texCrate
                roughness: 0.90
                metalness: 0.15
            }
        ]
    }

    // 3. VANGUARD Armored Core Wall (Tile 9, Height 4 blocks = 400 units)
    TileMapInstancing {
        id: coreInstancing
        levelManager: root.levelManager
        tileType: 9
        blockHeight: 4
        baseColor: (root.bossArena && root.bossArena.isBossDefeated) ? "#2b2e35" : "#ff3d00"
    }

    Model {
        id: coreModel
        source: "#Cube"
        instancing: coreInstancing
        materials: [
            PrincipledMaterial {
                baseColorMap: texCoreWall
                roughness: 0.50
                metalness: 0.40
                emissiveFactor: (root.bossArena && root.bossArena.isBossDefeated)
                    ? Qt.vector3d(0.05, 0.05, 0.05)
                    : Qt.vector3d(1.0, 0.35, 0.1)
            }
        ]
    }

    // Level 3 Central Energy Beacon rising from Logic Core
    Node {
        id: coreBeaconNode
        visible: root.levelManager && root.levelManager.currentLevel === 3
        position: Qt.vector3d(2000, 480, 2000)

        // Outer pulsing cylindrical energy beam
        Model {
            source: "#Cylinder"
            scale: Qt.vector3d(1.8, 2.2, 1.8)
            materials: [
                PrincipledMaterial {
                    baseColor: (root.bossArena && root.bossArena.isBossDefeated) ? "#2b2e35" : "#ff3d00"
                    lighting: PrincipledMaterial.NoLighting
                    opacity: (root.bossArena && root.bossArena.isBossDefeated) ? 0.0 : 0.80
                }
            ]
        }

        // Inner glowing core plasma conduit
        Model {
            source: "#Cylinder"
            scale: Qt.vector3d(0.9, 2.4, 0.9)
            materials: [
                PrincipledMaterial {
                    baseColor: (root.bossArena && root.bossArena.isBossDefeated) ? "#1a1a1a" : "#ffeaa7"
                    lighting: PrincipledMaterial.NoLighting
                    opacity: (root.bossArena && root.bossArena.isBossDefeated) ? 0.0 : 0.95
                }
            ]
        }
    }

    // Central VANGUARD Core Overhead Arena Floodlight
    PointLight {
        id: coreTopLight
        position: Qt.vector3d(2000, 480, 2000)
        color: "#ff5722"
        brightness: 10.0
        visible: root.levelManager && root.levelManager.currentLevel === 3 && !(root.bossArena && root.bossArena.isBossDefeated)
    }

    // Core Face Lights (placed outside 4x4 solid walls to brightly illuminate floor & vents)
    PointLight {
        position: Qt.vector3d(2000, 150, 1600) // North face
        color: "#ff3d00"
        brightness: 7.0
        visible: root.levelManager && root.levelManager.currentLevel === 3 && !(root.bossArena && root.bossArena.isBossDefeated)
    }
    PointLight {
        position: Qt.vector3d(2000, 150, 2400) // South face
        color: "#ff3d00"
        brightness: 7.0
        visible: root.levelManager && root.levelManager.currentLevel === 3 && !(root.bossArena && root.bossArena.isBossDefeated)
    }
    PointLight {
        position: Qt.vector3d(1600, 150, 2000) // West face
        color: "#ff3d00"
        brightness: 7.0
        visible: root.levelManager && root.levelManager.currentLevel === 3 && !(root.bossArena && root.bossArena.isBossDefeated)
    }
    PointLight {
        position: Qt.vector3d(2400, 150, 2000) // East face
        color: "#ff3d00"
        brightness: 7.0
        visible: root.levelManager && root.levelManager.currentLevel === 3 && !(root.bossArena && root.bossArena.isBossDefeated)
    }

    // Level 3 4 Corner Arena Industrial Floodlights
    PointLight {
        position: Qt.vector3d(750, 320, 750)
        color: "#74b9ff"
        brightness: 6.5
        visible: root.levelManager && root.levelManager.currentLevel === 3
    }
    PointLight {
        position: Qt.vector3d(3250, 320, 750)
        color: "#74b9ff"
        brightness: 6.5
        visible: root.levelManager && root.levelManager.currentLevel === 3
    }
    PointLight {
        position: Qt.vector3d(750, 320, 3250)
        color: "#74b9ff"
        brightness: 6.5
        visible: root.levelManager && root.levelManager.currentLevel === 3
    }
    PointLight {
        position: Qt.vector3d(3250, 320, 3250)
        color: "#74b9ff"
        brightness: 6.5
        visible: root.levelManager && root.levelManager.currentLevel === 3
    }

    // 4. Ammo Pickups (Tile 5, Height 1 block, styled military ammo cache)
    TileMapInstancing {
        id: ammoInstancing
        levelManager: root.levelManager
        tileType: 5
        blockHeight: 1
        baseColor: "#ffffff"
    }

    Model {
        id: ammoModel
        source: "#Cube"
        instancing: ammoInstancing
        scale: Qt.vector3d(0.55, 0.38, 0.45)
        materials: [
            PrincipledMaterial {
                baseColorMap: texAmmoBox
                roughness: 0.45
                metalness: 0.55
            }
        ]
    }

    // ==================== FLAT LEVEL FLOOR & CEILING ====================
    // Single large flat floor box (Level 1 & 2: Dark Industrial Metal Deck Plate; Level 3: Original)
    Model {
        id: floorBox
        source: "#Cube"
        scale: Qt.vector3d(root.mapWidthUnits / 100.0, 0.2, root.mapHeightUnits / 100.0)
        position: Qt.vector3d(root.mapWidthUnits * 0.5, -10, root.mapHeightUnits * 0.5)
        materials: [
            (root.levelManager && root.levelManager.currentLevel === 3) ? matFloorLevel3 : matFloorDeck
        ]
    }

    // Hallway Walkway Strip Component (Level 1 & Level 2)
    component WalkwayStrip: Model {
        id: strip
        property real widthBlocks: 2.0
        property real lengthBlocks: 10.0
        source: "#Cube"
        scale: Qt.vector3d(widthBlocks, 0.01, lengthBlocks)
        materials: [
            PrincipledMaterial {
                baseColorMap: Texture {
                    source: "../assets/textures/floor_hallway.png"
                    magFilter: Texture.Nearest
                    minFilter: Texture.Nearest
                    generateMipmaps: false
                    scaleU: strip.widthBlocks
                    scaleV: strip.lengthBlocks
                    tilingModeHorizontal: Texture.Repeat
                    tilingModeVertical: Texture.Repeat
                }
                metalness: 0.55
                roughness: 0.45
            }
        ]
    }

    // ==================== LEVEL 1 HALLWAY WALKWAYS ====================
    Node {
        id: level1WalkwaysNode
        visible: root.levelManager && root.levelManager.currentLevel === 1

        // 1. Central Spine Transit Corridor (North-South, Row 5..40, Col 23 center)
        WalkwayStrip {
            position: Qt.vector3d(2350, 0.5, 2300)
            widthBlocks: 2.0
            lengthBlocks: 36.0
        }

        // 2. West Outer Bypass Hallway (North-South, Row 18..24, Col 6.5)
        WalkwayStrip {
            position: Qt.vector3d(650, 0.5, 2150)
            widthBlocks: 1.2
            lengthBlocks: 7.0
        }

        // 3. East Outer Bypass Hallway (North-South, Row 18..24, Col 42.5)
        WalkwayStrip {
            position: Qt.vector3d(4250, 0.5, 2150)
            widthBlocks: 1.2
            lengthBlocks: 7.0
        }

        // 4. North Transverse Connector Corridor (East-West, Row 10, Z=1050)
        WalkwayStrip {
            position: Qt.vector3d(2350, 0.5, 1050)
            widthBlocks: 1.2
            lengthBlocks: 20.0
            eulerRotation: Qt.vector3d(0, 90, 0)
        }

        // 5. South Transverse Connector Corridor (East-West, Row 32, Z=3250)
        WalkwayStrip {
            position: Qt.vector3d(2350, 0.5, 3250)
            widthBlocks: 1.2
            lengthBlocks: 20.0
            eulerRotation: Qt.vector3d(0, 90, 0)
        }
    }

    // ==================== LEVEL 2 HALLWAY WALKWAYS ====================
    Node {
        id: level2WalkwaysNode
        visible: root.levelManager && root.levelManager.currentLevel === 2

        // 1. West Corridor (Main Arterial from Spawn, North-South, Row 36..57, Col 4.5)
        WalkwayStrip {
            position: Qt.vector3d(450, 0.5, 4650)
            widthBlocks: 1.5
            lengthBlocks: 21.0
        }

        // 2. North Access Corridor (East-West, Row 11..12, Z=1200, Col 35..50)
        WalkwayStrip {
            position: Qt.vector3d(4250, 0.5, 1200)
            widthBlocks: 1.5
            lengthBlocks: 15.0
            eulerRotation: Qt.vector3d(0, 90, 0)
        }

        // 3. East Security Corridor (North-South, Row 20..46, Z=3300, Col 55)
        WalkwayStrip {
            position: Qt.vector3d(5500, 0.5, 3300)
            widthBlocks: 1.8
            lengthBlocks: 26.0
        }

        // 4. Descent Approach Corridor (North-South, Row 48..52, Z=5000, Col 46)
        WalkwayStrip {
            position: Qt.vector3d(4600, 0.5, 5000)
            widthBlocks: 1.5
            lengthBlocks: 4.0
        }
    }

    // Single large flat ceiling box for Level 2 & 3 (raised to 600 in Level 3 for grand cathedral arena)
    Model {
        id: ceilingBox
        visible: root.levelManager && root.levelManager.currentLevel !== 1
        source: "#Cube"
        scale: Qt.vector3d(root.mapWidthUnits / 100.0, 0.2, root.mapHeightUnits / 100.0)
        position: Qt.vector3d(root.mapWidthUnits * 0.5, (root.levelManager && root.levelManager.currentLevel === 3) ? 600 : 310, root.mapHeightUnits * 0.5)
        materials: [
            PrincipledMaterial {
                baseColor: "#14171d"
                roughness: 0.95
            }
        ]
    }

    // Level 1 Sectional Ceilings (leaves Shooting Gallery open to high ceiling at Y=750)
    Node {
        id: level1Ceilings
        visible: root.levelManager && root.levelManager.currentLevel === 1

        // West Sector Ceiling (X: 0..3300, Z: 0..4800, Y=310)
        Model {
            position: Qt.vector3d(1650, 310, 2400)
            source: "#Cube"
            scale: Qt.vector3d(33.0, 0.2, 48.0)
            materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
        }
        // East Border Corridor Ceiling (X: 4300..4800, Z: 0..4800, Y=310)
        Model {
            position: Qt.vector3d(4550, 310, 2400)
            source: "#Cube"
            scale: Qt.vector3d(5.0, 0.2, 48.0)
            materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
        }
        // Northeast Sector Ceiling - North Corridor above Key Room 4 (X: 3300..4300, Z: 0..600, Y=310)
        Model {
            position: Qt.vector3d(3800, 310, 300)
            source: "#Cube"
            scale: Qt.vector3d(10.0, 0.2, 6.0)
            materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
        }
        // Northeast Sector Ceiling - South Corridor below Key Room 4 (X: 3300..4300, Z: 1800..2400, Y=310)
        Model {
            position: Qt.vector3d(3800, 310, 2100)
            source: "#Cube"
            scale: Qt.vector3d(10.0, 0.2, 6.0)
            materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
        }
        // Southeast Border Ceiling below Shooting Gallery (X: 3300..4300, Z: 3600..4800, Y=310)
        Model {
            position: Qt.vector3d(3800, 310, 4200)
            source: "#Cube"
            scale: Qt.vector3d(10.0, 0.2, 12.0)
            materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
        }
    }

    // ==================== EXIT PLATFORM MARKER (TILES 4, 6 & 11) ====================
    Node {
        id: exitPlatformMarker

        // Floating 3D Navigation Arrow over Freight Elevator Gate when all Level 1 objectives are met
        TaskArrow {
            id: arrowFreightElevator
            position: Qt.vector3d(2350, 120, 500)
            baseHeight: 120
            arrowColor: "#2ecc71" // Emerald Green
            active: root.levelManager && root.levelManager.currentLevel === 1 &&
                    root.levelManager.collectedKeysCount >= 4 &&
                    root.levelManager.circuitPuzzleCompleted
        }

        visible: root.levelManager && (
                     root.levelManager.currentLevel === 1 ||
                     root.levelManager.currentLevel === 2 ||
                     (root.levelManager.currentLevel === 3 &&
                      root.levelManager.getTileAtWorldPos(root.levelManager.exitCenterPosition.x,
                                                          root.levelManager.exitCenterPosition.z) === 11))
        position: root.levelManager ? root.levelManager.exitCenterPosition : Qt.vector3d(1350, 2, 250)

        Model {
            source: "#Cube"
            scale: (root.levelManager && (root.levelManager.currentLevel === 1 || root.levelManager.currentLevel === 2))
                   ? Qt.vector3d(3.0, 0.08, 3.0)
                   : Qt.vector3d(1.0, 0.08, 1.0)
            materials: [
                PrincipledMaterial {
                    baseColorMap: texExitElevator
                    roughness: 0.4
                    metalness: 0.3
                }
            ]
        }

        PointLight {
            position: Qt.vector3d(0, 80, 0)
            color: (root.levelManager && root.levelManager.currentLevel === 1) ? "#2ecc71" : "#9b59b6"
            brightness: 4.0 + 4.0 * (root.animationManager ? root.animationManager.elevatorGlow : 0.75)
        }

        // Voxel exit beam column (Stage V8 elevator glow)
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 140, 0)
            scale: Qt.vector3d(0.8, 2.8, 0.8)
            materials: [
                PrincipledMaterial {
                    baseColor: (root.levelManager && root.levelManager.currentLevel === 1) ? "#2ecc71" : "#9b59b6"
                    opacity: 0.25 + 0.35 * (root.animationManager ? root.animationManager.elevatorGlow : 0.5)
                    lighting: PrincipledMaterial.NoLighting
                }
            ]
        }
    }

    // ==================== HEAVY WEAPON PICKUP (TILE 7) ====================
    Node {
        id: heavyWeaponPickupNode
        visible: root.levelManager && root.levelManager.currentLevel === 2 && !root.levelManager.heavyWeaponCollected
        position: root.levelManager ? root.levelManager.heavyWeaponSpawnPosition : Qt.vector3d(1050, 25, 6150)

        property real rotAngle: 0.0
        NumberAnimation on rotAngle {
            from: 0; to: 360; duration: 3000; loops: Animation.Infinite; running: true
        }
        eulerRotation: Qt.vector3d(15, rotAngle, 0)

        // Floating Plasma Repeater Voxel Model
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.12, 0.16, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.4; metalness: 0.8 } ]
        }
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.08, 0.08, 0.85)
            position: Qt.vector3d(0, 0.04, 0.1)
            materials: [ PrincipledMaterial { baseColor: "#00e5ff"; roughness: 0.2; lighting: PrincipledMaterial.NoLighting } ]
        }
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.16, 0.12, 0.25)
            position: Qt.vector3d(0, 0.10, -0.15)
            materials: [ PrincipledMaterial { baseColor: "#8e44ad"; roughness: 0.3 } ]
        }
        PointLight {
            position: Qt.vector3d(0, 30, 0)
            color: "#00e5ff"
            brightness: 5.0
        }
    }

    // ==================== LEVEL 3 COOLING VENTS (Rendered via VentModel) ====================
    Repeater3D {
        model: (root.bossArena && root.levelManager && root.levelManager.currentLevel === 3) ? root.bossArena.ventCount() : 0

        VentModel {
            vent: root.bossArena ? root.bossArena.ventAt(index) : null
            cameraYaw: root.cameraYaw
        }
    }

    // ==================== INTERACTIVE BULKHEAD DOORS (Rendered via DoorModel) ====================
    Repeater3D {
        model: root.levelManager ? root.levelManager.doors : []

        DoorModel {
            door: modelData
            pocketTexture: texSteelWall
        }
    }

    // ==================== COLLECTIBLE ACCESS KEYS (Rendered via AccessKeyModel) ====================
    Repeater3D {
        model: root.levelManager ? root.levelManager.levelKeys : []

        AccessKeyModel {
            keyPickup: modelData
        }
    }

    // ==================== LEVEL 1 INTERACTIVE PUZZLE CONSOLES & BARRIERS ====================
    Node {
        id: level1PuzzlesNode
        visible: root.levelManager && root.levelManager.currentLevel === 1

        // ==================== 1. CENTRAL SPINE: COVER PILLARS & SPRINT SENSORS ====================
        Node {
            id: centralSpineGroup

            // Staggered Full-Height Cover Pillars (Ceiling: 4.5m = 450 units)
            Model {
                position: Qt.vector3d(2250, 225, 3350)
                source: "#Cube"
                scale: Qt.vector3d(0.8, 4.5, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.7; metalness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2450, 225, 2850)
                source: "#Cube"
                scale: Qt.vector3d(0.8, 4.5, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.7; metalness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2250, 225, 2250)
                source: "#Cube"
                scale: Qt.vector3d(0.8, 4.5, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.7; metalness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2450, 225, 1750)
                source: "#Cube"
                scale: Qt.vector3d(0.8, 4.5, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.7; metalness: 0.5 } ]
            }

            // --- Sprint Sensor 1 (South Spine: Row 36, Z=3650) ---
            Node {
                position: Qt.vector3d(2350, 0, 3650)
                // Left & Right Laser Emitters
                Model {
                    position: Qt.vector3d(-180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                // Floor Laser Trip Beam across corridor
                Model {
                    position: Qt.vector3d(0, 8, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(3.6, 0.08, 0.08)
                    materials: [ PrincipledMaterial {
                        baseColor: "#f39c12"
                        lighting: PrincipledMaterial.NoLighting
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 30, 0)
                    color: "#f39c12"
                    brightness: 3.5
                }
            }

            // --- Sprint Sensor 2 (Mid Spine: Row 25, Z=2550) ---
            Node {
                position: Qt.vector3d(2350, 0, 2550)
                Model {
                    position: Qt.vector3d(-180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(0, 8, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(3.6, 0.08, 0.08)
                    materials: [ PrincipledMaterial {
                        baseColor: "#f39c12"
                        lighting: PrincipledMaterial.NoLighting
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 30, 0)
                    color: "#f39c12"
                    brightness: 3.5
                }
            }

            // --- Sprint Sensor 3 (North Spine: Row 15, Z=1550) ---
            Node {
                position: Qt.vector3d(2350, 0, 1550)
                Model {
                    position: Qt.vector3d(-180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(180, 50, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 1.0, 0.25)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(0, 8, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(3.6, 0.08, 0.08)
                    materials: [ PrincipledMaterial {
                        baseColor: "#f39c12"
                        lighting: PrincipledMaterial.NoLighting
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 30, 0)
                    color: "#f39c12"
                    brightness: 3.5
                }
            }
        }

        // ==================== 2. KEY 1: SPHINX VAULT (SOUTHWEST) ====================
        Node {
            id: kitingBayGroup

            // Ambient ceiling light for Key 1 Chamber
            PointLight {
                position: Qt.vector3d(1050, 280, 3150)
                color: "#00e5ff"
                brightness: 3.5
            }

            // High-intensity floodlight illuminating the Vault facade & door
            PointLight {
                position: Qt.vector3d(900, 200, 3150)
                color: "#d5e8f7"
                brightness: 6.0
            }

            // --- Armored Wall Vault Enclosure holding Key 1 at (650, 35, 3150) ---
            // Back Wall (West)
            Model {
                position: Qt.vector3d(520, 110, 3150)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 2.2, 2.2)
                materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#34495e"; roughness: 0.45; metalness: 0.65 } ]
            }
            // North Vault Wall
            Model {
                position: Qt.vector3d(635, 110, 3050)
                source: "#Cube"
                scale: Qt.vector3d(2.1, 2.2, 0.2)
                materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#34495e"; roughness: 0.45; metalness: 0.65 } ]
            }
            // South Vault Wall
            Model {
                position: Qt.vector3d(635, 110, 3250)
                source: "#Cube"
                scale: Qt.vector3d(2.1, 2.2, 0.2)
                materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#34495e"; roughness: 0.45; metalness: 0.65 } ]
            }
            // Top Vault Ceiling Slab
            Model {
                position: Qt.vector3d(635, 220, 3150)
                source: "#Cube"
                scale: Qt.vector3d(2.3, 0.2, 2.2)
                materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#2c3e50"; roughness: 0.45; metalness: 0.7 } ]
            }

            // Heavy Structural Corner Framing Pillars
            Model {
                position: Qt.vector3d(520, 110, 3050)
                source: "#Cube"
                scale: Qt.vector3d(0.24, 2.24, 0.24)
                materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.4; metalness: 0.85 } ]
            }
            Model {
                position: Qt.vector3d(520, 110, 3250)
                source: "#Cube"
                scale: Qt.vector3d(0.24, 2.24, 0.24)
                materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.4; metalness: 0.85 } ]
            }
            Model {
                position: Qt.vector3d(740, 110, 3050)
                source: "#Cube"
                scale: Qt.vector3d(0.24, 2.24, 0.24)
                materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.4; metalness: 0.85 } ]
            }
            Model {
                position: Qt.vector3d(740, 110, 3250)
                source: "#Cube"
                scale: Qt.vector3d(0.24, 2.24, 0.24)
                materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.4; metalness: 0.85 } ]
            }

            // Hazard Warning Roof Perimeter Rails
            Model {
                position: Qt.vector3d(635, 225, 3050)
                source: "#Cube"
                scale: Qt.vector3d(2.35, 0.1, 0.1)
                materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(635, 225, 3250)
                source: "#Cube"
                scale: Qt.vector3d(2.35, 0.1, 0.1)
                materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(740, 225, 3150)
                source: "#Cube"
                scale: Qt.vector3d(0.1, 0.1, 2.25)
                materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
            }

            // Interior Key 1 Display Pedestal Structure
            Model {
                position: Qt.vector3d(650, 8, 3150)
                source: "#Cylinder"
                scale: Qt.vector3d(1.1, 0.16, 1.1)
                materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#1b2631"; roughness: 0.4; metalness: 0.85 } ]
            }
            Model {
                position: Qt.vector3d(650, 24, 3150)
                source: "#Cylinder"
                scale: Qt.vector3d(0.7, 0.24, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.3; metalness: 0.9 } ]
            }
            Model {
                position: Qt.vector3d(650, 36, 3150)
                source: "#Cylinder"
                scale: Qt.vector3d(0.74, 0.04, 0.74)
                materials: [ PrincipledMaterial { baseColor: "#00f0ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(650, 180, 3150)
                color: "#00f0ff"
                brightness: 7.0
            }

            // Heavy Sliding Armored Vault Door at Front (X=740)
            Node {
                id: vaultDoorNode
                position: Qt.vector3d(740, 110, (root.puzzleManager && root.puzzleManager.riddleSolved) ? 3360 : 3150)
                Behavior on position {
                    Vector3dAnimation { duration: 1200; easing.type: Easing.InOutQuad }
                }

                // Blast Door Slab
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.25, 2.15, 1.8)
                    materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#475965"; roughness: 0.4; metalness: 0.75 } ]
                }
                // Door Top & Bottom Hazard Edge Trims
                Model {
                    position: Qt.vector3d(13, 98, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.04, 0.12, 1.76)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(13, -98, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.04, 0.12, 1.76)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }
                // Central Radial Locking Wheel
                Model {
                    position: Qt.vector3d(15, 0, 0)
                    eulerRotation.z: 90
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.85, 0.14, 0.85)
                    materials: [ PrincipledMaterial { baseColor: "#e67e22"; roughness: 0.3; metalness: 0.85 } ]
                }
                // Wheel Cross Spokes
                Model {
                    position: Qt.vector3d(17, 0, 0)
                    eulerRotation.z: 90
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.16, 0.82)
                    materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.4; metalness: 0.85 } ]
                }
                Model {
                    position: Qt.vector3d(17, 0, 0)
                    eulerRotation.z: 90
                    eulerRotation.y: 90
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.16, 0.82)
                    materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.4; metalness: 0.85 } ]
                }
                // Center Hub Cap
                Model {
                    position: Qt.vector3d(19, 0, 0)
                    eulerRotation.z: 90
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.35, 0.18, 0.35)
                    materials: [ PrincipledMaterial { baseColor: "#f1c40f"; roughness: 0.3; metalness: 0.9 } ]
                }
                // Door Locking Status Beacon Bar
                Model {
                    position: Qt.vector3d(14, 75, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.04, 0.10, 0.60)
                    materials: [ PrincipledMaterial { baseColor: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#e74c3c"; lighting: PrincipledMaterial.NoLighting } ]
                }
                PointLight {
                    position: Qt.vector3d(30, 75, 0)
                    color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#e74c3c"
                    brightness: 6.0
                }
            }

            // Floating 3D Navigation Arrow over the Vault
            TaskArrow {
                id: arrowVault
                position: Qt.vector3d(635, 230, 3150)
                baseHeight: 230
                arrowColor: "#f39c12" // Vibrant Gold
                active: root.levelManager && root.levelManager.currentLevel === 1 && !root.levelManager.vaultUnlocked
            }

            // --- Interactive Wall Terminal mounted on Front Face of Vault at (755, 115, 2980) ---
            Node {
                id: vaultTerminalNode
                position: Qt.vector3d(755, 115, 2980)
                eulerRotation.y: 90

                // Sleek Angled Console Pedestal Column
                Model {
                    position: Qt.vector3d(0, -45, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.5, 1.4, 0.3)
                    materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#2c3e50"; roughness: 0.4; metalness: 0.75 } ]
                }
                // Angled Keyboard / Deck Shelf
                Model {
                    position: Qt.vector3d(0, -15, 14)
                    eulerRotation.x: -25
                    source: "#Cube"
                    scale: Qt.vector3d(0.65, 0.08, 0.35)
                    materials: [ PrincipledMaterial { baseColor: "#22313f"; roughness: 0.3; metalness: 0.7 } ]
                }
                // Backlit Keypad Deck Glow
                Model {
                    position: Qt.vector3d(0, -13, 15)
                    eulerRotation.x: -25
                    source: "#Cube"
                    scale: Qt.vector3d(0.55, 0.04, 0.22)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting; opacity: 0.75 } ]
                }
                // Monitor Frame Bezel Housing
                Model {
                    position: Qt.vector3d(0, 30, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.9, 0.65, 0.12)
                    materials: [ PrincipledMaterial { baseColor: "#0b0f14"; roughness: 0.3; metalness: 0.9 } ]
                }
                // CRT Screen with High-Tech Sci-Fi Holographic Interface
                Model {
                    position: Qt.vector3d(0, 30, 7)
                    source: "#Cube"
                    scale: Qt.vector3d(0.82, 0.56, 0.03)
                    materials: [ DefaultMaterial {
                        lighting: DefaultMaterial.NoLighting
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 512; height: 350
                                color: "#040b14"
                                border.color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"
                                border.width: 6
                                radius: 8

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 8

                                    // Top Tech Header
                                    Row {
                                        width: parent.width
                                        spacing: 8
                                        Rectangle {
                                            width: 12; height: 12; radius: 6
                                            color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "VANGUARD SEC-OS // SPHINX TERMINAL 01"
                                            color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"
                                            font.pixelSize: 18
                                            font.bold: true
                                            font.letterSpacing: 2
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 2
                                        color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"
                                        opacity: 0.6
                                    }

                                    // Central Display Box
                                    Rectangle {
                                        width: parent.width; height: 200
                                        color: "#081320"
                                        border.color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#27ae60" : "#0099cc"
                                        border.width: 2
                                        radius: 6

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 10

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "ACCESS GRANTED" : "VAULT ENCRYPTED"
                                                color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#f1c40f"
                                                font.pixelSize: 34
                                                font.bold: true
                                                font.letterSpacing: 3
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "SECURITY CIPHER CONFIRMED // DOOR OPEN" : "COGNITIVE SPHINX CIPHER LOCK ENGAGED"
                                                color: "#8fa0b2"
                                                font.pixelSize: 15
                                                font.bold: true
                                            }

                                            // Glowing Action Button
                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 380; height: 50
                                                radius: 6
                                                color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "VAULT UNLOCKED" : "[ E ] ACCESS TERMINAL"
                                                    color: "#000000"
                                                    font.pixelSize: 24
                                                    font.bold: true
                                                    font.letterSpacing: 2
                                                }
                                            }
                                        }
                                    }

                                    // Tech Footer
                                    Row {
                                        width: parent.width
                                        Text {
                                            text: "CHIEF ENGINEER PROTOCOL #402-V"
                                            color: "#4a6572"
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Item { width: 40; height: 1 }
                                        Text {
                                            text: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "STATUS: DISENGAGED" : "STATUS: RESTRICTED"
                                            color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#e74c3c"
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    } ]
                }
                // Terminal Ambient Screen Glow
                PointLight {
                    position: Qt.vector3d(0, 30, 35)
                    color: (root.puzzleManager && root.puzzleManager.riddleSolved) ? "#2ecc71" : "#00f0ff"
                    brightness: 6.0
                }
            }

            // Wall Monitor displaying Security Digit K1
            Node {
                position: Qt.vector3d(950, 150, 2615)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.4, 0.9, 0.1)
                    materials: [ PrincipledMaterial { baseColor: "#0d1117"; roughness: 0.5 } ]
                }
                Model {
                    position: Qt.vector3d(0, 0, 6)
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 0.7, 0.05)
                    materials: [ DefaultMaterial {
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 256; height: 160
                                color: "#050d1a"
                                border.color: "#00e5ff"
                                border.width: 4
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "SECTOR K1"
                                        color: "#7f8c8d"
                                        font.pixelSize: 22
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "ACCESS KEY 1"
                                        color: "#00e5ff"
                                        font.pixelSize: 32
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 0, 15)
                    color: "#00e5ff"
                    brightness: 3.0
                }
            }
        }

        // ==================== 3. KEY 2: SHOOTING GALLERY (SOUTHEAST) ====================
        Node {
            id: shootingGalleryGroup

            // --- Tall Enclosure Architecture (Ceiling Y=750, Height=7.5m) ---
            // High Ceiling Slab (3300..4300, 2400..3600, Y=750)
            Model {
                position: Qt.vector3d(3800, 750, 3000)
                source: "#Cube"
                scale: Qt.vector3d(10.2, 0.2, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
            }

            // Upper Perimeter Enclosing Walls (Y: 300 to 750, Height=450, Center Y=525)
            // North Upper Wall (Z=2400)
            Model {
                position: Qt.vector3d(3800, 525, 2400)
                source: "#Cube"
                scale: Qt.vector3d(10.2, 4.5, 0.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // South Upper Wall (Z=3600)
            Model {
                position: Qt.vector3d(3800, 525, 3600)
                source: "#Cube"
                scale: Qt.vector3d(10.2, 4.5, 0.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // East Upper Wall (X=4300)
            Model {
                position: Qt.vector3d(4300, 525, 3000)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 4.5, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // West Upper Wall Partition above 3m entrance doorway (X=3300)
            Model {
                position: Qt.vector3d(3300, 525, 3000)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 4.5, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }

            // Overhead Industrial Steel Rafter Beams (Y=620)
            Model {
                position: Qt.vector3d(3800, 620, 2750)
                source: "#Cube"
                scale: Qt.vector3d(10.0, 0.4, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(3800, 620, 3050)
                source: "#Cube"
                scale: Qt.vector3d(10.0, 0.4, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(3800, 620, 3350)
                source: "#Cube"
                scale: Qt.vector3d(10.0, 0.4, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
            }

            // STRICT EXCEPTION: Key 2 Room has ZERO ceiling lights or overhead floodlights per strict specification.
            // Room is completely dark so player must rely on flashlight [F] and enemy visor glow.

            // Staggered Waist-High Firing Barricades (1.2m tall = 120 units, Y=60)
            // Row 1 (Z=2850)
            Model {
                position: Qt.vector3d(3550, 60, 2850)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(3850, 60, 2850)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(4150, 60, 2850)
                source: "#Cube"
                scale: Qt.vector3d(1.4, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }

            // Row 2 (Z=3150)
            Model {
                position: Qt.vector3d(3450, 60, 3150)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(3750, 60, 3150)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(4050, 60, 3150)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }

            // Row 3 (Z=3450)
            Model {
                position: Qt.vector3d(3550, 60, 3450)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(3850, 60, 3450)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(4150, 60, 3450)
                source: "#Cube"
                scale: Qt.vector3d(1.4, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }

            // Laser-Caged Alcove holding Key 2 at (4150, 0, 2650)
            Node {
                id: laserCageGroup
                visible: root.levelManager ? root.levelManager.laserCageActive : true
                position: Qt.vector3d(4150, 0, 2650)

                // 4 Corner Laser Posts
                Model {
                    position: Qt.vector3d(-40, 100, -40)
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 2.0, 0.12)
                    materials: [ PrincipledMaterial { baseColor: "#ff0033"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(40, 100, -40)
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 2.0, 0.12)
                    materials: [ PrincipledMaterial { baseColor: "#ff0033"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(-40, 100, 40)
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 2.0, 0.12)
                    materials: [ PrincipledMaterial { baseColor: "#ff0033"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(40, 100, 40)
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 2.0, 0.12)
                    materials: [ PrincipledMaterial { baseColor: "#ff0033"; lighting: PrincipledMaterial.NoLighting } ]
                }
                // Laser containment plane
                Model {
                    position: Qt.vector3d(0, 100, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(0.8, 2.0, 0.8)
                    materials: [ PrincipledMaterial {
                        baseColor: "#ff0033"
                        opacity: 0.35
                        lighting: PrincipledMaterial.NoLighting
                    } ]
                }
                // Laser cage containment plane and posts provide unlit neon visibility without casting ambient light
            }

            // Floating 3D Navigation Arrow directly over the Laser Cage Alcove at (4150, 215, 2650)
            TaskArrow {
                id: arrowLaserCage
                position: Qt.vector3d(4150, 215, 2650)
                baseHeight: 215
                arrowColor: (!root.levelManager || root.levelManager.laserCageDisabled) ? "#00e5ff" : "#ff4757"
                active: root.levelManager && root.levelManager.currentLevel === 1 && !root.levelManager.isKeyCollected(1)
            }

            // 3 Shootable Glowing Power Targets hanging from Rafters (Y=380..420)
            Repeater3D {
                model: (root.levelManager && root.levelManager.powerRelays) ? root.levelManager.powerRelays : []
                delegate: Node {
                    visible: !modelData.destroyed
                    position: Qt.vector3d(modelData.x, modelData.y, modelData.z)

                    // Vertical mounting suspension rod from rafter down to target
                    Model {
                        position: Qt.vector3d(0, 100, 0)
                        source: "#Cylinder"
                        scale: Qt.vector3d(0.06, 2.0, 0.06)
                        materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
                    }

                    // Target outer cyan bullseye ring
                    Model {
                        source: "#Cylinder"
                        scale: Qt.vector3d(0.55, 0.07, 0.55)
                        materials: [ PrincipledMaterial {
                            baseColor: "#00e5ff"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Target inner amber concentric ring (perpendicular cross-disc for 360-degree visibility)
                    Model {
                        source: "#Cylinder"
                        eulerRotation: Qt.vector3d(90, 0, 0)
                        scale: Qt.vector3d(0.42, 0.05, 0.42)
                        materials: [ PrincipledMaterial {
                            baseColor: "#f39c12"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Glowing Ruby Bullseye Core
                    Model {
                        source: "#Sphere"
                        scale: Qt.vector3d(0.25, 0.25, 0.25)
                        materials: [ PrincipledMaterial {
                            baseColor: "#ff0055"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Target bullseye sphere provides unlit neon beacon without casting ambient light
                }
            }

            // Wall Monitor displaying Security Digit K2
            Node {
                position: Qt.vector3d(4285, 150, 3050)
                eulerRotation.y: -90
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.4, 0.9, 0.1)
                    materials: [ PrincipledMaterial { baseColor: "#0d1117"; roughness: 0.5 } ]
                }
                Model {
                    position: Qt.vector3d(0, 0, 6)
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 0.7, 0.05)
                    materials: [ DefaultMaterial {
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 256; height: 160
                                color: "#050d1a"
                                border.color: "#00e5ff"
                                border.width: 4
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "SECTOR K2"
                                        color: "#7f8c8d"
                                        font.pixelSize: 22
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "ACCESS KEY 2"
                                        color: "#00e5ff"
                                        font.pixelSize: 32
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    } ]
                }
                // Wall monitor uses emissive unlit display without casting ambient light into the dark room
            }
        }

        // ==================== 4. KEY 3: SENTINEL PATROL (NORTHWEST) ====================
        Node {
            id: sentinelPatrolGroup

            // Floating 3D Navigation Arrow over Key 3 Pedestal
            TaskArrow {
                id: arrowKey3
                position: Qt.vector3d(950, 50, 1150)
                baseHeight: 50
                arrowColor: "#00e5ff" // Neon Cyan
                active: root.levelManager && root.levelManager.currentLevel === 1 && !root.levelManager.isKeyCollected(2)
            }

            // Raised Keycard Pedestal holding Key 3 at (950, 0, 1150)
            Model {
                position: Qt.vector3d(950, 15, 1150)
                source: "#Cylinder"
                scale: Qt.vector3d(1.0, 0.3, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#1c2833"; roughness: 0.5; metalness: 0.8 } ]
            }
            PointLight {
                position: Qt.vector3d(950, 120, 1150)
                color: "#f1c40f"
                brightness: 5.0
            }

            // Wall Monitor displaying Security Digit K3
            Node {
                position: Qt.vector3d(515, 150, 1150)
                eulerRotation.y: 90
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.4, 0.9, 0.1)
                    materials: [ PrincipledMaterial { baseColor: "#0d1117"; roughness: 0.5 } ]
                }
                Model {
                    position: Qt.vector3d(0, 0, 6)
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 0.7, 0.05)
                    materials: [ DefaultMaterial {
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 256; height: 160
                                color: "#050d1a"
                                border.color: "#00e5ff"
                                border.width: 4
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "SECTOR K3"
                                        color: "#7f8c8d"
                                        font.pixelSize: 22
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "ACCESS KEY 3"
                                        color: "#00e5ff"
                                        font.pixelSize: 32
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 0, 15)
                    color: "#00e5ff"
                    brightness: 3.0
                }
            }
        }

        // ==================== 5. KEY 4: MIXED VAULT (NORTHEAST) ====================
        Node {
            id: mixedVaultGroup

            // --- Tall Enclosure Architecture for Key Room 4 (Ceiling Y=750, Height=7.5m) ---
            // High Ceiling Slab (X: 3300..4400, Z: 600..1800, Y=750)
            Model {
                position: Qt.vector3d(3850, 750, 1200)
                source: "#Cube"
                scale: Qt.vector3d(11.2, 0.2, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#14171d"; roughness: 0.95 } ]
            }

            // Upper Perimeter Enclosing Walls (Y: 300 to 750, Height=450, Center Y=525)
            // North Upper Wall (Z=600)
            Model {
                position: Qt.vector3d(3850, 525, 600)
                source: "#Cube"
                scale: Qt.vector3d(11.2, 4.5, 0.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // South Upper Wall (Z=1800)
            Model {
                position: Qt.vector3d(3850, 525, 1800)
                source: "#Cube"
                scale: Qt.vector3d(11.2, 4.5, 0.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // East Upper Wall (X=4400)
            Model {
                position: Qt.vector3d(4400, 525, 1200)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 4.5, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }
            // West Upper Wall Partition above 3m entrance doorway (X=3300)
            Model {
                position: Qt.vector3d(3300, 525, 1200)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 4.5, 12.2)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.8; metalness: 0.3 } ]
            }

            // Overhead Industrial Steel Rafter Beams (Y=620)
            Model {
                position: Qt.vector3d(3850, 620, 950)
                source: "#Cube"
                scale: Qt.vector3d(11.0, 0.4, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(3850, 620, 1450)
                source: "#Cube"
                scale: Qt.vector3d(11.0, 0.4, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.8 } ]
            }

            // Floating 3D Navigation Arrow over the Wall-Mounted Electrical Breaker Panel
            TaskArrow {
                id: arrowElectricalWiring
                position: Qt.vector3d(3650, 235, 620)
                baseHeight: 235
                arrowColor: "#f1c40f" // Electric Gold
                active: root.levelManager && root.levelManager.currentLevel === 1 && !root.levelManager.circuitPuzzleCompleted
            }
            // Floating 3D Navigation Arrow over Key 4 Pedestal on Catwalk (appears when wiring is fixed)
            TaskArrow {
                id: arrowKey4Pedestal
                position: Qt.vector3d(3850, 230, 1150)
                baseHeight: 230
                arrowColor: "#00e5ff" // Neon Cyan
                active: root.levelManager && root.levelManager.currentLevel === 1 && root.levelManager.circuitPuzzleCompleted && !root.levelManager.isKeyCollected(3)
            }

            // Elevated 2m Central Platform / Catwalk (Platform height: 200, Rows 10..12, Cols 37..39 -> X=3850, Z=1150)
            Model {
                position: Qt.vector3d(3850, 100, 1150)
                source: "#Cube"
                scale: Qt.vector3d(3.0, 2.0, 3.0)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.6 } ]
            }
            // Raised Keycard Pedestal on top of platform at Y=200
            Model {
                position: Qt.vector3d(3850, 208, 1150)
                source: "#Cylinder"
                scale: Qt.vector3d(0.8, 0.16, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.4; metalness: 0.8 } ]
            }
            // Step-up Access Crates (Row 14: 65cm, Row 13: 130cm -> leads to 200cm platform)
            Model {
                position: Qt.vector3d(3850, 32.5, 1450)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 0.65, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#7f8c8d"; roughness: 0.7; metalness: 0.3 } ]
            }
            Model {
                position: Qt.vector3d(3850, 65, 1350)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 1.3, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#7f8c8d"; roughness: 0.7; metalness: 0.3 } ]
            }
            // L-shaped cover barriers around platform
            Model {
                position: Qt.vector3d(3650, 260, 1050)
                source: "#Cube"
                scale: Qt.vector3d(0.3, 1.2, 1.5)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(4050, 260, 1050)
                source: "#Cube"
                scale: Qt.vector3d(0.3, 1.2, 1.5)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.6 } ]
            }
            // Magenta Spotlight illuminating Key 4
            PointLight {
                position: Qt.vector3d(3850, 280, 1150)
                color: "#e056fd"
                brightness: 6.0
            }

            // --- Wall-Mounted Electrical Switchboard & Breaker Panel at (3650, 135, 615) ---
            Node {
                id: electricalWiringTerminalNode
                position: Qt.vector3d(3650, 135, 615)

                // Industrial Surface-Mount Steel Breaker Enclosure Chassis
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.4, 1.8, 0.22)
                    materials: [ PrincipledMaterial { baseColorMap: texSteelWall; baseColor: "#243342"; roughness: 0.45; metalness: 0.8 } ]
                }

                // Heavy Hazard Warning Perimeter Rails (Yellow/Black Bevel)
                Model {
                    position: Qt.vector3d(0, 88, 12)
                    source: "#Cube"
                    scale: Qt.vector3d(1.44, 0.08, 0.06)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(0, -88, 12)
                    source: "#Cube"
                    scale: Qt.vector3d(1.44, 0.08, 0.06)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(-68, 0, 12)
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 1.84, 0.06)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }
                Model {
                    position: Qt.vector3d(68, 0, 12)
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 1.84, 0.06)
                    materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.4; metalness: 0.8 } ]
                }

                // Overhead Industrial Power Conduits Running Up to High Ceiling (Y=750)
                Model {
                    position: Qt.vector3d(-45, 300, 8)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.08, 4.5, 0.08)
                    materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.5; metalness: 0.85 } ]
                }
                Model {
                    position: Qt.vector3d(45, 300, 8)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.08, 4.5, 0.08)
                    materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.5; metalness: 0.85 } ]
                }

                // Bottom Feeder Conduits
                Model {
                    position: Qt.vector3d(-35, -110, 8)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.07, 0.7, 0.07)
                    materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.5; metalness: 0.85 } ]
                }
                Model {
                    position: Qt.vector3d(35, -110, 8)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.07, 0.7, 0.07)
                    materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.5; metalness: 0.85 } ]
                }

                // Exposed High-Voltage Braided Wire Harnesses
                Model {
                    position: Qt.vector3d(-30, -50, 14)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 0.45, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#e74c3c"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(-15, -50, 14)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 0.45, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(0, -50, 14)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 0.45, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#f1c40f"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    position: Qt.vector3d(15, -50, 14)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 0.45, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#2ecc71"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // Master Disconnect Knife Switch Lever
                Model {
                    position: Qt.vector3d(50, -50, 14)
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.35, 0.1)
                    materials: [ PrincipledMaterial { baseColor: "#111822"; roughness: 0.4; metalness: 0.9 } ]
                }
                Model {
                    position: Qt.vector3d(50, -45, 20)
                    eulerRotation.x: (root.puzzleManager && root.puzzleManager.powerSolved) ? 35 : -35
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.28, 0.06)
                    materials: [ PrincipledMaterial { baseColor: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#e74c3c"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // CRT Switchboard Monitor Bezel Frame
                Model {
                    position: Qt.vector3d(0, 25, 12)
                    source: "#Cube"
                    scale: Qt.vector3d(1.12, 0.82, 0.08)
                    materials: [ PrincipledMaterial { baseColor: "#0b0f14"; roughness: 0.3; metalness: 0.9 } ]
                }

                // CRT / Holographic Display Screen
                Model {
                    position: Qt.vector3d(0, 25, 17)
                    source: "#Cube"
                    scale: Qt.vector3d(1.04, 0.74, 0.02)
                    materials: [ DefaultMaterial {
                        lighting: DefaultMaterial.NoLighting
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 440; height: 300
                                color: "#06101e"
                                border.color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#f39c12"
                                border.width: 5
                                radius: 6

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 10

                                    Row {
                                        width: parent.width
                                        spacing: 10
                                        Rectangle {
                                            width: 14; height: 14; radius: 7
                                            color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#f39c12"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "VANGUARD PWR // SUB-STATION 04 SWITCHBOARD"
                                            color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#f39c12"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 1
                                        color: "#34495e"
                                    }

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: (root.puzzleManager && root.puzzleManager.powerSolved)
                                              ? "STATUS: 480V MAIN BUS ENERGIZED\nFINAL BULKHEAD CARD READER ONLINE\nALL CIRCUITS NOMINAL"
                                              : "STATUS: ELECTRICAL FAULT DETECTED\nBULKHEAD CARD READER OFFLINE\nPRESS [E] TO ACCESS SWITCHBOARD"
                                        color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00f0ff"
                                        font.pixelSize: 14
                                        font.bold: true
                                        lineHeight: 1.3
                                    }

                                    Rectangle {
                                        width: parent.width - 24
                                        height: 38
                                        radius: 4
                                        color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#1b4d3e" : "#d35400"
                                        border.color: "#ffffff"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: (root.puzzleManager && root.puzzleManager.powerSolved) ? "[ONLINE: WIRING RESTORED]" : "[E] ACCESS ELECTRICAL SWITCHBOARD"
                                            color: "#ffffff"
                                            font.pixelSize: 14
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 25, 45)
                    color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#f39c12"
                    brightness: 6.0
                }
            }

            // Wall Monitor displaying Security Digit K4
            Node {
                position: Qt.vector3d(3850, 150, 615)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.4, 0.9, 0.1)
                    materials: [ PrincipledMaterial { baseColor: "#0d1117"; roughness: 0.5 } ]
                }
                Model {
                    position: Qt.vector3d(0, 0, 6)
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 0.7, 0.05)
                    materials: [ DefaultMaterial {
                        diffuseMap: Texture {
                            sourceItem: Rectangle {
                                width: 256; height: 160
                                color: "#050d1a"
                                border.color: "#00e5ff"
                                border.width: 4
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "SECTOR K4"
                                        color: "#7f8c8d"
                                        font.pixelSize: 22
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "ACCESS KEY 4"
                                        color: "#00e5ff"
                                        font.pixelSize: 32
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    } ]
                }
                PointLight {
                    position: Qt.vector3d(0, 0, 15)
                    color: "#00e5ff"
                    brightness: 3.0
                }
            }
        }

        // ==================== 6. STORAGE ROOM AMBUSH (NORTH) ====================
        Node {
            id: storageAmbushGroup

            // --- Industrial Cargo Shipping Containers with Detailed Corrugation Textures & Hardware ---
            // 1. Red Heavy Cargo Container at (1950, 150, 850)
            Node {
                position: Qt.vector3d(1950, 150, 850)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.8, 3.0, 1.2)
                    materials: [ PrincipledMaterial { baseColorMap: texContainerRed; roughness: 0.40; metalness: 0.45 } ]
                }
                // Dark Corner Framing Rails
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, 146, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, -146, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                // Vertical Dual Door Lock Rods on Front Face (Z=61)
                Model {
                    position: Qt.vector3d(-20, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 2.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
                Model {
                    position: Qt.vector3d(20, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 2.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
            }

            // 2. Blue Heavy Cargo Container at (2750, 150, 850)
            Node {
                position: Qt.vector3d(2750, 150, 850)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.8, 3.0, 1.2)
                    materials: [ PrincipledMaterial { baseColorMap: texContainerBlue; roughness: 0.40; metalness: 0.45 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, 146, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, -146, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.84, 0.08, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                // Vertical Dual Door Lock Rods on Front Face (Z=61)
                Model {
                    position: Qt.vector3d(-20, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 2.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
                Model {
                    position: Qt.vector3d(20, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 2.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
            }

            // 3. Orange Medium Freight Container at (2150, 100, 1150)
            Node {
                position: Qt.vector3d(2150, 100, 1150)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 2.0, 1.2)
                    materials: [ PrincipledMaterial { baseColorMap: texContainerOrange; roughness: 0.45; metalness: 0.40 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, 97, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, -97, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                // Vertical Door Lock Rod on Front Face (Z=61)
                Model {
                    position: Qt.vector3d(0, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 1.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
            }

            // 4. Green Medium Freight Container at (2550, 100, 1150)
            Node {
                position: Qt.vector3d(2550, 100, 1150)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.2, 2.0, 1.2)
                    materials: [ PrincipledMaterial { baseColorMap: texContainerGreen; roughness: 0.45; metalness: 0.40 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, 97, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                Model {
                    position: Qt.vector3d(0, -97, 0)
                    source: "#Cube"
                    scale: Qt.vector3d(1.24, 0.06, 1.24)
                    materials: [ PrincipledMaterial { baseColor: "#11161d"; roughness: 0.35; metalness: 0.90 } ]
                }
                // Vertical Door Lock Rod on Front Face (Z=61)
                Model {
                    position: Qt.vector3d(0, 0, 61)
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.04, 1.9, 0.04)
                    materials: [ PrincipledMaterial { baseColor: "#c8d6e5"; roughness: 0.25; metalness: 0.95 } ]
                }
            }
        }

        // ==================== 7. EXIT ELEVATOR BULKHEAD & KEYPAD TERMINAL ====================
        Node {
            id: exitElevatorGroup
            position: Qt.vector3d(2350, 0, 250)

            // Elevator Bulkhead Frame
            Model {
                position: Qt.vector3d(0, 150, 0)
                source: "#Cube"
                scale: Qt.vector3d(4.0, 3.0, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#111722"; roughness: 0.4; metalness: 0.8 } ]
            }
            // Status Light: Red when locked, Green when all 4 keys held
            PointLight {
                position: Qt.vector3d(0, 280, 20)
                color: (root.levelManager && root.levelManager.collectedKeysCount >= 4) ? "#2ecc71" : "#e74c3c"
                brightness: 6.0
            }

            // Keycard Terminal Pedestal at door entrance
            Model {
                position: Qt.vector3d(130, 60, 270)
                source: "#Cube"
                scale: Qt.vector3d(0.4, 1.2, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5; metalness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(130, 125, 270)
                eulerRotation.x: -25
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.25, 0.08)
                materials: [ PrincipledMaterial {
                    baseColor: (root.levelManager && root.levelManager.collectedKeysCount >= 4) ? "#2ecc71" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(130, 140, 280)
                color: (root.levelManager && root.levelManager.collectedKeysCount >= 4) ? "#2ecc71" : "#00e5ff"
                brightness: 3.0
            }
        }

    }

    // ==================== ATMOSPHERIC CEILING LIGHTS (LEVEL 1) ====================
    Node {
        id: level1CeilingLightsNode
        visible: root.levelManager && root.levelManager.currentLevel === 1

        // --- Hallway Red Lockdown Lights (Central Spine & Outer Bypasses) ---
        // Central Spine (Y=445 flush against Y=450 ceiling; Y=295 at vestibule)
        CeilingLightFixture {
            position: Qt.vector3d(2350, 445, 3750)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(2350, 445, 3150)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(2350, 445, 2550)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(2350, 445, 1950)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(2350, 445, 1350)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(2350, 295, 450)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }

        // Outer Bypass Hallways (Y=295 flush against Y=300 ceiling)
        CeilingLightFixture {
            position: Qt.vector3d(650, 295, 2150)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(4250, 295, 2150)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }

        // --- Standard Room Cool-White / Ice-Blue Lights (#D8E8FF) ---
        // Spawn Airlock
        CeilingLightFixture {
            position: Qt.vector3d(2350, 295, 4250)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Key 1 Room (The Vault / Kiting Bay)
        CeilingLightFixture {
            position: Qt.vector3d(950, 295, 3150)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Storage Room (Central Storage)
        CeilingLightFixture {
            position: Qt.vector3d(2350, 440, 1750)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Key 3 Room (Sentinel Patrol)
        CeilingLightFixture {
            position: Qt.vector3d(950, 295, 950)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Key 4 Room (Mixed Vault & Breaker Panel - High Ceiling at Y=750)
        CeilingLightFixture {
            position: Qt.vector3d(3850, 740, 950)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 5.0
        }
        // NOTE: STRICT EXCEPTION - Level 1 Key 2 Room (rows 21..36, cols 33..45; X: 3300..4300, Z: 2400..3600)
        // has ZERO ceiling light fixtures and ZERO PointLight nodes. Completely dark.
    }

    // ==================== ATMOSPHERIC CEILING LIGHTS (LEVEL 2) ====================
    Node {
        id: level2CeilingLightsNode
        visible: root.levelManager && root.levelManager.currentLevel === 2

        // --- Hallway Red Lockdown Lights (Level 2 Main Corridors) ---
        // West Corridor
        CeilingLightFixture {
            position: Qt.vector3d(450, 295, 3800)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(450, 295, 4600)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(450, 295, 5400)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        // North Corridor
        CeilingLightFixture {
            position: Qt.vector3d(3700, 295, 1200)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(4700, 295, 1200)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        // East Security Corridor
        CeilingLightFixture {
            position: Qt.vector3d(5500, 295, 1800)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(5500, 295, 3000)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(5500, 295, 4200)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        // Descent Approach Corridor
        CeilingLightFixture {
            position: Qt.vector3d(4600, 295, 5000)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }
        CeilingLightFixture {
            position: Qt.vector3d(3800, 295, 5000)
            fixtureColor: "#FF1E1E"
            emissiveFactor: Qt.vector3d(1.0, 0.08, 0.08)
            pointLightColor: "#FF2A2A"
        }

        // --- Standard Room Cool-White / Ice-Blue Lights (#D8E8FF) ---
        // Spawn / The Cache
        CeilingLightFixture {
            position: Qt.vector3d(1050, 295, 6050)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // West Arsenal / Proving Grounds
        CeilingLightFixture {
            position: Qt.vector3d(1250, 295, 2400)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Central Armory Vault
        CeilingLightFixture {
            position: Qt.vector3d(2850, 295, 2800)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Explosives Depot
        CeilingLightFixture {
            position: Qt.vector3d(4950, 295, 1700)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
        // Descent Shaft Antechamber
        CeilingLightFixture {
            position: Qt.vector3d(3400, 295, 4900)
            fixtureColor: "#D8E8FF"
            emissiveFactor: Qt.vector3d(0.85, 0.92, 1.0)
            pointLightColor: "#D8E8FF"
            lightBrightness: 4.0
        }
    }
}
