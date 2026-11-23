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

    // Single large flat ceiling box (raised to 600 in Level 3 for grand cathedral arena)
    Model {
        id: ceilingBox
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

        // 1. Cargo Warehouse: Crane Control Console & Blocking Containers
        Node {
            id: cargoCraneGroup
            Model {
                position: Qt.vector3d(850, 45, 950)
                source: "#Cube"
                scale: Qt.vector3d(0.7, 0.9, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#1b2631"; roughness: 0.5; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(850, 95, 950)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 0.35, 0.08)
                materials: [ PrincipledMaterial {
                    baseColor: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(850, 110, 950)
                color: (root.puzzleManager && root.puzzleManager.craneSolved) ? "#2ecc71" : "#00e5ff"
                brightness: 3.5
            }

            // 3 Heavy Containers Blocking K1 Alcove (Row 6..7, Col 9)
            Node {
                property real hoistY: (root.puzzleManager && root.puzzleManager.craneSolved) ? 280.0 : 75.0
                Behavior on hoistY { NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad } }

                position: Qt.vector3d(950, hoistY, 700)

                Model {
                    position: Qt.vector3d(0, 0, -45)
                    source: "#Cube"
                    scale: Qt.vector3d(0.9, 1.5, 0.8)
                    materials: [ PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.6 } ]
                }
                Model {
                    position: Qt.vector3d(0, 0, 45)
                    source: "#Cube"
                    scale: Qt.vector3d(0.9, 1.5, 0.8)
                    materials: [ PrincipledMaterial { baseColor: "#2980b9"; roughness: 0.6 } ]
                }
            }

            // Warehouse Office Shipping Log Desk at (1950, 0, 850)
            Model {
                position: Qt.vector3d(1950, 35, 850)
                source: "#Cube"
                scale: Qt.vector3d(1.1, 0.7, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(1950, 72, 850)
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.04, 0.25)
                materials: [ PrincipledMaterial { baseColor: "#f1c40f"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(1950, 85, 850)
                color: "#f39c12"
                brightness: 2.2
            }
        }

        // 2. Research Laboratories: Power Routing Terminal & Containment Field
        Node {
            id: researchPowerGroup
            Model {
                position: Qt.vector3d(6250, 45, 1050)
                source: "#Cube"
                scale: Qt.vector3d(0.7, 0.9, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.4; metalness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(6250, 95, 1050)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 0.35, 0.08)
                materials: [ PrincipledMaterial {
                    baseColor: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(6250, 110, 1050)
                color: (root.puzzleManager && root.puzzleManager.powerSolved) ? "#2ecc71" : "#00e5ff"
                brightness: 3.5
            }

            // Containment Plasma Field across Row 10, Cols 64..65
            Model {
                visible: root.puzzleManager ? !root.puzzleManager.powerSolved : true
                position: Qt.vector3d(6500, 150, 1050)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 3.0, 0.15)
                materials: [ PrincipledMaterial {
                    baseColor: "#00e5ff"
                    opacity: 0.55
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(6500, 150, 1050)
                color: "#00e5ff"
                brightness: 6.0
                visible: root.puzzleManager ? !root.puzzleManager.powerSolved : true
            }

            // Activated Containment Ceiling Floodlight on success
            PointLight {
                position: Qt.vector3d(7100, 240, 750)
                color: "#74b9ff"
                brightness: 8.0
                visible: root.puzzleManager && root.puzzleManager.powerSolved
            }

            // Electrical Control Room: 200A Ceramic Fuse at (6050, 0, 1850)
            Model {
                position: Qt.vector3d(6050, 30, 1850)
                source: "#Cylinder"
                scale: Qt.vector3d(0.4, 0.6, 0.4)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5 } ]
            }
            Model {
                visible: root.puzzleManager ? !root.puzzleManager.fuseCollected : true
                position: Qt.vector3d(6050, 68, 1850)
                source: "#Cylinder"
                scale: Qt.vector3d(0.12, 0.28, 0.12)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                visible: root.puzzleManager ? !root.puzzleManager.fuseCollected : true
                position: Qt.vector3d(6050, 75, 1850)
                color: "#00e5ff"
                brightness: 3.0
            }
        }

        // 3. Administration Block: Security Keypad & Supervisor Directive Desk & Laser Gate
        Node {
            id: adminSecurityGroup
            Model {
                position: Qt.vector3d(1550, 110, 7050)
                source: "#Cube"
                scale: Qt.vector3d(0.12, 0.45, 0.35)
                materials: [ PrincipledMaterial {
                    baseColor: (root.puzzleManager && root.puzzleManager.securitySolved) ? "#2ecc71" : "#e74c3c"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(1530, 110, 7050)
                color: (root.puzzleManager && root.puzzleManager.securitySolved) ? "#2ecc71" : "#e74c3c"
                brightness: 3.0
            }

            // Supervisor Directive Desk at (850, 0, 6450)
            Model {
                position: Qt.vector3d(850, 35, 6450)
                source: "#Cube"
                scale: Qt.vector3d(1.2, 0.7, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(850, 72, 6450)
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.05, 0.25)
                materials: [ PrincipledMaterial { baseColor: "#f39c12"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(850, 85, 6450)
                color: "#f39c12"
                brightness: 2.5
            }

            // Clue 1: Reception Desk at (1050, 0, 5750)
            Model {
                position: Qt.vector3d(1050, 35, 5750)
                source: "#Cube"
                scale: Qt.vector3d(1.1, 0.7, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#34495e"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(1050, 72, 5750)
                source: "#Cube"
                scale: Qt.vector3d(0.3, 0.04, 0.22)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(1050, 85, 5750)
                color: "#00e5ff"
                brightness: 2.2
            }

            // Clue 3: Archive Terminal at (2050, 0, 6750)
            Model {
                position: Qt.vector3d(2050, 45, 6750)
                source: "#Cube"
                scale: Qt.vector3d(0.7, 0.9, 0.6)
                materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(2050, 95, 6750)
                source: "#Cube"
                scale: Qt.vector3d(0.45, 0.35, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; lighting: PrincipledMaterial.NoLighting } ]
            }
            PointLight {
                position: Qt.vector3d(2050, 110, 6750)
                color: "#2ecc71"
                brightness: 2.5
            }

            // Laser Gate Barrier across Row 70, Cols 12..13
            Model {
                visible: root.puzzleManager ? !root.puzzleManager.securitySolved : true
                position: Qt.vector3d(1300, 150, 7050)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 3.0, 0.15)
                materials: [ PrincipledMaterial {
                    baseColor: "#e74c3c"
                    opacity: 0.65
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(1300, 150, 7050)
                color: "#e74c3c"
                brightness: 5.0
                visible: root.puzzleManager ? !root.puzzleManager.securitySolved : true
            }
        }

        // 4. Maintenance & Utilities: Coolant Valve Manifold & Substation Interlock Gate
        Node {
            id: maintenanceCoolantGroup
            Model {
                position: Qt.vector3d(6250, 45, 6650)
                source: "#Cube"
                scale: Qt.vector3d(1.1, 0.9, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#2d3436"; roughness: 0.6; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(6210, 95, 6650)
                source: "#Cylinder"
                scale: Qt.vector3d(0.18, 0.12, 0.18)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff" } ]
            }
            Model {
                position: Qt.vector3d(6250, 95, 6650)
                source: "#Cylinder"
                scale: Qt.vector3d(0.18, 0.12, 0.18)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff" } ]
            }
            Model {
                position: Qt.vector3d(6290, 95, 6650)
                source: "#Cylinder"
                scale: Qt.vector3d(0.18, 0.12, 0.18)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff" } ]
            }
            PointLight {
                position: Qt.vector3d(6250, 120, 6650)
                color: (root.puzzleManager && root.puzzleManager.coolantSolved) ? "#f1c40f" : "#e67e22"
                brightness: 3.5
            }

            // Substation Interlock Gate at Row 72, Col 68
            Model {
                visible: root.puzzleManager ? !root.puzzleManager.coolantSolved : true
                position: Qt.vector3d(6850, 150, 7250)
                source: "#Cube"
                scale: Qt.vector3d(0.2, 3.0, 1.0)
                materials: [ PrincipledMaterial {
                    baseColor: "#f39c12"
                    roughness: 0.5
                    metalness: 0.8
                } ]
            }

            // Backup Generator Turbine Floodlight on success
            PointLight {
                position: Qt.vector3d(7100, 250, 7200)
                color: "#ffeaa7"
                brightness: 9.0
                visible: root.puzzleManager && root.puzzleManager.coolantSolved
            }
        }

        // ==================== 5. DETAILED ROOM INTERIORS (DESKS, CHAIRS, WORKSTATIONS) ====================
        Node {
            id: level1RoomInteriors

            // ----- A. WAREHOUSE OFFICE INTERIORS (Rows 6..12, Cols 18..24) -----
            // Chief Logistics Desk at (1950, 0, 850)
            Model {
                position: Qt.vector3d(1950, 35, 850)
                source: "#Cube"
                scale: Qt.vector3d(1.4, 0.7, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#3e2723"; roughness: 0.6 } ] // Mahogany wood desk
            }
            // Monitor on Desk
            Model {
                position: Qt.vector3d(1950, 78, 830)
                source: "#Cube"
                scale: Qt.vector3d(0.45, 0.35, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            // Office Swivel Chair behind Desk at (1950, 0, 910)
            Model {
                position: Qt.vector3d(1950, 22, 910)
                source: "#Cylinder"
                scale: Qt.vector3d(0.35, 0.44, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#212121"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(1950, 52, 925)
                source: "#Cube"
                scale: Qt.vector3d(0.38, 0.48, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#37474f"; roughness: 0.8 } ]
            }
            // Assistant Desk at (2200, 0, 950)
            Model {
                position: Qt.vector3d(2200, 35, 950)
                source: "#Cube"
                scale: Qt.vector3d(1.3, 0.7, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#455a64"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(2200, 78, 930)
                source: "#Cube"
                scale: Qt.vector3d(0.4, 0.3, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(2200, 22, 1000)
                source: "#Cylinder"
                scale: Qt.vector3d(0.35, 0.44, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#212121"; roughness: 0.7 } ]
            }
            // Office Metal Filing Cabinets along north wall
            Model {
                position: Qt.vector3d(1800, 70, 650)
                source: "#Cube"
                scale: Qt.vector3d(0.6, 1.4, 0.5)
                materials: [ PrincipledMaterial { baseColor: "#546e7a"; roughness: 0.5; metalness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(2050, 70, 650)
                source: "#Cube"
                scale: Qt.vector3d(0.6, 1.4, 0.5)
                materials: [ PrincipledMaterial { baseColor: "#546e7a"; roughness: 0.5; metalness: 0.6 } ]
            }
            // Water Cooler at (2300, 0, 750)
            Model {
                position: Qt.vector3d(2300, 45, 750)
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.9, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#eceff1"; roughness: 0.4 } ]
            }
            Model {
                position: Qt.vector3d(2300, 100, 750)
                source: "#Cylinder"
                scale: Qt.vector3d(0.28, 0.35, 0.28)
                materials: [ PrincipledMaterial { baseColor: "#00bcd4"; opacity: 0.7; roughness: 0.2 } ]
            }

            // ----- B. CARGO STORAGE & RECEIVING BAY (Rows 4..16, Cols 6..16) -----
            // Industrial Steel Workbench at (750, 0, 1450)
            Model {
                position: Qt.vector3d(750, 40, 1450)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 0.8, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#37474f"; roughness: 0.6; metalness: 0.8 } ]
            }
            // Tool chest on bench
            Model {
                position: Qt.vector3d(720, 88, 1450)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 0.25, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.5; metalness: 0.4 } ]
            }
            // Oil drums & chemical barrels
            Model {
                position: Qt.vector3d(650, 40, 1550)
                source: "#Cylinder"
                scale: Qt.vector3d(0.42, 0.8, 0.42)
                materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.5; metalness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(700, 40, 1550)
                source: "#Cylinder"
                scale: Qt.vector3d(0.42, 0.8, 0.42)
                materials: [ PrincipledMaterial { baseColor: "#2980b9"; roughness: 0.5; metalness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(675, 40, 1600)
                source: "#Cylinder"
                scale: Qt.vector3d(0.42, 0.8, 0.42)
                materials: [ PrincipledMaterial { baseColor: "#27ae60"; roughness: 0.5; metalness: 0.7 } ]
            }

            // ----- C. RESEARCH LABORATORIES (Rows 6..14, Cols 56..68) -----
            // Central Science Lab Workbench at (6000, 0, 900)
            Model {
                position: Qt.vector3d(6000, 40, 900)
                source: "#Cube"
                scale: Qt.vector3d(2.0, 0.8, 0.9)
                materials: [ PrincipledMaterial { baseColor: "#eceff1"; roughness: 0.3; metalness: 0.5 } ]
            }
            // Chemical Flasks & Beakers on bench
            Model {
                position: Qt.vector3d(5950, 88, 900)
                source: "#Cylinder"
                scale: Qt.vector3d(0.12, 0.22, 0.12)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(6050, 88, 900)
                source: "#Cylinder"
                scale: Qt.vector3d(0.12, 0.22, 0.12)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; lighting: PrincipledMaterial.NoLighting } ]
            }
            // Lab Stools
            Model {
                position: Qt.vector3d(6000, 25, 965)
                source: "#Cylinder"
                scale: Qt.vector3d(0.3, 0.5, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#455a64"; roughness: 0.6 } ]
            }
            // Analysis Station 2 at (6450, 0, 900)
            Model {
                position: Qt.vector3d(6450, 40, 900)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 0.8, 0.9)
                materials: [ PrincipledMaterial { baseColor: "#eceff1"; roughness: 0.3; metalness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(6450, 88, 880)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 0.35, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#37474f"; roughness: 0.5; metalness: 0.7 } ]
            }
            // High-density Server Racks with LED arrays at (5750, 0, 750) and (5750, 0, 950)
            Model {
                position: Qt.vector3d(5750, 90, 750)
                source: "#Cube"
                scale: Qt.vector3d(0.65, 1.8, 0.9)
                materials: [ PrincipledMaterial { baseColor: "#1a1a24"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(5720, 90, 750)
                source: "#Cube"
                scale: Qt.vector3d(0.04, 1.4, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(5750, 90, 950)
                source: "#Cube"
                scale: Qt.vector3d(0.65, 1.8, 0.9)
                materials: [ PrincipledMaterial { baseColor: "#1a1a24"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(5720, 90, 950)
                source: "#Cube"
                scale: Qt.vector3d(0.04, 1.4, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; lighting: PrincipledMaterial.NoLighting } ]
            }

            // ----- D. ADMINISTRATION SECTOR (Rows 55..75, Cols 6..24) -----
            // Reception Counter & Waiting Area (Rows 55..60, Cols 8..14)
            Model {
                position: Qt.vector3d(1050, 38, 5750)
                source: "#Cube"
                scale: Qt.vector3d(1.5, 0.76, 0.6)
                materials: [ PrincipledMaterial { baseColor: "#263238"; roughness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(1050, 80, 5730)
                source: "#Cube"
                scale: Qt.vector3d(0.4, 0.3, 0.06)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(1050, 22, 5790)
                source: "#Cylinder"
                scale: Qt.vector3d(0.32, 0.44, 0.32)
                materials: [ PrincipledMaterial { baseColor: "#212121"; roughness: 0.8 } ]
            }
            // Waiting Room Guest Sofa & Coffee Table at (1300, 0, 5850)
            Model {
                position: Qt.vector3d(1300, 25, 5850)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 0.5, 0.65)
                materials: [ PrincipledMaterial { baseColor: "#1a237e"; roughness: 0.8 } ] // Navy leather sofa
            }
            Model {
                position: Qt.vector3d(1300, 50, 5880)
                source: "#Cube"
                scale: Qt.vector3d(1.6, 0.5, 0.15)
                materials: [ PrincipledMaterial { baseColor: "#1a237e"; roughness: 0.8 } ] // Sofa backrest
            }
            Model {
                position: Qt.vector3d(1300, 20, 5760)
                source: "#Cube"
                scale: Qt.vector3d(1.0, 0.4, 0.5)
                materials: [ PrincipledMaterial { baseColor: "#3e2723"; roughness: 0.5 } ] // Coffee table
            }

            // Executive Conference Room (Rows 62..68, Cols 14..20 around 1700, 0, 6450)
            // Grand Conference Table (240x100 units)
            Model {
                position: Qt.vector3d(1700, 36, 6450)
                source: "#Cube"
                scale: Qt.vector3d(2.4, 0.72, 1.0)
                materials: [ PrincipledMaterial { baseColor: "#2b1b17"; roughness: 0.4 } ] // Dark walnut table
            }
            // 6 Conference Chairs around table
            Model { position: Qt.vector3d(1550, 22, 6380); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(1700, 22, 6380); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(1850, 22, 6380); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(1550, 22, 6520); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(1700, 22, 6520); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(1850, 22, 6520); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            // Wall Presentation Display on north wall at (1700, 160, 6220)
            Model {
                position: Qt.vector3d(1700, 160, 6220)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 1.1, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
            }

            // Supervisor Office (Rows 62..68, Cols 6..12 around 850, 0, 6450)
            Model {
                position: Qt.vector3d(850, 35, 6450)
                source: "#Cube"
                scale: Qt.vector3d(1.5, 0.7, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#3e2723"; roughness: 0.5 } ]
            }
            Model {
                position: Qt.vector3d(850, 22, 6520)
                source: "#Cylinder"
                scale: Qt.vector3d(0.36, 0.44, 0.36)
                materials: [ PrincipledMaterial { baseColor: "#212121"; roughness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(850, 56, 6535)
                source: "#Cube"
                scale: Qt.vector3d(0.42, 0.55, 0.08)
                materials: [ PrincipledMaterial { baseColor: "#424242"; roughness: 0.8 } ] // High-back leather chair
            }
            // 2 Visitor chairs in front of desk
            Model { position: Qt.vector3d(780, 22, 6370); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }
            Model { position: Qt.vector3d(920, 22, 6370); source: "#Cylinder"; scale: Qt.vector3d(0.3, 0.44, 0.3); materials: [ PrincipledMaterial { baseColor: "#37474f" } ] }

            // Archive Storage Shelving Units (Rows 65..72, Cols 18..24 around 2050, 0, 6750)
            Model {
                position: Qt.vector3d(2050, 80, 6650)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 1.6, 1.6)
                materials: [ PrincipledMaterial { baseColor: "#455a64"; roughness: 0.6; metalness: 0.7 } ]
            }
            Model {
                position: Qt.vector3d(2050, 80, 6950)
                source: "#Cube"
                scale: Qt.vector3d(0.5, 1.6, 1.6)
                materials: [ PrincipledMaterial { baseColor: "#455a64"; roughness: 0.6; metalness: 0.7 } ]
            }

            // ----- E. MAINTENANCE & WORKSHOP (Rows 60..74, Cols 56..74) -----
            // Heavy Mechanical Workbenches
            Model {
                position: Qt.vector3d(6450, 42, 6350)
                source: "#Cube"
                scale: Qt.vector3d(2.0, 0.84, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#263238"; roughness: 0.5; metalness: 0.85 } ]
            }
            // Rows of Worker Storage Lockers at (6850, 0, 6150)
            Model {
                position: Qt.vector3d(6850, 85, 6150)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 1.7, 0.5)
                materials: [ PrincipledMaterial { baseColor: "#37474f"; roughness: 0.6; metalness: 0.7 } ]
            }
            // Oil drums & fuel canisters at (7150, 0, 6750)
            Model { position: Qt.vector3d(7150, 40, 6750); source: "#Cylinder"; scale: Qt.vector3d(0.42, 0.8, 0.42); materials: [ PrincipledMaterial { baseColor: "#f39c12"; roughness: 0.6; metalness: 0.6 } ] }
            Model { position: Qt.vector3d(7200, 40, 6750); source: "#Cylinder"; scale: Qt.vector3d(0.42, 0.8, 0.42); materials: [ PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.6; metalness: 0.6 } ] }
            Model { position: Qt.vector3d(7175, 40, 6800); source: "#Cylinder"; scale: Qt.vector3d(0.42, 0.8, 0.42); materials: [ PrincipledMaterial { baseColor: "#2c3e50"; roughness: 0.6; metalness: 0.6 } ] }

            // ----- F. CENTRAL CHECKPOINT & SCANNING GATE (Rows 36..44, Cols 36..44) -----
            // Security Scanner Archway Portal at (4000, 0, 3750)
            Model {
                position: Qt.vector3d(3940, 100, 3750)
                source: "#Cube"
                scale: Qt.vector3d(0.12, 2.0, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(4060, 100, 3750)
                source: "#Cube"
                scale: Qt.vector3d(0.12, 2.0, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; roughness: 0.4; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(4000, 200, 3750)
                source: "#Cube"
                scale: Qt.vector3d(1.3, 0.15, 0.3)
                materials: [ PrincipledMaterial { baseColor: "#00e5ff"; roughness: 0.4; metalness: 0.8 } ]
            }
            PointLight {
                position: Qt.vector3d(4000, 190, 3750)
                color: "#00e5ff"
                brightness: 3.0
            }
            // Guard Inspection Podium at (3850, 0, 3900)
            Model {
                position: Qt.vector3d(3850, 45, 3900)
                source: "#Cube"
                scale: Qt.vector3d(0.7, 0.9, 0.6)
                materials: [ PrincipledMaterial { baseColor: "#37474f"; roughness: 0.6 } ]
            }
            Model {
                position: Qt.vector3d(3850, 95, 3890)
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.25, 0.06)
                materials: [ PrincipledMaterial { baseColor: "#f1c40f"; lighting: PrincipledMaterial.NoLighting } ]
            }
        }

        // ==================== 6. TOXIC GAS LEAK VOLUMETRIC HAZE & EXHAUST SWITCHES ====================
        Node {
            id: level1GasLeakHaze
            visible: root.levelManager && root.levelManager.currentLevel === 1 && root.levelManager.gasLeakActive
            position: root.levelManager ? root.levelManager.gasStationPosition : Qt.vector3d(0, 0, 0)

            // Toxic green gas smoke columns
            Model {
                position: Qt.vector3d(0, 100, 0)
                source: "#Cylinder"
                scale: Qt.vector3d(3.5, 2.2, 3.5)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; opacity: 0.45; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(40, 110, -30)
                source: "#Cylinder"
                scale: Qt.vector3d(2.8, 2.0, 2.8)
                materials: [ PrincipledMaterial { baseColor: "#27ae60"; opacity: 0.40; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                position: Qt.vector3d(-40, 95, 35)
                source: "#Cylinder"
                scale: Qt.vector3d(3.0, 2.1, 3.0)
                materials: [ PrincipledMaterial { baseColor: "#a8ff78"; opacity: 0.38; lighting: PrincipledMaterial.NoLighting } ]
            }
            // Emergency Gas Isolation Console
            Model {
                position: Qt.vector3d(0, 45, 0)
                source: "#Cube"
                scale: Qt.vector3d(0.7, 0.9, 0.7)
                materials: [ PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.5; metalness: 0.8 } ]
            }
            Model {
                position: Qt.vector3d(0, 95, 0)
                source: "#Cylinder"
                scale: Qt.vector3d(0.25, 0.2, 0.25)
                materials: [ PrincipledMaterial {
                    baseColor: (root.levelManager && root.levelManager.gasLeakRepairStage >= 3) ? "#2ecc71" : "#f1c40f"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(0, 140, 0)
                color: (root.levelManager && root.levelManager.gasLeakRepairStage >= 3) ? "#2ecc71" : "#e74c3c"
                brightness: 8.5
            }
        }
    }
}
