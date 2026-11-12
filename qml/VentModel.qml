import QtQuick
import QtQuick3D
import FPSLabGame

/**
 * @brief VentModel.qml provides a block-built voxel 3D model for Cooling Vents.
 *
 * Adheres to the Project VANGUARD pixel / Minecraft aesthetic:
 * - Blocky geometric casing and coolant conduits
 * - Emits a vivid cyan coolant glow while functional
 * - Collapses and extinguishes into dark charred metal when destroyed
 * - 3D floating status indicator above the vent showing health when damaged
 */
Node {
    id: root

    property var vent: null
    property real cameraYaw: 0.0

    position: vent ? vent.position : Qt.vector3d(0, 0, 0)

    readonly property bool isDestroyed: vent ? vent.isDestroyed : false
    readonly property int hp: vent ? vent.health : 150
    readonly property int maxHp: vent ? vent.maxHealth : 150
    readonly property real hpRatio: maxHp > 0 ? hp / maxHp : 0.0

    // Subtle coolant pulse animation while active
    property real pulseVal: 0.0
    NumberAnimation on pulseVal {
        from: 0.7; to: 1.0; duration: 1200; loops: Animation.Infinite; running: !root.isDestroyed
    }

    // ==================== 3D VOXEL STRUCTURE ====================
    Node {
        id: modelRoot
        // When destroyed, tilt slightly as if ruptured
        eulerRotation: root.isDestroyed ? Qt.vector3d(8, 12, -6) : Qt.vector3d(0, 0, 0)
        position.y: root.isDestroyed ? -10 : 0

        Behavior on position.y { NumberAnimation { duration: 400; easing.type: Easing.OutBounce } }
        Behavior on eulerRotation.x { NumberAnimation { duration: 400 } }

        // 1. Heavy reinforced steel base plate
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.95, 0.35, 0.95)
            position: Qt.vector3d(0, 17.5, 0)
            materials: [
                PrincipledMaterial {
                    baseColor: root.isDestroyed ? "#1a1d24" : "#2c3e50"
                    roughness: 0.8
                    metalness: 0.6
                }
            ]
        }

        // 2. Main housing column
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.75, 1.2, 0.75)
            position: Qt.vector3d(0, 95, 0)
            materials: [
                PrincipledMaterial {
                    baseColor: root.isDestroyed ? "#16181d" : "#34495e"
                    roughness: 0.75
                    metalness: 0.5
                }
            ]
        }

        // 3. Glowing Coolant Chamber / Grille
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.82, 0.60, 0.82)
            position: Qt.vector3d(0, 95, 0)
            materials: [
                PrincipledMaterial {
                    baseColor: root.isDestroyed ? "#22252a" : (root.hpRatio < 0.35 ? "#e74c3c" : "#00e5ff")
                    lighting: root.isDestroyed ? PrincipledMaterial.FragmentLighting : PrincipledMaterial.NoLighting
                    roughness: 0.2
                }
            ]
        }

        // 4. Exhaust Hood / Cap
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.85, 0.25, 0.85)
            position: Qt.vector3d(0, 165, 0)
            materials: [
                PrincipledMaterial {
                    baseColor: root.isDestroyed ? "#121418" : "#1f2937"
                    roughness: 0.9
                    metalness: 0.7
                }
            ]
        }

        // 5. Glowing Coolant Vapor Column & Tall Objective Beacon Beam
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.30, 2.8, 0.30)
            position: Qt.vector3d(0, 310, 0)
            visible: !root.isDestroyed
            materials: [
                PrincipledMaterial {
                    baseColor: root.hpRatio < 0.35 ? "#ff3311" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                    opacity: 0.85 * root.pulseVal
                }
            ]
        }

        // 6. Vent Coolant Illumination (casts onto floor and surrounding walls)
        PointLight {
            position: Qt.vector3d(0, 130, 0)
            color: root.hpRatio < 0.35 ? "#ff3311" : "#00e5ff"
            brightness: root.pulseVal * 8.5
            visible: !root.isDestroyed
        }

        // 7. Billboarded 3D Health Bar
        Node {
            position: Qt.vector3d(0, 210, 0)
            visible: !root.isDestroyed
            eulerRotation: Qt.vector3d(0, -root.cameraYaw, 0)

            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.90, 0.12, 0.02)
                materials: [ PrincipledMaterial { baseColor: "#111418"; lighting: PrincipledMaterial.NoLighting } ]
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.86 * Math.max(0.01, root.hpRatio), 0.08, 0.025)
                position: Qt.vector3d(-43 * (1.0 - root.hpRatio), 0, 0.5)
                materials: [ PrincipledMaterial {
                    baseColor: root.hpRatio < 0.35 ? "#e74c3c" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                }]
            }
        }
    }
}
