import QtQuick
import QtQuick3D
import FPSLabGame

/**
 * @brief DoorModel.qml renders a procedural sci-fi dual sliding bulkhead door
 * with genuine recessed pocket housings, metallic frame, and emissive status lights.
 *
 * Local coordinate layout (1.0 #Cube scale = 100 world units):
 * - Center doorway aperture: X in [-50, +50], Y in [0, 288], Z in [-50, +50]
 * - Recessed left/right pocket slots: |X| in [50, 146], Z in [-14, +14], Y in [0, 288]
 * - Each sliding leaf (50 x 288 x 12) retracts +-52 units into its pocket at openProgress == 1.0,
 *   completely clearing the 100-unit doorway without intersecting flanking wall cubes.
 */
Node {
    id: root

    property var door: null
    property var pocketTexture: null

    position: door ? door.position : Qt.vector3d(0, 0, 0)
    eulerRotation: Qt.vector3d(0, door ? door.axis : 0.0, 0)

    readonly property real progress: door ? door.openProgress : 0.0
    readonly property int stateVal: door ? door.doorState : Door.Closed
    readonly property int typeVal: door ? door.doorType : Door.Standard

    readonly property color statusColor: {
        if (stateVal === Door.Locked) return "#e74c3c"
        if (stateVal === Door.Open) return "#2ecc71"
        if (stateVal === Door.Opening || stateVal === Door.Closing) return "#f1c40f"
        return (typeVal === Door.MainExit) ? "#f39c12" : "#00e5ff"
    }

    Texture {
        id: texDoorPanel
        source: "../assets/textures/door.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    Texture {
        id: texDefaultPocket
        source: "../assets/textures/steel_wall.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    readonly property var effectivePocketTex: root.pocketTexture ? root.pocketTexture : texDefaultPocket

    // ==================== 1. RECESSED POCKET WALL HOUSINGS ====================
    // Left Pocket (X in [-150, -50]): hollow Z cavity [-14, +14] for left leaf
    Model {
        source: "#Cube"
        position: Qt.vector3d(-100, 150, 32)
        scale: Qt.vector3d(1.0, 3.0, 0.36)
        materials: [ PrincipledMaterial { baseColorMap: root.effectivePocketTex; baseColor: "#d5dce6"; roughness: 0.85; metalness: 0.3 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(-100, 150, -32)
        scale: Qt.vector3d(1.0, 3.0, 0.36)
        materials: [ PrincipledMaterial { baseColorMap: root.effectivePocketTex; baseColor: "#d5dce6"; roughness: 0.85; metalness: 0.3 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(-148, 150, 0)
        scale: Qt.vector3d(0.04, 3.0, 0.28)
        materials: [ PrincipledMaterial { baseColor: "#1f2730"; roughness: 0.6; metalness: 0.7 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(-100, 294, 0)
        scale: Qt.vector3d(1.0, 0.12, 0.28)
        materials: [ PrincipledMaterial { baseColor: "#26303c"; roughness: 0.6; metalness: 0.6 } ]
    }

    // Right Pocket (X in [+50, +150]): hollow Z cavity [-14, +14] for right leaf
    Model {
        source: "#Cube"
        position: Qt.vector3d(100, 150, 32)
        scale: Qt.vector3d(1.0, 3.0, 0.36)
        materials: [ PrincipledMaterial { baseColorMap: root.effectivePocketTex; baseColor: "#d5dce6"; roughness: 0.85; metalness: 0.3 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(100, 150, -32)
        scale: Qt.vector3d(1.0, 3.0, 0.36)
        materials: [ PrincipledMaterial { baseColorMap: root.effectivePocketTex; baseColor: "#d5dce6"; roughness: 0.85; metalness: 0.3 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(148, 150, 0)
        scale: Qt.vector3d(0.04, 3.0, 0.28)
        materials: [ PrincipledMaterial { baseColor: "#1f2730"; roughness: 0.6; metalness: 0.7 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(100, 294, 0)
        scale: Qt.vector3d(1.0, 0.12, 0.28)
        materials: [ PrincipledMaterial { baseColor: "#26303c"; roughness: 0.6; metalness: 0.6 } ]
    }

    // ==================== 2. DOORFRAME HEADER, THRESHOLD & JAMB TRIM ====================
    // Header lintel above full 100-unit doorway (Y in [288, 300])
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 294, 0)
        scale: Qt.vector3d(1.0, 0.12, 1.0)
        materials: [ PrincipledMaterial { baseColor: "#2c3540"; roughness: 0.5; metalness: 0.75 } ]
    }

    // Flush floor track rail
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 1, 0)
        scale: Qt.vector3d(1.0, 0.02, 0.32)
        materials: [ PrincipledMaterial { baseColor: "#1e252d"; roughness: 0.4; metalness: 0.85 } ]
    }

    // External metallic jamb trim mounted on pocket faces outside the [-50, +50] doorway clear width
    Model {
        source: "#Cube"
        position: Qt.vector3d(-54, 144, 51.5)
        scale: Qt.vector3d(0.08, 2.88, 0.03)
        materials: [ PrincipledMaterial { baseColor: "#37424f"; roughness: 0.4; metalness: 0.8 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(54, 144, 51.5)
        scale: Qt.vector3d(0.08, 2.88, 0.03)
        materials: [ PrincipledMaterial { baseColor: "#37424f"; roughness: 0.4; metalness: 0.8 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(-54, 144, -51.5)
        scale: Qt.vector3d(0.08, 2.88, 0.03)
        materials: [ PrincipledMaterial { baseColor: "#37424f"; roughness: 0.4; metalness: 0.8 } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(54, 144, -51.5)
        scale: Qt.vector3d(0.08, 2.88, 0.03)
        materials: [ PrincipledMaterial { baseColor: "#37424f"; roughness: 0.4; metalness: 0.8 } ]
    }

    // ==================== 3. EMISSIVE STATUS LIGHTS ====================
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 293, 51.5)
        scale: Qt.vector3d(0.72, 0.05, 0.03)
        materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
    }
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 293, -51.5)
        scale: Qt.vector3d(0.72, 0.05, 0.03)
        materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
    }

    // Side status beacon cylinders
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(-54, 175, 52.5)
        scale: Qt.vector3d(0.04, 0.34, 0.04)
        materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
    }
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(54, 175, -52.5)
        scale: Qt.vector3d(0.04, 0.34, 0.04)
        materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
    }

    // ==================== 4. DUAL SLIDING BULKHEAD PANELS ====================
    // Left leaf: at progress=0 occupies X in [-50, 0]; at progress=1 occupies X in [-102, -52]
    Node {
        id: leftLeaf
        position: Qt.vector3d(-25.0 - 52.0 * root.progress, 144.0, 0.0)

        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.50, 2.88, 0.12)
            materials: [
                PrincipledMaterial {
                    baseColorMap: texDoorPanel
                    baseColor: (root.typeVal === Door.MainExit) ? "#ffe0a3" : "#cfd8e3"
                    roughness: 0.5
                    metalness: 0.65
                }
            ]
        }
        // Central locking seam rib & status bar
        Model {
            source: "#Cube"
            position: Qt.vector3d(22, 0, 0)
            scale: Qt.vector3d(0.06, 2.80, 0.135)
            materials: [ PrincipledMaterial { baseColor: "#1a2129"; roughness: 0.35; metalness: 0.85 } ]
        }
        Model {
            source: "#Cube"
            position: Qt.vector3d(12, 10, 0)
            scale: Qt.vector3d(0.04, 0.65, 0.138)
            materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
        }
    }

    // Right leaf: at progress=0 occupies X in [0, +50]; at progress=1 occupies X in [+52, +102]
    Node {
        id: rightLeaf
        position: Qt.vector3d(25.0 + 52.0 * root.progress, 144.0, 0.0)

        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.50, 2.88, 0.12)
            materials: [
                PrincipledMaterial {
                    baseColorMap: texDoorPanel
                    baseColor: (root.typeVal === Door.MainExit) ? "#ffe0a3" : "#cfd8e3"
                    roughness: 0.5
                    metalness: 0.65
                }
            ]
        }
        // Central locking seam rib & status bar
        Model {
            source: "#Cube"
            position: Qt.vector3d(-22, 0, 0)
            scale: Qt.vector3d(0.06, 2.80, 0.135)
            materials: [ PrincipledMaterial { baseColor: "#1a2129"; roughness: 0.35; metalness: 0.85 } ]
        }
        Model {
            source: "#Cube"
            position: Qt.vector3d(-12, 10, 0)
            scale: Qt.vector3d(0.04, 0.65, 0.138)
            materials: [ PrincipledMaterial { baseColor: root.statusColor; lighting: PrincipledMaterial.NoLighting } ]
        }
    }
}

