import QtQuick
import QtQuick3D

/**
 * @brief AccessKeyModel.qml renders a procedural low-poly sci-fi security keycard / crystal beacon
 * using Qt Quick 3D primitives and emissive highlights. Automatically hides once collected.
 */
Node {
    id: root

    property var keyPickup: null

    visible: keyPickup ? !keyPickup.collected : false
    position: keyPickup ? keyPickup.renderPosition : Qt.vector3d(0, 35, 0)
    eulerRotation: Qt.vector3d(12, keyPickup ? keyPickup.rotationY : 0.0, 0)

    readonly property int keyIdx: keyPickup ? keyPickup.keyIndex : 0
    readonly property color accentColor: {
        switch (keyIdx) {
        case 0: return "#00e5ff" // Key 1: Cyan
        case 1: return "#2ecc71" // Key 2: Emerald
        case 2: return "#f1c40f" // Key 3: Amber Gold
        default: return "#e056fd" // Key 4: Magenta
        }
    }

    // Metallic outer frame backing
    Model {
        source: "#Cube"
        scale: Qt.vector3d(0.28, 0.36, 0.05)
        materials: [
            PrincipledMaterial {
                baseColor: "#1b2430"
                roughness: 0.35
                metalness: 0.85
            }
        ]
    }

    // Glowing holographic circuit strip (front)
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 4, 2.8)
        scale: Qt.vector3d(0.20, 0.24, 0.015)
        materials: [
            PrincipledMaterial {
                baseColor: root.accentColor
                lighting: PrincipledMaterial.NoLighting
            }
        ]
    }

    // Glowing holographic circuit strip (back)
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 4, -2.8)
        scale: Qt.vector3d(0.20, 0.24, 0.015)
        materials: [
            PrincipledMaterial {
                baseColor: root.accentColor
                lighting: PrincipledMaterial.NoLighting
            }
        ]
    }

    // Central crystal energy core spire
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0, 0)
        scale: Qt.vector3d(0.11, 0.44, 0.11)
        materials: [
            PrincipledMaterial {
                baseColor: root.accentColor
                lighting: PrincipledMaterial.NoLighting
                opacity: 0.92
            }
        ]
    }

    // Base holo-pedestal ring
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, -24, 0)
        scale: Qt.vector3d(0.32, 0.03, 0.32)
        materials: [
            PrincipledMaterial {
                baseColor: "#2c3e50"
                roughness: 0.45
                metalness: 0.75
            }
        ]
    }

    // Beacon illumination
    PointLight {
        position: Qt.vector3d(0, 22, 0)
        color: root.accentColor
        brightness: 4.5
    }
}

