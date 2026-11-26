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
    property var bossArena: null
    property var animationManager: null
    property var puzzleManager: null
    property real cameraYaw: 0.0
    property bool gasLeakActive: false
    property int gasLeakSector: 1 // 1=Maintenance, 2=Research

    readonly property real mapWidthUnits: levelManager ? levelManager.mapWidth * levelManager.blockSize : 1600.0
    readonly property real mapHeightUnits: levelManager ? levelManager.mapHeight * levelManager.blockSize : 1600.0

    // ==================== 16x16 NEAREST-FILTERED TEXTURES ====================
    Texture {
        id: texSteelWall
        source: "../assets/textures/steel_wall.png"
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
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    // ==================== INSTANCED VOXEL BLOCK TABLES ====================
    // 1. Solid Walls (Tile 1, Height 3 blocks = 300 units; 6 blocks = 600 units in Level 3)
    TileMapInstancing {
        id: wallInstancing
        levelManager: root.levelManager
        tileType: 1
        blockHeight: (root.levelManager && root.levelManager.currentLevel === 3) ? 6 : 3
        baseColor: "#e0e4eb"
    }

    Model {
        id: wallModel
        source: "#Cube"
        instancing: wallInstancing
        materials: [
            PrincipledMaterial {
                baseColorMap: texSteelWall
                roughness: 0.85
                metalness: 0.25
            }
        ]
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

    // 4. Ammo Pickups (Tile 5, Height 1 block, styled ammo cache)
    TileMapInstancing {
        id: ammoInstancing
        levelManager: root.levelManager
        tileType: 5
        blockHeight: 1
        baseColor: "#e67e22"
    }

    Model {
        id: ammoModel
        source: "#Cube"
        instancing: ammoInstancing
        scale: Qt.vector3d(0.45, 0.35, 0.45)
        materials: [
            PrincipledMaterial {
                baseColorMap: texAmmoBox
                roughness: 0.6
                metalness: 0.4
            }
        ]
    }

    // ==================== FLAT LEVEL FLOOR & CEILING ====================
    // Single large flat floor box
    Model {
        id: floorBox
        source: "#Cube"
        scale: Qt.vector3d(root.mapWidthUnits / 100.0, 0.2, root.mapHeightUnits / 100.0)
        position: Qt.vector3d(root.mapWidthUnits * 0.5, -10, root.mapHeightUnits * 0.5)
        materials: [
            PrincipledMaterial {
                baseColorMap: texFloorPlate
                roughness: 0.88
                metalness: 0.2
            }
        ]
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
        // Northeast Sector Ceiling above Mixed Vault (X: 3300..4300, Z: 0..2400, Y=310)
        Model {
            position: Qt.vector3d(3800, 310, 1200)
            source: "#Cube"
            scale: Qt.vector3d(10.0, 0.2, 24.0)
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

        // ==================== 2. KEY 1: KITING BAY (SOUTHWEST) ====================
        Node {
            id: kitingBayGroup

            // Central 4x4 Fabrication Machine for circle-strafing (Rows 30..31, Cols 9..10 -> X=950, Z=3050)
            Model {
                position: Qt.vector3d(950, 110, 3050)
                source: "#Cube"
                scale: Qt.vector3d(3.5, 2.2, 3.5)
                materials: [ PrincipledMaterial { baseColor: "#1a252f"; roughness: 0.6; metalness: 0.8 } ]
            }
            // Machine Core Column
            Model {
                position: Qt.vector3d(950, 240, 3050)
                source: "#Cylinder"
                scale: Qt.vector3d(2.0, 1.4, 2.0)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; roughness: 0.2; metalness: 0.9; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(950, 260, 3050)
                color: "#00e5ff"
                brightness: 5.0
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

            // Overhead Industrial Floodlights
            PointLight {
                position: Qt.vector3d(3650, 680, 2900)
                color: "#f0f6fc"
                brightness: 6.0
            }
            PointLight {
                position: Qt.vector3d(3950, 680, 3200)
                color: "#f0f6fc"
                brightness: 6.0
            }

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
                PointLight {
                    position: Qt.vector3d(0, 100, 0)
                    color: "#ff0033"
                    brightness: 6.0
                }
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
                        scale: Qt.vector3d(1.1, 0.12, 1.1)
                        materials: [ PrincipledMaterial {
                            baseColor: "#00e5ff"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Target inner amber concentric ring (perpendicular cross-disc for 360-degree visibility)
                    Model {
                        source: "#Cylinder"
                        eulerRotation: Qt.vector3d(90, 0, 0)
                        scale: Qt.vector3d(0.9, 0.1, 0.9)
                        materials: [ PrincipledMaterial {
                            baseColor: "#f39c12"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Glowing Ruby Bullseye Core
                    Model {
                        source: "#Sphere"
                        scale: Qt.vector3d(0.55, 0.55, 0.55)
                        materials: [ PrincipledMaterial {
                            baseColor: "#ff0055"
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }

                    // Target Beacon Light
                    PointLight {
                        position: Qt.vector3d(0, 0, 0)
                        color: "#ff0055"
                        brightness: 8.0
                    }
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
                PointLight {
                    position: Qt.vector3d(0, 0, 15)
                    color: "#00e5ff"
                    brightness: 3.0
                }
            }
        }

        // ==================== 4. KEY 3: SENTINEL PATROL (NORTHWEST) ====================
        Node {
            id: sentinelPatrolGroup

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
            // Step-up Access Crates (Row 14: 50cm, Row 13: 100cm -> leads to 200cm platform)
            Model {
                position: Qt.vector3d(3850, 25, 1450)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 0.5, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#7f8c8d"; roughness: 0.7; metalness: 0.3 } ]
            }
            Model {
                position: Qt.vector3d(3850, 50, 1350)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 1.0, 1.0)
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

            // Tall Cargo Containers in warehouse
            Model {
                position: Qt.vector3d(1950, 150, 850)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 3.0, 1.2)
                materials: [ PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2750, 150, 850)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 3.0, 1.2)
                materials: [ PrincipledMaterial { baseColor: "#2980b9"; roughness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2150, 100, 1150)
                source: "#Cube"
                scale: Qt.vector3d(1.2, 2.0, 1.2)
                materials: [ PrincipledMaterial { baseColor: "#d35400"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(2550, 100, 1150)
                source: "#Cube"
                scale: Qt.vector3d(1.2, 2.0, 1.2)
                materials: [ PrincipledMaterial { baseColor: "#27ae60"; roughness: 0.6 } ]
            }
            // Staggered crate stacks (1m -> 2m)
            Model {
                position: Qt.vector3d(1950, 50, 1050)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 1.0, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#7f8c8d"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(2750, 50, 1050)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 1.0, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#7f8c8d"; roughness: 0.7 } ]
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
}
