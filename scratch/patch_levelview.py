# scratch/patch_levelview.py
with open("qml/LevelView.qml", "r", encoding="utf-8") as f:
    content = f.read()

start_marker = "        id: level1PuzzlesNode\n        visible: root.levelManager && root.levelManager.currentLevel === 1\n"
end_marker = "        // ==================== 6. TOXIC GAS LEAK VOLUMETRIC HAZE & EXHAUST SWITCHES ===================="

start_idx = content.find(start_marker)
assert start_idx != -1, "start_marker not found"
puzzles_content_start = start_idx + len(start_marker)

end_node_idx = content.find("\n    }\n}\n", start_idx)
assert end_node_idx != -1, "end_node_idx not found"

new_level1_content = """
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
                                        text: "K1: " + (root.levelManager ? root.levelManager.k1Digit : 0)
                                        color: "#00e5ff"
                                        font.pixelSize: 60
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

            // Staggered Waist-High Cover Rows (1.2m tall = 120 units, Y=60)
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

            // 3 Shootable Glowing Power Relays high on walls/ceiling beams (Key 2: Ceiling=700)
            Repeater3D {
                model: (root.levelManager && root.levelManager.powerRelays) ? root.levelManager.powerRelays : []
                delegate: Node {
                    visible: !modelData.destroyed
                    position: Qt.vector3d(modelData.x, modelData.y, modelData.z)

                    Model {
                        source: "#Sphere"
                        scale: Qt.vector3d(0.5, 0.5, 0.5)
                        materials: [ PrincipledMaterial {
                            baseColor: "#ff2a6d"
                            roughness: 0.1
                            metalness: 0.9
                            lighting: PrincipledMaterial.NoLighting
                        } ]
                    }
                    Model {
                        source: "#Cylinder"
                        scale: Qt.vector3d(0.65, 0.15, 0.65)
                        materials: [ PrincipledMaterial { baseColor: "#05d9e8"; lighting: PrincipledMaterial.NoLighting } ]
                    }
                    PointLight {
                        position: Qt.vector3d(0, 0, 0)
                        color: "#ff2a6d"
                        brightness: 7.0
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
                                        text: "K2: " + (root.levelManager ? root.levelManager.k2Digit : 0)
                                        color: "#00e5ff"
                                        font.pixelSize: 60
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

            // Central Vault Enclosure holding Key 3 (Rows 9..14, Cols 8..11 -> X=950, Z=1150)
            Model {
                position: Qt.vector3d(950, 120, 1150)
                source: "#Cube"
                scale: Qt.vector3d(1.8, 2.4, 1.8)
                materials: [ PrincipledMaterial { baseColor: "#1c2833"; roughness: 0.6; metalness: 0.7 } ]
            }
            PointLight {
                position: Qt.vector3d(950, 180, 1150)
                color: "#f1c40f"
                brightness: 4.0
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
                                        text: "K3: " + (root.levelManager ? root.levelManager.k3Digit : 0)
                                        color: "#00e5ff"
                                        font.pixelSize: 60
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
            // Jumpable 1m Crate Access Step (Row 13, Col 38 -> X=3850, Z=1350)
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
            PointLight {
                position: Qt.vector3d(3850, 300, 1150)
                color: "#00e5ff"
                brightness: 5.0
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
                                        text: "K4: " + (root.levelManager ? root.levelManager.k4Digit : 0)
                                        color: "#00e5ff"
                                        font.pixelSize: 60
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
            // Status Light: Red when locked, Green when code solved & 4 keys held
            PointLight {
                position: Qt.vector3d(0, 280, 20)
                color: (root.levelManager && root.levelManager.overrideCodeSolved && root.levelManager.collectedKeysCount >= 4) ? "#2ecc71" : "#e74c3c"
                brightness: 6.0
            }

            // Keypad Terminal Pedestal at door entrance
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
                    baseColor: (root.levelManager && root.levelManager.overrideCodeSolved) ? "#2ecc71" : "#00e5ff"
                    lighting: PrincipledMaterial.NoLighting
                } ]
            }
            PointLight {
                position: Qt.vector3d(130, 140, 280)
                color: (root.levelManager && root.levelManager.overrideCodeSolved) ? "#2ecc71" : "#00e5ff"
                brightness: 3.0
            }
        }
"""

content = content[:puzzles_content_start] + new_level1_content + content[end_node_idx:]

with open("qml/LevelView.qml", "w", encoding="utf-8") as f:
    f.write(content)

print("LevelView.qml patched cleanly!")
