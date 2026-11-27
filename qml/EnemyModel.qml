import QtQuick
import QtQuick3D
import FPSLabGame

/**
 * @brief EnemyModel renders the 3D voxel model for an enemy.
 * Supports:
 *  - Drone: Futuristic quadcopter flying machine with spinning rotors, ion thruster,
 *           hover bobbing/banking, dual plasma blaster cannons (shooter variant)
 *           or heavy ramming prow & shock arc blades (melee variant), with close-range damage.
 *  - Sentinel: Heavy bipedal combat gunner mech.
 *  - Death Simulation: Replaces miniature shrink (0.1) with a realistic scattering explosion
 *                      of mechanical scraps (hull plates, rotor arms, turbine blades,
 *                      glowing power core fragments, barrels, and circuits) that blast outward,
 *                      arc in mid-air, bounce, and settle as wreckage on the floor.
 */
Node {
    id: root

    property var enemyObj: null
    property real cameraYaw: 0

    readonly property bool isDrone: enemyObj ? (enemyObj.enemyType === Enemy.Drone) : true
    readonly property bool isVisible: enemyObj ? enemyObj.isVisible : false
    readonly property bool isDead: enemyObj ? enemyObj.isDead : false

    // Flying Drone Hover Animations
    property real hoverBob: 0
    property real hoverTilt: 0
    property real rotorAngle: 0
    readonly property real forwardBank: (enemyObj && enemyObj.isAttacking) ? -12 : ((enemyObj && enemyObj.stateString === "CHASE") ? -7 : 0)

    // Dedicated High-Resolution Terminator Mech Textures
    Texture {
        id: texSentinelHead
        source: "../assets/textures/sentinel_head.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }
    Texture {
        id: texSentinelArmor
        source: "../assets/textures/sentinel_armor.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }
    Texture {
        id: texSentinelCore
        source: "../assets/textures/sentinel_core.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }
    Texture {
        id: texSentinelGun
        source: "../assets/textures/sentinel_gun.png"
        magFilter: Texture.Linear
        minFilter: Texture.Linear
        generateMipmaps: true
    }

    // Terminator Bipedal Mech Walk & Stance Animations
    property real sentinelWalkPhase: 0.0
    readonly property bool isSentinelWalking: !root.isDrone && root.enemyObj && (root.enemyObj.stateString === "CHASE" || root.enemyObj.stateString === "SEARCH" || root.enemyObj.stateString === "GUARD" || root.enemyObj.stateString === "AIM")

    NumberAnimation on sentinelWalkPhase {
        from: 0
        to: Math.PI * 2
        duration: 950
        loops: Animation.Infinite
        running: root.isVisible && !root.isDead && root.isSentinelWalking
    }

    readonly property real legSwingAngle: isSentinelWalking ? Math.sin(sentinelWalkPhase) * 24 : 0
    readonly property real armSwingAngle: isSentinelWalking ? -Math.sin(sentinelWalkPhase) * 20 : 0
    readonly property real torsoBob: isSentinelWalking ? Math.abs(Math.sin(sentinelWalkPhase * 2)) * 3.0 : 0

    // Scrap Debris Death Simulation Properties
    property bool isDying: false
    property real scrapProgress: 0.0
    property real scrapFade: 1.0

    // Hover bobbing animation (continuous floating motion for flying machines)
    NumberAnimation on hoverBob {
        from: -7
        to: 7
        duration: 1300
        easing.type: Easing.InOutSine
        loops: Animation.Infinite
        running: root.isVisible && !root.isDead && root.isDrone
    }

    // Hover tilt sway animation
    NumberAnimation on hoverTilt {
        from: -2.5
        to: 2.5
        duration: 1700
        easing.type: Easing.InOutSine
        loops: Animation.Infinite
        running: root.isVisible && !root.isDead && root.isDrone
    }

    // High-speed rotor blade spinning animation
    NumberAnimation on rotorAngle {
        from: 0
        to: 360
        duration: 180
        loops: Animation.Infinite
        running: root.isVisible && !root.isDead && root.isDrone
    }

    // Death simulation trigger
    onIsDeadChanged: {
        if (isDead) {
            isDying = true
            deathAnim.restart()
        } else {
            isDying = false
            deathAnim.stop()
            scrapProgress = 0.0
            scrapFade = 1.0
        }
    }

    // Scrap debris ballistic explosion animation
    SequentialAnimation {
        id: deathAnim
        ScriptAction {
            script: {
                root.isDying = true
                root.scrapProgress = 0.0
                root.scrapFade = 1.0
            }
        }
        // Phase 1: High velocity scatter & arc down to floor
        NumberAnimation {
            target: root
            property: "scrapProgress"
            from: 0.0
            to: 1.0
            duration: 850
            easing.type: Easing.OutQuad
        }
        // Phase 2: Rest on the floor as scattered wreckage
        PauseAnimation {
            duration: 500
        }
        // Phase 3: Dissipate / fade out
        NumberAnimation {
            target: root
            property: "scrapFade"
            from: 1.0
            to: 0.0
            duration: 400
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                root.isDying = false
            }
        }
    }

    position: enemyObj ? enemyObj.position : Qt.vector3d(0, -9999, 0)
    eulerRotation: Qt.vector3d(0, enemyObj ? enemyObj.rotationY : 0, 0)
    visible: isVisible || isDying

    // ==================== INTACT ALIVE BODY NODE ====================
    Node {
        id: aliveBodyNode
        visible: !root.isDead

        // ==================== DRONE MODEL (Quadcopter Flying Machine) ====================
        Node {
            id: droneNode
            visible: root.isDrone

            readonly property bool isShooter: root.enemyObj ? root.enemyObj.canShoot : false
            readonly property bool isAttacking: root.enemyObj ? root.enemyObj.isAttacking : false
            readonly property bool isShooting: root.enemyObj ? root.enemyObj.isShooting : false

            // Elevated hovering flight altitude with dynamic bobbing and pitch banking
            position: Qt.vector3d(0, 95 + root.hoverBob, 0)
            eulerRotation: Qt.vector3d(root.forwardBank + root.hoverTilt, 0, root.hoverTilt * 0.7)

            // 1. Central Aerodynamic Fuselage Pod (Sleek angular hull)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.55, 0.32, 0.65)
                position: Qt.vector3d(0, 0, 0)
                materials: [ PrincipledMaterial {
                    baseColor: "#1e293b" // Deep dark slate composite
                    metalness: 0.8
                    roughness: 0.35
                }]
            }

            // 2. Upper Armored Cowling / Shield Crest (Variant accent color)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.42, 0.16, 0.52)
                position: Qt.vector3d(0, 14, -2)
                materials: [ PrincipledMaterial {
                    // Shock Drone: Electric Cyan/Blue; Ranged Drone: Crimson Red
                    baseColor: !droneNode.isShooter ? "#0284c7" : (droneNode.isAttacking ? "#ff3333" : "#dc2626")
                    metalness: 0.6
                    roughness: 0.4
                }]
            }

            // 3. Central Sensor Visor / Optical Camera Eye (Glowing Front Sensor)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.36, 0.12, 0.1)
                position: Qt.vector3d(0, 2, 33)
                materials: [ PrincipledMaterial {
                    baseColor: !droneNode.isShooter ? "#00f0ff" : "#ff1122"
                    lighting: PrincipledMaterial.NoLighting
                }]
            }

            // 4. Rear Power Generator Vent / Thruster Grille
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.28, 0.14, 0.08)
                position: Qt.vector3d(0, 2, -33)
                materials: [ PrincipledMaterial {
                    baseColor: !droneNode.isShooter ? "#38bdf8" : "#f59e0b"
                    lighting: PrincipledMaterial.NoLighting
                }]
            }

            // 5. Underbelly Anti-Gravity Repulsor Thruster
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.26, 0.1, 0.26)
                position: Qt.vector3d(0, -18, 0)
                materials: [ PrincipledMaterial {
                    baseColor: "#0f172a"
                    metalness: 0.9
                    roughness: 0.2
                }]
            }
            // Plasma Ion Thrust Flame beneath repulsor
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.16, 0.25, 0.16)
                position: Qt.vector3d(0, -28, 0)
                materials: [ PrincipledMaterial {
                    baseColor: !droneNode.isShooter ? "#00e5ff" : "#ff4400"
                    lighting: PrincipledMaterial.NoLighting
                }]
            }

            // 6. Quadcopter Outrigger Rotor Pylons (4 Diagonal Boom Arms)
            // Front-Left Arm
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.1, 0.08, 0.48)
                position: Qt.vector3d(-24, 6, 20)
                eulerRotation: Qt.vector3d(0, -42, 0)
                materials: [ PrincipledMaterial { baseColor: "#111827"; roughness: 0.5 } ]
            }
            // Front-Right Arm
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.1, 0.08, 0.48)
                position: Qt.vector3d(24, 6, 20)
                eulerRotation: Qt.vector3d(0, 42, 0)
                materials: [ PrincipledMaterial { baseColor: "#111827"; roughness: 0.5 } ]
            }
            // Rear-Left Arm
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.1, 0.08, 0.48)
                position: Qt.vector3d(-24, 6, -20)
                eulerRotation: Qt.vector3d(0, -138, 0)
                materials: [ PrincipledMaterial { baseColor: "#111827"; roughness: 0.5 } ]
            }
            // Rear-Right Arm
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.1, 0.08, 0.48)
                position: Qt.vector3d(24, 6, -20)
                eulerRotation: Qt.vector3d(0, 138, 0)
                materials: [ PrincipledMaterial { baseColor: "#111827"; roughness: 0.5 } ]
            }

            // 7. Four Rotor Nacelles & High-Speed Spinning Propellers
            // Nacelle 1: Front-Left (-40, 10, 36)
            Node {
                position: Qt.vector3d(-40, 10, 36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.2, 0.08, 0.2)
                    materials: [ PrincipledMaterial { baseColor: "#334155" } ]
                }
                Node {
                    eulerRotation.y: root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.48, 0.02, 0.07)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.07, 0.02, 0.48)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                }
            }
            // Nacelle 2: Front-Right (40, 10, 36)
            Node {
                position: Qt.vector3d(40, 10, 36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.2, 0.08, 0.2)
                    materials: [ PrincipledMaterial { baseColor: "#334155" } ]
                }
                Node {
                    eulerRotation.y: -root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.48, 0.02, 0.07)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.07, 0.02, 0.48)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                }
            }
            // Nacelle 3: Rear-Left (-40, 10, -36)
            Node {
                position: Qt.vector3d(-40, 10, -36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.2, 0.08, 0.2)
                    materials: [ PrincipledMaterial { baseColor: "#334155" } ]
                }
                Node {
                    eulerRotation.y: -root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.48, 0.02, 0.07)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.07, 0.02, 0.48)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                }
            }
            // Nacelle 4: Rear-Right (40, 10, -36)
            Node {
                position: Qt.vector3d(40, 10, -36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.2, 0.08, 0.2)
                    materials: [ PrincipledMaterial { baseColor: "#334155" } ]
                }
                Node {
                    eulerRotation.y: root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.48, 0.02, 0.07)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.07, 0.02, 0.48)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#94a3b8"; metalness: 0.8 } ]
                    }
                }
            }

            // 8. Weapon Variant A: SHOOTER DRONE (Dual Underslung Repeating Blasters)
            Node {
                visible: droneNode.isShooter

                // Left Blaster Cannon
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.08, 0.42)
                    position: Qt.vector3d(-18, -12, 24)
                    materials: [ PrincipledMaterial { baseColor: "#0f172a"; metalness: 0.9; roughness: 0.2 } ]
                }
                // Left Cannon Energy Coil
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.1, 0.1, 0.12)
                    position: Qt.vector3d(-18, -12, 18)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // Right Blaster Cannon
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.08, 0.42)
                    position: Qt.vector3d(18, -12, 24)
                    materials: [ PrincipledMaterial { baseColor: "#0f172a"; metalness: 0.9; roughness: 0.2 } ]
                }
                // Right Cannon Energy Coil
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.1, 0.1, 0.12)
                    position: Qt.vector3d(18, -12, 18)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // Dual Muzzle Flash (Flashes when firing)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.14, 0.14, 0.14)
                    position: Qt.vector3d(-18, -12, 47)
                    visible: droneNode.isShooting
                    materials: [ PrincipledMaterial { baseColor: "#00f0ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.14, 0.14, 0.14)
                    position: Qt.vector3d(18, -12, 47)
                    visible: droneNode.isShooting
                    materials: [ PrincipledMaterial { baseColor: "#00f0ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
            }

            // 9. Weapon Variant B: MELEE RAMMER DRONE (Reinforced Ramming Nose & Shock Prongs)
            Node {
                visible: !droneNode.isShooter

                // Heavy Ramming Prow Nose
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.32, 0.2, 0.22)
                    position: Qt.vector3d(0, -6, 32)
                    materials: [ PrincipledMaterial {
                        baseColor: droneNode.isAttacking ? "#ff4444" : "#7f1d1d"
                        metalness: 0.8
                        roughness: 0.3
                    }]
                }

                // Left High-Voltage Shock Blade Prong
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.14, 0.35)
                    position: Qt.vector3d(-16, -4, 42)
                    materials: [ PrincipledMaterial {
                        baseColor: "#e2e8f0"
                        metalness: 0.9
                        roughness: 0.1
                    }]
                }
                // Left Shock Blade Arc Tip
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.16, 0.1)
                    position: Qt.vector3d(-16, -4, 57)
                    materials: [ PrincipledMaterial {
                        baseColor: "#ffaa00"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }

                // Right High-Voltage Shock Blade Prong
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.14, 0.35)
                    position: Qt.vector3d(16, -4, 42)
                    materials: [ PrincipledMaterial {
                        baseColor: "#e2e8f0"
                        metalness: 0.9
                        roughness: 0.1
                    }]
                }
                // Right Shock Blade Arc Tip
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.16, 0.1)
                    position: Qt.vector3d(16, -4, 57)
                    materials: [ PrincipledMaterial {
                        baseColor: "#ffaa00"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
            }
        }

        // ==================== SENTINEL MODEL (Terminator Combat Gunner Mech) ====================
        Node {
            id: sentinelNode
            visible: !root.isDrone
            position: Qt.vector3d(0, root.torsoBob, 0)

            // --- 1. Cybernetic Skull / Head ---
            Node {
                position: Qt.vector3d(0, 155, 0)

                // Armored Skull Faceplate (Bright silver titanium alloy)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.50, 0.48, 0.48)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelHead
                        metalness: 0.30
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
                    }]
                }
                // Glowing Ruby Ocular Visor / Sensor Strip
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.44, 0.14, 0.14)
                    position: Qt.vector3d(0, 1, 24)
                    materials: [ PrincipledMaterial {
                        baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#ff0033" : "#ff2244"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Temple Hydraulic Armor Plates (Left & Right - Light silver alloy)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.32, 0.35)
                    position: Qt.vector3d(-26, -2, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.32, 0.35)
                    position: Qt.vector3d(26, -2, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
            }

            // --- 2. Heavy Armored Torso & Core Reactor ---
            Node {
                position: Qt.vector3d(0, 105, 0)

                // Upper Chest Ballistic Carapace (Bright polished titanium plates)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.75, 0.52, 0.44)
                    position: Qt.vector3d(0, 8, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.32
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
                    }]
                }
                // Core Plasma Reactor Housing
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.42, 0.42, 0.46)
                    position: Qt.vector3d(0, 6, 2)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelCore
                        metalness: 0.30
                        roughness: 0.42
                        emissiveFactor: Qt.vector3d(0.14, 0.12, 0.12)
                    }]
                }
                // Glowing Reactor Exhaust Vent (Glows brighter when attacking)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.18, 0.08)
                    position: Qt.vector3d(0, 6, 25)
                    materials: [ PrincipledMaterial {
                        baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#ff2200" : "#ff7700"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Abdominal Spinal Vertebrae & Power Conduits
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.42, 0.32, 0.32)
                    position: Qt.vector3d(0, -28, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelCore
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }

                // Left Heavy Shoulder Pauldron
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.32, 0.22, 0.45)
                    position: Qt.vector3d(-46, 25, 0)
                    eulerRotation: Qt.vector3d(0, 0, 15)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
                    }]
                }
                // Right Heavy Shoulder Pauldron
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.32, 0.22, 0.45)
                    position: Qt.vector3d(46, 25, 0)
                    eulerRotation: Qt.vector3d(0, 0, -15)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
                    }]
                }
            }

            // --- 3. Left Arm (Tactical Stabilizer & Combat Claw) ---
            Node {
                position: Qt.vector3d(-48, 110, 0)
                eulerRotation: Qt.vector3d(root.armSwingAngle, 0, 8)

                // Upper Hydraulic Arm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.40, 0.20)
                    position: Qt.vector3d(0, -18, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Elbow Servo Joint (Light titanium joint)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.12, 0.18)
                    position: Qt.vector3d(0, -38, 0)
                    materials: [ PrincipledMaterial { baseColor: "#5a687c"; metalness: 0.45; roughness: 0.40 }]
                }
                // Armored Forearm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.38, 0.18)
                    position: Qt.vector3d(0, -56, 4)
                    eulerRotation: Qt.vector3d(-15, 0, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Tactical Combat Claw (Bright chrome finish)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.14, 0.16, 0.20)
                    position: Qt.vector3d(0, -74, 8)
                    materials: [ PrincipledMaterial { baseColor: "#8b9cb0"; metalness: 0.50; roughness: 0.30 }]
                }
            }

            // --- 4. Right Arm with Heavy Plasma Assault Cannon ---
            Node {
                position: Qt.vector3d(48, 110, 0)
                eulerRotation: Qt.vector3d(-65 - (root.enemyObj && root.enemyObj.isShooting ? 12 : 0), -5, -8)

                // Upper Arm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.40, 0.20)
                    position: Qt.vector3d(0, -18, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Elbow Servo
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.12, 0.18)
                    position: Qt.vector3d(0, -38, 0)
                    materials: [ PrincipledMaterial { baseColor: "#5a687c"; metalness: 0.45; roughness: 0.40 }]
                }
                // Armored Forearm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.38, 0.20)
                    position: Qt.vector3d(0, -56, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }

                // Heavy Plasma Assault Cannon
                Node {
                    position: Qt.vector3d(2, -64, 16)

                    // Cannon Receiver & Frame (Bright silver/titanium)
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.22, 0.28, 0.75)
                        position: Qt.vector3d(0, 0, 10)
                        materials: [ PrincipledMaterial {
                            baseColorMap: texSentinelGun
                            metalness: 0.35
                            roughness: 0.38
                            emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                        }]
                    }
                    // Glowing Plasma Energy Coils (Top Chamber)
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.14, 0.12, 0.32)
                        position: Qt.vector3d(0, 14, 6)
                        materials: [ PrincipledMaterial {
                            baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#ff3300" : "#ff7700"
                            lighting: PrincipledMaterial.NoLighting
                        }]
                    }
                    // Heavy Heat-Dissipation Barrel
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.14, 0.14, 0.55)
                        position: Qt.vector3d(0, 0, 48)
                        materials: [ PrincipledMaterial {
                            baseColor: "#627284"
                            metalness: 0.50
                            roughness: 0.30
                        }]
                    }
                    // Muzzle Shroud / Flash Compensator
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.18, 0.18, 0.15)
                        position: Qt.vector3d(0, 0, 72)
                        materials: [ PrincipledMaterial {
                            baseColor: "#718296"
                            metalness: 0.45
                            roughness: 0.35
                        }]
                    }
                    // High-Energy Muzzle Flash
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.22, 0.22, 0.22)
                        position: Qt.vector3d(0, 0, 84)
                        visible: root.enemyObj ? root.enemyObj.isShooting : false
                        materials: [ PrincipledMaterial {
                            baseColor: "#ffaa00"
                            lighting: PrincipledMaterial.NoLighting
                        }]
                    }
                }
            }

            // --- 5. Armored Pelvis & Bipedal Legs ---
            // Pelvis
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.58, 0.20, 0.36)
                position: Qt.vector3d(0, 62, 0)
                materials: [ PrincipledMaterial {
                    baseColorMap: texSentinelArmor
                    metalness: 0.35
                    roughness: 0.38
                    emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                }]
            }

            // Left Leg (Swings with sentinelWalkPhase)
            Node {
                position: Qt.vector3d(-20, 56, 0)
                eulerRotation: Qt.vector3d(root.legSwingAngle, 0, 0)

                // Armored Thigh
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.24, 0.35, 0.24)
                    position: Qt.vector3d(0, -16, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Knee Hydraulic Actuator
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.10, 0.22)
                    position: Qt.vector3d(0, -32, 2)
                    materials: [ PrincipledMaterial { baseColor: "#5a687c"; metalness: 0.45; roughness: 0.40 }]
                }
                // Armored Shin & Calf Plate
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.22, 0.34, 0.22)
                    position: Qt.vector3d(0, -48, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Magnetic Heavy Combat Boot (Bright titanium alloy)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.12, 0.36)
                    position: Qt.vector3d(0, -66, 6)
                    materials: [ PrincipledMaterial { baseColor: "#6b7c93"; metalness: 0.45; roughness: 0.35 }]
                }
            }

            // Right Leg (Swings counter-phase)
            Node {
                position: Qt.vector3d(20, 56, 0)
                eulerRotation: Qt.vector3d(-root.legSwingAngle, 0, 0)

                // Armored Thigh
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.24, 0.35, 0.24)
                    position: Qt.vector3d(0, -16, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.40
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Knee Hydraulic Actuator
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.10, 0.22)
                    position: Qt.vector3d(0, -32, 2)
                    materials: [ PrincipledMaterial { baseColor: "#5a687c"; metalness: 0.45; roughness: 0.40 }]
                }
                // Armored Shin & Calf Plate
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.22, 0.34, 0.22)
                    position: Qt.vector3d(0, -48, 0)
                    materials: [ PrincipledMaterial {
                        baseColorMap: texSentinelArmor
                        metalness: 0.35
                        roughness: 0.38
                        emissiveFactor: Qt.vector3d(0.10, 0.12, 0.14)
                    }]
                }
                // Magnetic Heavy Combat Boot (Bright titanium alloy)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.12, 0.36)
                    position: Qt.vector3d(0, -66, 6)
                    materials: [ PrincipledMaterial { baseColor: "#6b7c93"; metalness: 0.45; roughness: 0.35 }]
                }
            }
        }
    }

    // ==================== MECHANICAL SCRAPS & DEBRIS EXPLOSION (On Death) ====================
    Node {
        id: scrapDebrisNode
        visible: root.isDying

        // Helper function for ballistic arc trajectory to floor
        function calcScrapY(startY, floorY, peakUp, p) {
            var arc = peakUp * Math.sin(p * Math.PI)
            var drop = (startY - floorY) * (p * p)
            return Math.max(floorY, startY + arc - drop)
        }

        // Scrap 1: Armored Hull Plate (sheared off)
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.42, 0.08, 0.35)
            position: Qt.vector3d(-65 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 4, 45, root.scrapProgress),
                                  55 * root.scrapProgress)
            eulerRotation: Qt.vector3d(420 * root.scrapProgress, 260 * root.scrapProgress, 510 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: root.isDrone ? "#1e293b" : "#8b1e0f"
                metalness: 0.8
                roughness: 0.3
                opacity: root.scrapFade
            }]
        }

        // Scrap 2: Rotor Arm Boom / Structural Strut
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.12, 0.12, 0.65)
            position: Qt.vector3d(75 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 5, 60, root.scrapProgress),
                                  -50 * root.scrapProgress)
            eulerRotation: Qt.vector3d(540 * root.scrapProgress, 380 * root.scrapProgress, 310 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#111827"
                metalness: 0.5
                roughness: 0.6
                opacity: root.scrapFade
            }]
        }

        // Scrap 3: Propeller / Turbine Blade Fragment
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.45, 0.03, 0.12)
            position: Qt.vector3d(15 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 3, 75, root.scrapProgress),
                                  85 * root.scrapProgress)
            eulerRotation: Qt.vector3d(720 * root.scrapProgress, 600 * root.scrapProgress, 180 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#94a3b8"
                metalness: 0.9
                roughness: 0.2
                opacity: root.scrapFade
            }]
        }

        // Scrap 4: Ruptured Glowing Power Core (Emissive burning ember)
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.2, 0.2, 0.2)
            position: Qt.vector3d(-55 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 6, 35, root.scrapProgress),
                                  -65 * root.scrapProgress)
            eulerRotation: Qt.vector3d(360 * root.scrapProgress, 480 * root.scrapProgress, 420 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#ff5500"
                lighting: PrincipledMaterial.NoLighting
                opacity: root.scrapFade
            }]
        }

        // Scrap 5: Blaster Barrel / Shock Prong Segment
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.08, 0.08, 0.48)
            position: Qt.vector3d(80 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 4, 50, root.scrapProgress),
                                  30 * root.scrapProgress)
            eulerRotation: Qt.vector3d(630 * root.scrapProgress, 210 * root.scrapProgress, 390 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#0f172a"
                metalness: 0.9
                roughness: 0.2
                opacity: root.scrapFade
            }]
        }

        // Scrap 6: Heavy Joint Bracket / Repulsor Housing
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.28, 0.2, 0.28)
            position: Qt.vector3d(-35 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 7, 20, root.scrapProgress),
                                  15 * root.scrapProgress)
            eulerRotation: Qt.vector3d(180 * root.scrapProgress, 150 * root.scrapProgress, 200 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#334155"
                metalness: 0.7
                roughness: 0.4
                opacity: root.scrapFade
            }]
        }

        // Scrap 7: Optical Sensor Visor Shard (Glowing)
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.22, 0.08, 0.08)
            position: Qt.vector3d(-45 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 2, 40, root.scrapProgress),
                                  70 * root.scrapProgress)
            eulerRotation: Qt.vector3d(500 * root.scrapProgress, 360 * root.scrapProgress, 440 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: root.isDrone ? "#00f0ff" : "#ff0022"
                lighting: PrincipledMaterial.NoLighting
                opacity: root.scrapFade
            }]
        }

        // Scrap 8: Avionics Circuit Plate
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.26, 0.05, 0.22)
            position: Qt.vector3d(45 * root.scrapProgress,
                                  scrapDebrisNode.calcScrapY(90, 3, 30, root.scrapProgress),
                                  -80 * root.scrapProgress)
            eulerRotation: Qt.vector3d(310 * root.scrapProgress, 450 * root.scrapProgress, 270 * root.scrapProgress)
            materials: [ PrincipledMaterial {
                baseColor: "#0f766e"
                metalness: 0.4
                roughness: 0.6
                opacity: root.scrapFade
            }]
        }
    }

    // ==================== ENEMY HEALTH BAR (red, billboarded above head) ====================
    Node {
        position: Qt.vector3d(0, root.isDrone ? 155 : 200, 0)
        visible: root.isVisible && root.enemyObj && !root.isDead
        // Billboard: face camera only when visible
        eulerRotation: root.isVisible ? Qt.vector3d(0, -root.cameraYaw, 0) : Qt.vector3d(0, 0, 0)

        // Background bar
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.6, 0.06, 0.02)
            materials: [ PrincipledMaterial {
                baseColor: "#1a1a1a"
                lighting: PrincipledMaterial.NoLighting
            }]
        }
        // Health fill bar (red)
        Model {
            source: "#Cube"
            property real healthPct: (root.enemyObj && root.enemyObj.maxHealth > 0)
                                     ? (root.enemyObj.health / root.enemyObj.maxHealth) : 0
            scale: Qt.vector3d(0.58 * healthPct, 0.04, 0.025)
            position: Qt.vector3d(-29 * (1.0 - healthPct), 0, 0.5)
            materials: [ PrincipledMaterial {
                baseColor: "#c0392b"
                lighting: PrincipledMaterial.NoLighting
            }]
        }
    }
}
