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

    // Dedicated Nearest-Filtered Enemy Textures & Dark Facility Metallic Materials
    Texture {
        id: texDronePanel
        source: "../assets/textures/drone_panel.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }
    Texture {
        id: texSentinelHead
        source: "../assets/textures/sentinel_head.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }
    Texture {
        id: texSentinelArmor
        source: "../assets/textures/sentinel_armor.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }
    Texture {
        id: texSentinelCore
        source: "../assets/textures/sentinel_core.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }
    Texture {
        id: texSentinelGun
        source: "../assets/textures/sentinel_gun.png"
        magFilter: Texture.Nearest
        minFilter: Texture.Nearest
        generateMipmaps: false
    }

    // ==================== REUSABLE PRINCIPLED MATERIALS ====================
    // Drone Brushed Gunmetal Chassis (#23272E, metalness: 0.8, roughness: 0.3)
    PrincipledMaterial {
        id: matDroneChassis
        baseColorMap: texDronePanel
        baseColor: "#23272E"
        metalness: 0.80
        roughness: 0.30
    }

    // Dark Recessed Mechanical Joint Material (#2D3748)
    PrincipledMaterial {
        id: matDarkMechJoint
        baseColor: "#2D3748"
        metalness: 0.65
        roughness: 0.35
    }

    // High-Visibility Tactical Titanium Sentinel Armor Plating
    PrincipledMaterial {
        id: matSentinelHead
        baseColorMap: texSentinelHead
        baseColor: "#E2E8F0"
        metalness: 0.55
        roughness: 0.35
        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
    }

    PrincipledMaterial {
        id: matSentinelArmor
        baseColorMap: texSentinelArmor
        baseColor: "#E2E8F0"
        metalness: 0.55
        roughness: 0.35
        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
    }

    PrincipledMaterial {
        id: matSentinelCore
        baseColorMap: texSentinelCore
        baseColor: "#CBD5E1"
        metalness: 0.55
        roughness: 0.35
        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
    }

    PrincipledMaterial {
        id: matSentinelGun
        baseColorMap: texSentinelGun
        baseColor: "#E2E8F0"
        metalness: 0.55
        roughness: 0.35
        emissiveFactor: Qt.vector3d(0.12, 0.14, 0.16)
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

            // 1. Central Fuselage Pod (Dark brushed gunmetal with metallic panel texture)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.55, 0.32, 0.65)
                position: Qt.vector3d(0, 0, 0)
                materials: [ matDroneChassis ]
            }

            // 2. Upper Armored Cowling / Crest (Dark gunmetal with variant accent)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.42, 0.16, 0.52)
                position: Qt.vector3d(0, 14, -2)
                materials: [ PrincipledMaterial {
                    baseColorMap: texDronePanel
                    baseColor: droneNode.isShooter ? (droneNode.isAttacking ? "#4A1818" : "#2A1F22") : (droneNode.isAttacking ? "#18384A" : "#1B2734")
                    metalness: 0.80
                    roughness: 0.30
                }]
            }

            // 3. Narrow Glowing Optical Visor Slit
            // Ranged Drones: glowing crimson (#FF1E1E); Close-Shock Drones: glowing electric-cyan (#00E5FF)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.32, 0.045, 0.08)
                position: Qt.vector3d(0, 2, 33)
                materials: [ PrincipledMaterial {
                    baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                    lighting: PrincipledMaterial.NoLighting
                    emissiveFactor: Qt.vector3d(1.0, 1.0, 1.0)
                }]
            }
            // Recessed Visor Housing Bevel
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.36, 0.09, 0.04)
                position: Qt.vector3d(0, 2, 32.5)
                materials: [ matDarkMechJoint ]
            }

            // 4. Rear Power Generator Vent / Thruster Slit
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.24, 0.06, 0.05)
                position: Qt.vector3d(0, 2, -33)
                materials: [ PrincipledMaterial {
                    baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                    lighting: PrincipledMaterial.NoLighting
                }]
            }

            // 5. Underbelly Anti-Gravity Repulsor Plate
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.28, 0.08, 0.28)
                position: Qt.vector3d(0, -17, 0)
                materials: [ matDarkMechJoint ]
            }

            // 6. Quadcopter Outrigger Rotor Pylons (4 Diagonal Boom Arms Angled Slightly Upward)
            // Front-Left Arm (pitched upward by 10 deg)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.10, 0.08, 0.50)
                position: Qt.vector3d(-24, 9, 20)
                eulerRotation: Qt.vector3d(-10, -42, 8)
                materials: [ matDarkMechJoint ]
            }
            // Front-Right Arm (pitched upward by 10 deg)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.10, 0.08, 0.50)
                position: Qt.vector3d(24, 9, 20)
                eulerRotation: Qt.vector3d(-10, 42, -8)
                materials: [ matDarkMechJoint ]
            }
            // Rear-Left Arm (pitched upward by 10 deg)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.10, 0.08, 0.50)
                position: Qt.vector3d(-24, 9, -20)
                eulerRotation: Qt.vector3d(10, -138, 8)
                materials: [ matDarkMechJoint ]
            }
            // Rear-Right Arm (pitched upward by 10 deg)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.10, 0.08, 0.50)
                position: Qt.vector3d(24, 9, -20)
                eulerRotation: Qt.vector3d(10, 138, -8)
                materials: [ matDarkMechJoint ]
            }

            // 7. Four Rotor Nacelles with Thin Dark Rotor Guard Frames & Rotor-Tip LEDs
            // Nacelle 1: Front-Left (-40, 16, 36)
            Node {
                position: Qt.vector3d(-40, 16, 36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    materials: [ matDroneChassis ]
                }
                // Rotor Guard Frame (Thin dark perimeter frame around spinning blades)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, 25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, -25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(-25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                // Rotor-Tip LED Marker (Red on Shooter, Electric-Cyan on Shock)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.04, 0.05)
                    position: Qt.vector3d(-25, 6, 25)
                    materials: [ PrincipledMaterial {
                        baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Spinning Blades
                Node {
                    eulerRotation.y: root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.46, 0.02, 0.06)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.06, 0.02, 0.46)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                }
            }

            // Nacelle 2: Front-Right (40, 16, 36)
            Node {
                position: Qt.vector3d(40, 16, 36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    materials: [ matDroneChassis ]
                }
                // Guard Frame
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, 25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, -25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(-25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                // LED Marker
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.04, 0.05)
                    position: Qt.vector3d(25, 6, 25)
                    materials: [ PrincipledMaterial {
                        baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Counter-Spinning Blades
                Node {
                    eulerRotation.y: -root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.46, 0.02, 0.06)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.06, 0.02, 0.46)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                }
            }

            // Nacelle 3: Rear-Left (-40, 16, -36)
            Node {
                position: Qt.vector3d(-40, 16, -36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    materials: [ matDroneChassis ]
                }
                // Guard Frame
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, 25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, -25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(-25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                // LED Marker
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.04, 0.05)
                    position: Qt.vector3d(-25, 6, -25)
                    materials: [ PrincipledMaterial {
                        baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Counter-Spinning Blades
                Node {
                    eulerRotation.y: -root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.46, 0.02, 0.06)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.06, 0.02, 0.46)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                }
            }

            // Nacelle 4: Rear-Right (40, 16, -36)
            Node {
                position: Qt.vector3d(40, 16, -36)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    materials: [ matDroneChassis ]
                }
                // Guard Frame
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, 25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.52, 0.025, 0.03)
                    position: Qt.vector3d(0, 5, -25)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(-25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.025, 0.52)
                    position: Qt.vector3d(25, 5, 0)
                    materials: [ matDarkMechJoint ]
                }
                // LED Marker
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.04, 0.05)
                    position: Qt.vector3d(25, 6, -25)
                    materials: [ PrincipledMaterial {
                        baseColor: droneNode.isShooter ? "#FF1E1E" : "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
                // Spinning Blades
                Node {
                    eulerRotation.y: root.rotorAngle
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.46, 0.02, 0.06)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.06, 0.02, 0.46)
                        position: Qt.vector3d(0, 5, 0)
                        materials: [ PrincipledMaterial { baseColor: "#718096"; metalness: 0.85; roughness: 0.25 } ]
                    }
                }
            }

            // 8. Weapon Variant A: RED RANGED DRONE (Sleek Under-Slung Dual-Barrel Blaster)
            Node {
                visible: droneNode.isShooter

                // Under-slung Blaster Mounting Bracket
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.24, 0.10, 0.38)
                    position: Qt.vector3d(0, -9, 12)
                    materials: [ matDroneChassis ]
                }

                // Left Heavy Blaster Barrel
                Model {
                    source: "#Cylinder"
                    eulerRotation: Qt.vector3d(90, 0, 0)
                    scale: Qt.vector3d(0.04, 0.32, 0.04)
                    position: Qt.vector3d(-10, -10, 28)
                    materials: [ PrincipledMaterial { baseColor: "#151920"; metalness: 0.90; roughness: 0.20 } ]
                }
                // Left Crimson Energy Coil
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.06, 0.12)
                    position: Qt.vector3d(-10, -10, 20)
                    materials: [ PrincipledMaterial { baseColor: "#FF1E1E"; lighting: PrincipledMaterial.NoLighting } ]
                }
                // Left Muzzle Compensator
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.055, 0.055, 0.06)
                    position: Qt.vector3d(-10, -10, 44)
                    materials: [ matDarkMechJoint ]
                }

                // Right Heavy Blaster Barrel
                Model {
                    source: "#Cylinder"
                    eulerRotation: Qt.vector3d(90, 0, 0)
                    scale: Qt.vector3d(0.04, 0.32, 0.04)
                    position: Qt.vector3d(10, -10, 28)
                    materials: [ PrincipledMaterial { baseColor: "#151920"; metalness: 0.90; roughness: 0.20 } ]
                }
                // Right Crimson Energy Coil
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.06, 0.12)
                    position: Qt.vector3d(10, -10, 20)
                    materials: [ PrincipledMaterial { baseColor: "#FF1E1E"; lighting: PrincipledMaterial.NoLighting } ]
                }
                // Right Muzzle Compensator
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.055, 0.055, 0.06)
                    position: Qt.vector3d(10, -10, 44)
                    materials: [ matDarkMechJoint ]
                }

                // Dual Muzzle Flash (Flashes when firing)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.12, 0.12)
                    position: Qt.vector3d(-10, -10, 48)
                    visible: droneNode.isShooting
                    materials: [ PrincipledMaterial { baseColor: "#FF3333"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.12, 0.12)
                    position: Qt.vector3d(10, -10, 48)
                    visible: droneNode.isShooting
                    materials: [ PrincipledMaterial { baseColor: "#FF3333"; lighting: PrincipledMaterial.NoLighting } ]
                }
            }

            // 9. Weapon Variant B: BLUE CLOSE-SHOCK DRONE (Twin Electric Shock Prongs)
            Node {
                visible: !droneNode.isShooter

                // Shock Electrode Mounting Yoke
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.30, 0.12, 0.26)
                    position: Qt.vector3d(0, -8, 14)
                    materials: [ matDroneChassis ]
                }

                // Left Shock Prong Blade
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.07, 0.36)
                    position: Qt.vector3d(-14, -6, 32)
                    materials: [ matDarkMechJoint ]
                }
                // Left Glowing Electric-Cyan Arc-Prong Tip (#00E5FF)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.08, 0.12)
                    position: Qt.vector3d(-14, -6, 50)
                    materials: [ PrincipledMaterial {
                        baseColor: "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }

                // Right Shock Prong Blade
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.05, 0.07, 0.36)
                    position: Qt.vector3d(14, -6, 32)
                    materials: [ matDarkMechJoint ]
                }
                // Right Glowing Electric-Cyan Arc-Prong Tip (#00E5FF)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.06, 0.08, 0.12)
                    position: Qt.vector3d(14, -6, 50)
                    materials: [ PrincipledMaterial {
                        baseColor: "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }

                // Central High-Voltage Arc Discharge Crossbar
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.24, 0.03, 0.03)
                    position: Qt.vector3d(0, -6, 36)
                    materials: [ PrincipledMaterial {
                        baseColor: "#00E5FF"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }
            }
        }

        // ==================== SENTINEL MODEL (Heavy Dark Titanium Combat Mech) ====================
        Node {
            id: sentinelNode
            visible: !root.isDrone
            position: Qt.vector3d(0, root.torsoBob, 0)

            // --- 0. Recessed Mechanical Neck Joint (#111317) ---
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.18, 0.16, 0.18)
                position: Qt.vector3d(0, 134, 0)
                materials: [ matDarkMechJoint ]
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.04, 0.16, 0.04)
                position: Qt.vector3d(-10, 134, 0)
                materials: [ matDarkMechJoint ]
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.04, 0.16, 0.04)
                position: Qt.vector3d(10, 134, 0)
                materials: [ matDarkMechJoint ]
            }

            // --- 1. Cybernetic Skull / Head ---
            Node {
                position: Qt.vector3d(0, 155, 0)

                // Armored Skull Faceplate (Heavy dark titanium alloy #2D3748)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.50, 0.48, 0.48)
                    materials: [ matSentinelHead ]
                }

                // Dark Recessed Visor Socket (#111317)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.44, 0.10, 0.08)
                    position: Qt.vector3d(0, 1, 23.5)
                    materials: [ matDarkMechJoint ]
                }

                // Narrow Menacing Glowing Red Optical Slit (#FF1E1E)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.42, 0.06, 0.08)
                    position: Qt.vector3d(0, 1, 25)
                    materials: [ PrincipledMaterial {
                        baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#FF0033" : "#FF1E1E"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }

                // Temple Hydraulic Armor Plates (Left & Right - Heavy dark titanium #2D3748)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.32, 0.35)
                    position: Qt.vector3d(-26, -2, 0)
                    materials: [ matSentinelArmor ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.08, 0.32, 0.35)
                    position: Qt.vector3d(26, -2, 0)
                    materials: [ matSentinelArmor ]
                }
            }

            // --- 2. Heavy Armored Torso & Recessed Reactor Core ---
            Node {
                position: Qt.vector3d(0, 105, 0)

                // Upper Chest Ballistic Carapace (Heavy dark titanium plates #2D3748)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.75, 0.52, 0.44)
                    position: Qt.vector3d(0, 8, 0)
                    materials: [ matSentinelArmor ]
                }

                // Recessed Reactor Core Housing Cavity (#111317)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.38, 0.38, 0.20)
                    position: Qt.vector3d(0, 8, 4)
                    materials: [ matDarkMechJoint ]
                }

                // Recessed Glowing Plasma Reactor Core (#FF1E1E)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.26, 0.12)
                    position: Qt.vector3d(0, 8, 14)
                    materials: [ PrincipledMaterial {
                        baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#FF0033" : "#FF2200"
                        lighting: PrincipledMaterial.NoLighting
                    }]
                }

                // Dark Armored Protective Ribs across Reactor Core (#111317)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.36, 0.035, 0.06)
                    position: Qt.vector3d(0, 15, 23)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.36, 0.035, 0.06)
                    position: Qt.vector3d(0, 8, 23)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.36, 0.035, 0.06)
                    position: Qt.vector3d(0, 1, 23)
                    materials: [ matDarkMechJoint ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.04, 0.32, 0.07)
                    position: Qt.vector3d(0, 8, 23.5)
                    materials: [ matDarkMechJoint ]
                }

                // Abdominal Spinal Vertebrae & Power Conduits
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.42, 0.32, 0.32)
                    position: Qt.vector3d(0, -28, 0)
                    materials: [ matSentinelCore ]
                }

                // Widened Heavy Shoulder Pauldrons (Heavier tactical silhouette)
                // Left Heavy Shoulder Pauldron (displays hazard markings from texture)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.38, 0.26, 0.50)
                    position: Qt.vector3d(-50, 26, 0)
                    eulerRotation: Qt.vector3d(0, 0, 18)
                    materials: [ matSentinelArmor ]
                }
                // Right Heavy Shoulder Pauldron (displays hazard markings from texture)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.38, 0.26, 0.50)
                    position: Qt.vector3d(50, 26, 0)
                    eulerRotation: Qt.vector3d(0, 0, -18)
                    materials: [ matSentinelArmor ]
                }
            }

            // --- Recessed Mechanical Shoulder Joints (#111317) ---
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.16, 0.16, 0.16)
                position: Qt.vector3d(-44, 114, 0)
                materials: [ matDarkMechJoint ]
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.16, 0.16, 0.16)
                position: Qt.vector3d(44, 114, 0)
                materials: [ matDarkMechJoint ]
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
                    materials: [ matSentinelArmor ]
                }

                // Recessed Mechanical Elbow Servo Joint (#111317)
                Model {
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.16, 0.12, 0.16)
                    position: Qt.vector3d(0, -38, 0)
                    materials: [ matDarkMechJoint ]
                }

                // Armored Forearm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.18, 0.38, 0.18)
                    position: Qt.vector3d(0, -56, 4)
                    eulerRotation: Qt.vector3d(-15, 0, 0)
                    materials: [ matSentinelArmor ]
                }

                // Tactical Combat Claw (Dark Gunmetal)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.14, 0.16, 0.20)
                    position: Qt.vector3d(0, -74, 8)
                    materials: [ matDarkMechJoint ]
                }
            }

            // --- 4. Right Arm with Heavy Gunmetal Assault Cannon ---
            Node {
                position: Qt.vector3d(48, 110, 0)
                eulerRotation: Qt.vector3d(-65 - (root.enemyObj && root.enemyObj.isShooting ? 12 : 0), -5, -8)

                // Upper Arm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.40, 0.20)
                    position: Qt.vector3d(0, -18, 0)
                    materials: [ matSentinelArmor ]
                }

                // Recessed Mechanical Elbow Servo Joint (#111317)
                Model {
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.16, 0.12, 0.16)
                    position: Qt.vector3d(0, -38, 0)
                    materials: [ matDarkMechJoint ]
                }

                // Armored Forearm
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.20, 0.38, 0.20)
                    position: Qt.vector3d(0, -56, 0)
                    materials: [ matSentinelArmor ]
                }

                // Heavy Gunmetal Assault Cannon Assembly
                Node {
                    position: Qt.vector3d(2, -64, 16)

                    // Cannon Receiver & Frame (Heavy dark gunmetal)
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.24, 0.30, 0.72)
                        position: Qt.vector3d(0, 0, 10)
                        materials: [ matSentinelGun ]
                    }
                    // Picatinny Tactical Top Rail
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.12, 0.06, 0.55)
                        position: Qt.vector3d(0, 16, 8)
                        materials: [ matDarkMechJoint ]
                    }
                    // Glowing Crimson Plasma Energy Coils (#FF1E1E)
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.14, 0.08, 0.30)
                        position: Qt.vector3d(0, 12, 6)
                        materials: [ PrincipledMaterial {
                            baseColor: (root.enemyObj && root.enemyObj.isAttacking) ? "#FF0033" : "#FF1E1E"
                            lighting: PrincipledMaterial.NoLighting
                        }]
                    }
                    // Heavy Heat-Dissipation Fluted Cannon Barrel
                    Model {
                        source: "#Cylinder"
                        eulerRotation: Qt.vector3d(90, 0, 0)
                        scale: Qt.vector3d(0.10, 0.45, 0.10)
                        position: Qt.vector3d(0, 0, 48)
                        materials: [ matDarkMechJoint ]
                    }
                    // Muzzle Shroud / Heavy Compensator
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.16, 0.16, 0.14)
                        position: Qt.vector3d(0, 0, 72)
                        materials: [ matSentinelGun ]
                    }
                    // Glowing Crimson Emissive Muzzle Accent (#FF1E1E)
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.12, 0.12, 0.03)
                        position: Qt.vector3d(0, 0, 79)
                        materials: [ PrincipledMaterial {
                            baseColor: "#FF1E1E"
                            lighting: PrincipledMaterial.NoLighting
                        }]
                    }
                    // High-Energy Muzzle Flash
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(0.24, 0.24, 0.24)
                        position: Qt.vector3d(0, 0, 88)
                        visible: root.enemyObj ? root.enemyObj.isShooting : false
                        materials: [ PrincipledMaterial {
                            baseColor: "#FFAA00"
                            lighting: PrincipledMaterial.NoLighting
                        }]
                    }
                }
            }

            // --- Recessed Mechanical Waist Joint & Hydraulic Actuators (#111317) ---
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.24, 0.16, 0.24)
                position: Qt.vector3d(0, 78, 0)
                materials: [ matDarkMechJoint ]
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.05, 0.16, 0.05)
                position: Qt.vector3d(-14, 78, 0)
                materials: [ matDarkMechJoint ]
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.05, 0.16, 0.05)
                position: Qt.vector3d(14, 78, 0)
                materials: [ matDarkMechJoint ]
            }

            // --- 5. Armored Pelvis & Bipedal Legs ---
            // Armored Pelvis (Heavy dark titanium)
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.58, 0.20, 0.36)
                position: Qt.vector3d(0, 62, 0)
                materials: [ matSentinelArmor ]
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
                    materials: [ matSentinelArmor ]
                }
                // Recessed Mechanical Knee Joint (#111317)
                Model {
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    position: Qt.vector3d(0, -32, 2)
                    materials: [ matDarkMechJoint ]
                }
                // Armored Shin & Calf Plate
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.22, 0.34, 0.22)
                    position: Qt.vector3d(0, -48, 0)
                    materials: [ matSentinelArmor ]
                }
                // Magnetic Heavy Combat Boot (Dark Gunmetal)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.12, 0.36)
                    position: Qt.vector3d(0, -66, 6)
                    materials: [ matDarkMechJoint ]
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
                    materials: [ matSentinelArmor ]
                }
                // Recessed Mechanical Knee Joint (#111317)
                Model {
                    source: "#Cylinder"
                    scale: Qt.vector3d(0.18, 0.10, 0.18)
                    position: Qt.vector3d(0, -32, 2)
                    materials: [ matDarkMechJoint ]
                }
                // Armored Shin & Calf Plate
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.22, 0.34, 0.22)
                    position: Qt.vector3d(0, -48, 0)
                    materials: [ matSentinelArmor ]
                }
                // Magnetic Heavy Combat Boot (Dark Gunmetal)
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.12, 0.36)
                    position: Qt.vector3d(0, -66, 6)
                    materials: [ matDarkMechJoint ]
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
