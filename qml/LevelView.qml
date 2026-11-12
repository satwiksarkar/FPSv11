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
    property real cameraYaw: 0.0

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

    // ==================== EXIT PLATFORM MARKER (TILES 4 & 6) ====================
    Node {
        id: exitPlatformMarker
        visible: root.levelManager && (root.levelManager.currentLevel === 1 || root.levelManager.currentLevel === 2)
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
}
