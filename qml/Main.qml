import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtMultimedia
import FPSLabGame

Window {
    id: root
    width: 1280
    height: 720
    visible: true
    title: qsTr("FPS Lab Game - Project VANGUARD")
    color: "#0c0e14"

    onActiveFocusItemChanged: {
        if (!inputHandler.activeFocus) {
            inputHandler.forceActiveFocus()
        }
    }

    // ==================== AUDIO MANAGER & SOUND EFFECTS ====================
    AudioManager {
        id: audioManager
    }

    AnimationManager {
        id: animationManager
    }

    function playSound(type) {
        if (!audioManager) return;
        if (type === "gunshot") {
            audioManager.playGunshot()
        } else if (type === "heavy_gunshot") {
            audioManager.playHeavyGunshot()
        } else if (type === "reload") {
            audioManager.playReload()
        } else if (type === "door") {
            audioManager.playDoor()
        } else if (type === "enemy_hit") {
            audioManager.playEnemyHit()
        } else if (type === "death") {
            audioManager.playDeath()
        } else if (type === "enemy_gunshot") {
            audioManager.playEnemyGunshot()
        } else if (type === "pickup") {
            audioManager.playPickup()
        } else if (type === "vent_explode") {
            audioManager.playVentExplosion()
        } else if (type === "level_clear") {
            audioManager.playLevelComplete()
        } else {
            audioManager.playSound(type)
        }
    }

    // ==================== CAMPAIGN & LEVEL MANAGER ====================
    LevelManager {
        id: levelManager
        onExitReached: function(nextLevel) {
            console.log("[Main] Exit tile reached. Advancing to Level:", nextLevel)
            playSound("level_clear")
            advanceToNextLevel()
        }
        onCampaignWon: {
            console.log("[Main] Campaign completed successfully!")
            gameManager.triggerWin()
        }
        onTrapTriggered: function(spawnPos, enemyType) {
            if (enemyManager.activeCount < enemyManager.maxActive) {
                if (enemyType === 1) {
                    enemyManager.spawnSentinel(spawnPos)
                } else {
                    enemyManager.spawnDrone(spawnPos)
                }
                root.hitNotificationText = "CROSSFIRE TRAP! AMBUSH SPAWNED BEHIND YOU!"
                root.hitNotificationColor = "#e74c3c"
                hitNotificationTimer.restart()
                playSound("enemy_hit")
            }
        }
    }

    // ==================== CORE GAME ENTITIES ====================
    GameManager {
        id: gameManager
        onGameStarted: root.startCampaign()
        onGameRestarted: root.startCampaign()
        onDifficultyChanged: root.applyWeaponDifficultyTuning()
        onGameStateChanged: {
            if (!isPlaying) {
                root.mouseLookActive = false
                audioManager.stopAmbient()
            } else {
                audioManager.playAmbient(levelManager.currentLevel)
            }
        }
    }

    GameWorld {
        id: gameWorld
        levelManager: levelManager
    }

    Connections {
        target: gameWorld.door
        function onDoorOpened() { playSound("door") }
        function onDoorClosed() { playSound("door") }
        function onDoorHit() { playSound("door") }
    }

    Player {
        id: player
        world: gameWorld
        onDied: {
            playSound("death")
            gameManager.triggerGameOver()
            root.mouseLookActive = false
        }
        onDamageTaken: function(amount) {
            animationManager.triggerDamageFlash()
        }
        onHealed: function(amount) {
            animationManager.triggerHealFlash()
        }
    }

    Sniper {
        id: sniperWeapon
        onFired: {
            playSound("gunshot")
            recoilAnim.restart()
            muzzleFlash.visible = true
            flashTimer.restart()
        }
        onReloaded: playSound("reload")
        onShotFired: function(hitPoint, hitType) {
            animationManager.spawnTracer(player.cameraPosition, hitPoint, 0)
            if (hitType === Sniper.EnemyHead || hitType === Sniper.EnemyBody) {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 1)
            } else if (hitType === Sniper.CoolingVent) {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 2)
            } else {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 0)
            }
        }
        onTargetHit: function(hitPoint, hitType) {
            playSound("enemy_hit")
            if (hitType === Sniper.EnemyHead) {
                root.hitNotificationText = "HEADSHOT! CRITICAL HIT"
                root.hitNotificationColor = "#e74c3c"
            } else {
                root.hitNotificationText = "BODY HIT (+40 DMG)"
                root.hitNotificationColor = "#f39c12"
            }
            hitNotificationTimer.restart()
        }
        onEnemyHit: function(enemy, isHeadshot, damage) {
            if (!enemy) return
            var typeStr = (enemy.enemyType === Enemy.Drone) ? "DRONE" : "SENTINEL"
            if (enemy.isDead) {
                var score = enemy.scoreValue
                gameManager.addScore(score)
                if (levelManager.currentLevel === 3) {
                    root.hitNotificationText = "DRONE ELIMINATED (+" + score + " PTS) [0/" + enemy.maxHealth + " HP] — TARGET THE 4 VENTS!"
                } else {
                    root.hitNotificationText = typeStr + " ELIMINATED (+" + score + " PTS) [0/" + enemy.maxHealth + " HP]"
                }
                root.hitNotificationColor = "#2ecc71"
            } else {
                var hitLabel = isHeadshot ? "HEADSHOT!" : "BODY HIT"
                root.hitNotificationText = typeStr + " " + hitLabel + " (-" + damage + " HP) [" + enemy.health + "/" + enemy.maxHealth + " HP]"
                root.hitNotificationColor = isHeadshot ? "#e74c3c" : "#f39c12"
            }
            hitNotificationTimer.restart()
        }
        onVentHit: function(vent, damage) {
            playSound("enemy_hit")
            root.hitNotificationText = "COOLING VENT #" + (vent.ventIndex + 1) + " HIT (-" + damage + " HP) [" + vent.health + "/" + vent.maxHealth + " HP]"
            root.hitNotificationColor = "#00e5ff"
            hitNotificationTimer.restart()
        }
    }

    HeavyWeapon {
        id: heavyWeapon
        onFired: {
            playSound("heavy_gunshot")
            heavyRecoilAnim.restart()
            heavyMuzzleFlash.visible = true
            heavyFlashTimer.restart()
        }
        onReloaded: playSound("reload")
        onShotFired: function(hitPoint, hitType) {
            animationManager.spawnTracer(player.cameraPosition, hitPoint, 1)
            if (hitType === HeavyWeapon.EnemyHead || hitType === HeavyWeapon.EnemyBody) {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 1)
            } else if (hitType === HeavyWeapon.CoolingVent) {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 2)
            } else {
                animationManager.spawnSparks(hitPoint, Qt.vector3d(0, 1, 0), 0)
            }
        }
        onTargetHit: function(hitPoint, hitType) {
            playSound("enemy_hit")
            if (hitType === HeavyWeapon.EnemyHead) {
                root.hitNotificationText = "PLASMA HEADSHOT! (+50 DMG)"
                root.hitNotificationColor = "#00e5ff"
            } else {
                root.hitNotificationText = "PLASMA HIT (+25 DMG)"
                root.hitNotificationColor = "#3498db"
            }
            hitNotificationTimer.restart()
        }
        onEnemyHit: function(enemy, isHeadshot, damage) {
            if (!enemy) return
            var typeStr = (enemy.enemyType === Enemy.Drone) ? "DRONE" : "SENTINEL"
            if (enemy.isDead) {
                var score = enemy.scoreValue
                gameManager.addScore(score)
                if (levelManager.currentLevel === 3) {
                    root.hitNotificationText = "DRONE ELIMINATED (+" + score + " PTS) [0/" + enemy.maxHealth + " HP] — TARGET THE 4 VENTS!"
                } else {
                    root.hitNotificationText = typeStr + " ELIMINATED (+" + score + " PTS) [0/" + enemy.maxHealth + " HP]"
                }
                root.hitNotificationColor = "#2ecc71"
            } else {
                var hitLabel = isHeadshot ? "PLASMA HEADSHOT!" : "PLASMA HIT"
                root.hitNotificationText = typeStr + " " + hitLabel + " (-" + damage + " HP) [" + enemy.health + "/" + enemy.maxHealth + " HP]"
                root.hitNotificationColor = "#00e5ff"
            }
            hitNotificationTimer.restart()
        }
        onVentHit: function(vent, damage) {
            playSound("enemy_hit")
            root.hitNotificationText = "PLASMA VENT #" + (vent.ventIndex + 1) + " HIT (-" + damage + " HP) [" + vent.health + "/" + vent.maxHealth + " HP]"
            root.hitNotificationColor = "#00e5ff"
            hitNotificationTimer.restart()
        }
    }

    readonly property var activeWeapon: (player.currentWeaponIndex === 0) ? sniperWeapon : heavyWeapon

    // ==================== BOSS ARENA & COOLING VENTS (Stage V7) ====================
    BossArena {
        id: bossArena
        onBossDefeated: {
            console.log("[Main] All 4 Cooling Vents destroyed! VANGUARD core collapsed.")
            audioManager.stopAmbient()
            enemyManager.clearAll()
            gameManager.addScore(1000)
            root.hitNotificationText = "CRITICAL OVERLOAD: VANGUARD DESTROYED! (+1000 PTS)"
            root.hitNotificationColor = "#2ecc71"
            hitNotificationTimer.restart()
            playSound("enemy_hit")

            levelManager.loadLevel(4)
            gameManager.showStory()
        }
        onVentDestroyed: function(index) {
            gameManager.addScore(250)
            root.hitNotificationText = "COOLING VENT " + (index + 1) + " DESTROYED! (" + (4 - bossArena.activeVentsCount) + "/4) [+250 PTS]"
            root.hitNotificationColor = "#e74c3c"
            hitNotificationTimer.restart()
            playSound("vent_explode")
            var ventObj = bossArena.ventAt(index)
            if (ventObj) {
                animationManager.spawnVentBurst(ventObj.position)
            }
        }
    }

    // ==================== ENEMY MANAGER (Stage V4) ====================
    EnemyManager {
        id: enemyManager
        onEnemyShotFired: {
            playSound("enemy_gunshot")
        }
        onEnemyBulletFired: function(from, targetPos, didHit) {
            animationManager.spawnTracer(from, targetPos, 2)
        }
        Component.onCompleted: {
            setWorld(gameWorld)
        }
    }

    // ==================== LEVEL 1 VOXEL PICKUPS ====================
    Pickup {
        id: pickupFood
        position: Qt.vector3d(250, 25, 2650) // Row 26, Col 2 (South alcove)
        itemType: Inventory.FoodPack
    }

    Pickup {
        id: pickupBandage
        position: Qt.vector3d(550, 25, 2350) // Row 23, Col 5 (Southwest loop)
        itemType: Inventory.Bandage
    }

    Pickup {
        id: pickupMedkit
        position: Qt.vector3d(750, 25, 1750) // Row 17, Col 7 (West storage room)
        itemType: Inventory.Medkit
    }

    Pickup {
        id: pickupExtraBandage
        position: Qt.vector3d(2550, 25, 1050) // Row 10, Col 25 (Inside Loading Bay)
        itemType: Inventory.Bandage
    }

    Pickup {
        id: pickupExtraFood
        position: Qt.vector3d(2550, 25, 350) // Row 3, Col 25 (Before Elevator)
        itemType: Inventory.FoodPack
    }

    Pickup {
        id: pickupExtraMedkit
        position: Qt.vector3d(1450, 25, 2550) // Row 25, Col 14 (South corridor alcove)
        itemType: Inventory.Medkit
    }

    // ==================== LEVEL FLOW & STATS PERSISTENCE ====================
    function applyWeaponDifficultyTuning() {
        if (levelManager.currentLevel === 3) {
            if (gameManager.difficultyName === "EASY") {
                sniperWeapon.setMaxAmmo(10)
                sniperWeapon.setAmmo(10)
                sniperWeapon.addReserveAmmo(20)
            } else {
                sniperWeapon.setMaxAmmo(5)
                sniperWeapon.setAmmo(5)
            }
        } else {
            sniperWeapon.setMaxAmmo(5)
        }
    }

    function setupLevel(lvl, isTransition) {
        console.log("[Main] setupLevel called for level:", lvl, "Difficulty:", gameManager.difficultyName, "isTransition:", isTransition)

        // Save persistent player stats across level transitions
        var savedHealth = 100
        var savedHasHeavy = false
        var savedCurrentWeapon = 0
        var savedSniperAmmo = 5
        var savedSniperReserve = 20
        var savedHeavyAmmo = 30
        var savedHeavyReserve = 90
        var savedFood = 0
        var savedBandages = 0
        var savedMedkits = 0

        if (isTransition) {
            savedHealth = (player.healthSystem) ? player.healthSystem.health : player.health
            savedHasHeavy = player.hasHeavyWeapon
            savedCurrentWeapon = player.currentWeaponIndex
            savedSniperAmmo = sniperWeapon.ammo
            savedSniperReserve = sniperWeapon.reserveAmmo
            savedHeavyAmmo = heavyWeapon.ammo
            savedHeavyReserve = heavyWeapon.reserveAmmo
            if (player.inventory) {
                savedFood = player.inventory.foodPacks
                savedBandages = player.inventory.bandages
                savedMedkits = player.inventory.medkits
            }
        }

        levelManager.loadLevel(lvl)
        animationManager.clearAll()
        bossArena.reset()
        player.reset()
        player.position = levelManager.spawnPosition
        player.setPosition(levelManager.spawnPosition)
        player.setRotation(0.0, 0.0)
        enemyManager.clearAll()
        gameWorld.resetWorld()

        if (isTransition) {
            // Restore persistent player stats
            if (player.healthSystem) {
                player.healthSystem.health = Math.max(1, savedHealth)
            }
            player.hasHeavyWeapon = savedHasHeavy
            player.setHasHeavyWeapon(savedHasHeavy)
            player.currentWeaponIndex = savedCurrentWeapon
            player.setCurrentWeaponIndex(savedCurrentWeapon)
            if (player.inventory) {
                if (savedFood > 0) player.inventory.addItem(0, savedFood)
                if (savedBandages > 0) player.inventory.addItem(1, savedBandages)
                if (savedMedkits > 0) player.inventory.addItem(2, savedMedkits)
            }
            sniperWeapon.setAmmo(savedSniperAmmo)
            sniperWeapon.setReserveAmmo(savedSniperReserve)
            if (savedHasHeavy) {
                heavyWeapon.setAmmo(savedHeavyAmmo)
                heavyWeapon.setReserveAmmo(savedHeavyReserve)
            }
        } else {
            // Fresh start / Restart: Weapon ammo & difficulty tuning
            if (lvl === 3) {
                if (gameManager.difficultyName === "EASY") {
                    sniperWeapon.setMaxAmmo(10)
                    sniperWeapon.setAmmo(10)
                    sniperWeapon.resetAmmo()
                    sniperWeapon.addReserveAmmo(20)
                } else {
                    sniperWeapon.setMaxAmmo(5)
                    sniperWeapon.setAmmo(5)
                    sniperWeapon.resetAmmo()
                }
                player.hasHeavyWeapon = true
                player.setHasHeavyWeapon(true)
                heavyWeapon.resetAmmo()
            } else {
                sniperWeapon.setMaxAmmo(5)
                sniperWeapon.setAmmo(5)
                sniperWeapon.resetAmmo()
                player.hasHeavyWeapon = false
                player.setHasHeavyWeapon(false)
            }
        }

        // Medical Pickups placement for all 3 levels
        if (lvl === 1) {
            pickupFood.position = Qt.vector3d(250, 25, 2650)
            pickupBandage.position = Qt.vector3d(550, 25, 2350)
            pickupMedkit.position = Qt.vector3d(750, 25, 1750)
            pickupExtraBandage.position = Qt.vector3d(2550, 25, 1050)
            pickupExtraFood.position = Qt.vector3d(2550, 25, 350)
            pickupExtraMedkit.position = Qt.vector3d(1450, 25, 2550)
        } else if (lvl === 2) {
            pickupBandage.position = Qt.vector3d(450, 25, 6150)
            pickupMedkit.position = Qt.vector3d(950, 25, 6150)
            pickupExtraBandage.position = Qt.vector3d(450, 25, 3850)
            pickupExtraMedkit.position = Qt.vector3d(2650, 25, 2850)
            pickupFood.position = Qt.vector3d(3250, 25, 3450)
            pickupExtraFood.position = Qt.vector3d(4450, 25, 5550)
        } else if (lvl === 3) {
            pickupBandage.position = Qt.vector3d(1850, 25, 3450)
            pickupMedkit.position = Qt.vector3d(2250, 25, 3450)
            pickupFood.position = Qt.vector3d(2050, 25, 3650)
            pickupExtraBandage.position = Qt.vector3d(450, 25, 2050)
            pickupExtraMedkit.position = Qt.vector3d(3650, 25, 2050)
            pickupExtraFood.position = Qt.vector3d(2050, 25, 450)
        }
        pickupFood.reset()
        pickupBandage.reset()
        pickupMedkit.reset()
        pickupExtraBandage.reset()
        pickupExtraFood.reset()
        pickupExtraMedkit.reset()

        root.mouseLookActive = false
        root.hitNotificationText = "LEVEL " + lvl + ": " + levelManager.currentLevelName
        root.hitNotificationColor = (lvl === 3) ? "#00e5ff" : "#2ecc71"
        hitNotificationTimer.restart()

        inputHandler.moveForward = false
        inputHandler.moveBackward = false
        inputHandler.moveLeft = false
        inputHandler.moveRight = false
        inputHandler.syncMovement()

        if (gameManager.isPlaying) {
            audioManager.playAmbient(lvl)
        } else {
            audioManager.stopAmbient()
        }
        root.enemySpawnCountdown = 2.0
        root.enemiesSpawnedForLevel = false
    }

    function startCampaign() {
        var startLvl = (mainMenu.selectedLevel > 0) ? mainMenu.selectedLevel : 1
        setupLevel(startLvl)
    }

    function spawnEnemiesForLevel() {
        var currentLvl = levelManager.currentLevel
        if (currentLvl === 1) {
            // Level 1: Spawn corridor patrol Drones
            var count = levelManager.corridorDroneSpawnCount()
            for (var i = 0; i < count; ++i) {
                var spawn = levelManager.corridorDroneSpawn(i)
                enemyManager.spawnDrone(spawn)
            }
            console.log("[Main] Level 1 Corridor Drones spawned. Active:", enemyManager.activeCount)
        } else if (currentLvl === 2) {
            // Level 2: Spawn Sentinels at hallways & vaults
            var sCount = levelManager.sentinelSpawnCount()
            for (var s = 0; s < sCount; ++s) {
                enemyManager.spawnSentinel(levelManager.sentinelSpawn(s))
            }
            // Level 2: Spawn patrol Drones across corridors
            var dCount = levelManager.droneSpawnCount()
            for (var d = 0; d < dCount; ++d) {
                enemyManager.spawnDrone(levelManager.droneSpawn(d))
            }
            console.log("[Main] Level 2 Enemies spawned - Sentinels:", sCount, "Drones:", dCount, "Active:", enemyManager.activeCount)
        } else if (currentLvl === 3) {
            // Level 3: Spawn initial arena guardian Drones from perimeter gates (away from player south spawn)
            enemyManager.spawnDrone(Qt.vector3d(1950, 0, 250))
            enemyManager.spawnDrone(Qt.vector3d(3750, 0, 1950))
            enemyManager.spawnDrone(Qt.vector3d(3250, 0, 650))
            enemyManager.spawnDrone(Qt.vector3d(250, 0, 1950))
            console.log("[Main] Level 3 Logic Core initialized. Active Drones:", enemyManager.activeCount)
        } else {
            // Test level fallback
            var blockSize = levelManager.blockSize
            var droneX = (8 + 0.5) * blockSize
            var droneZ = (5 + 0.5) * blockSize
            enemyManager.spawnDrone(Qt.vector3d(droneX, 0, droneZ))

            var sentinelX = (7 + 0.5) * blockSize
            var sentinelZ = (7 + 0.5) * blockSize
            enemyManager.spawnSentinel(Qt.vector3d(sentinelX, 0, sentinelZ))
            console.log("[Main] Test enemies spawned. Active:", enemyManager.activeCount)
        }
    }

    function advanceToNextLevel() {
        var nextLvl = levelManager.currentLevel + 1
        if (nextLvl > 3) {
            gameManager.triggerWin()
            return
        }
        setupLevel(nextLvl, true)
        gameManager.showStory()
    }

    property bool mouseLookActive: false
    property string hitNotificationText: ""
    property color hitNotificationColor: "#ffffff"
    property real enemySpawnCountdown: 2.0
    property bool enemiesSpawnedForLevel: false

    Timer {
        id: flashTimer
        interval: 60
        onTriggered: muzzleFlash.visible = false
    }

    Timer {
        id: heavyFlashTimer
        interval: 40
        onTriggered: heavyMuzzleFlash.visible = false
    }

    Timer {
        id: hitNotificationTimer
        interval: 1800
        onTriggered: root.hitNotificationText = ""
    }

    property int currentFps: 60
    property real fpsAccumTime: 0
    property int fpsFrameCount: 0
    property real frameCameraYaw: 0.0

    // ==================== HALLWAY SHADER & FLASHLIGHT CONTROLS ====================
    property bool flashlightActive: true
    property bool hallwayDarknessActive: true
    property real hallwayDarknessLevel: 0.18

    // ==================== GAME LOOP ====================
    FrameAnimation {
        id: gameLoop
        running: gameManager.isPlaying
        onTriggered: {
            root.frameCameraYaw = mainCamera.eulerRotation.y

            player.update(frameTime)
            sniperWeapon.update(frameTime)
            heavyWeapon.update(frameTime)
            gameWorld.door.update(frameTime)
            animationManager.update(frameTime)

            // Real-time FPS metric
            root.fpsFrameCount++
            root.fpsAccumTime += frameTime
            if (root.fpsAccumTime >= 0.5) {
                root.currentFps = Math.max(1, Math.round(root.fpsFrameCount / root.fpsAccumTime))
                root.fpsFrameCount = 0
                root.fpsAccumTime = 0
            }

            // Delayed enemy spawning: Spawns enemies 2.0 seconds after entering active gameplay
            if (!root.enemiesSpawnedForLevel && root.enemySpawnCountdown > 0) {
                root.enemySpawnCountdown -= frameTime
                if (root.enemySpawnCountdown <= 0) {
                    root.enemySpawnCountdown = 0
                    root.enemiesSpawnedForLevel = true
                    root.spawnEnemiesForLevel()
                    root.hitNotificationText = "ALERT: ENEMY PATROLS DETECTED!"
                    root.hitNotificationColor = "#e67e22"
                    hitNotificationTimer.restart()
                    playSound("enemy_hit")
                }
            }

            // Update ALL enemies via EnemyManager
            enemyManager.updateAll(frameTime, player.position, player, gameManager)

            // Update Boss Arena (Level 3 spawner and vent status)
            bossArena.update(frameTime, enemyManager, levelManager)

            // Check exit tile reach every frame
            levelManager.checkExitReached(player.position)

            // Check trigger traps every frame (Stage V6 crossfire ambush)
            levelManager.checkTriggerTrap(player.position, player.yaw)

            pickupFood.update(frameTime)
            pickupBandage.update(frameTime)
            pickupMedkit.update(frameTime)
            pickupExtraBandage.update(frameTime)
            pickupExtraFood.update(frameTime)
            pickupExtraMedkit.update(frameTime)

            // Health & Item Pickups Collection
            if (!pickupFood.isCollected && pickupFood.checkCollection(player.position)) {
                player.inventory.addItem(pickupFood.itemType, 1)
                root.hitNotificationText = "COLLECTED FOOD PACK (+20 HP) [PRESS 1]"
                root.hitNotificationColor = "#2ecc71"
                hitNotificationTimer.restart()
                playSound("pickup")
            }
            if (!pickupBandage.isCollected && pickupBandage.checkCollection(player.position)) {
                player.inventory.addItem(pickupBandage.itemType, 1)
                root.hitNotificationText = "COLLECTED BANDAGE (+30 HP) [PRESS 2]"
                root.hitNotificationColor = "#3498db"
                hitNotificationTimer.restart()
                playSound("pickup")
            }
            if (!pickupMedkit.isCollected && pickupMedkit.checkCollection(player.position)) {
                player.inventory.addItem(pickupMedkit.itemType, 1)
                root.hitNotificationText = "COLLECTED MEDKIT (+50 HP) [PRESS 3]"
                root.hitNotificationColor = "#e74c3c"
                hitNotificationTimer.restart()
                playSound("pickup")
            }
            if (!pickupExtraBandage.isCollected && pickupExtraBandage.checkCollection(player.position)) {
                player.inventory.addItem(pickupExtraBandage.itemType, 1)
                root.hitNotificationText = "COLLECTED BANDAGE (+30 HP) [PRESS 2]"
                root.hitNotificationColor = "#3498db"
                hitNotificationTimer.restart()
                playSound("pickup")
            }
            if (!pickupExtraFood.isCollected && pickupExtraFood.checkCollection(player.position)) {
                player.inventory.addItem(pickupExtraFood.itemType, 1)
                root.hitNotificationText = "COLLECTED FOOD PACK (+20 HP) [PRESS 1]"
                root.hitNotificationColor = "#2ecc71"
                hitNotificationTimer.restart()
                playSound("pickup")
            }
            if (!pickupExtraMedkit.isCollected && pickupExtraMedkit.checkCollection(player.position)) {
                player.inventory.addItem(pickupExtraMedkit.itemType, 1)
                root.hitNotificationText = "COLLECTED MEDKIT (+50 HP) [PRESS 3]"
                root.hitNotificationColor = "#e74c3c"
                hitNotificationTimer.restart()
                playSound("pickup")
            }

            // Tile 7: Heavy Weapon (Plasma Repeater) Collection
            if (levelManager.consumeHeavyWeaponTile(player.position.x, player.position.z)) {
                player.giveHeavyWeapon()
                root.hitNotificationText = "ACQUIRED: PLASMA REPEATER! [PRESS Q TO SWITCH]"
                root.hitNotificationColor = "#00e5ff"
                hitNotificationTimer.restart()
                playSound("pickup")
            }

            // Tile 5: Ammo Pickups Collection
            if (levelManager.consumeAmmoTile(player.position.x, player.position.z)) {
                var sniperGain = (levelManager.currentLevel === 3 && gameManager.difficultyName === "EASY") ? 10 : 5
                sniperWeapon.addReserveAmmo(sniperGain)
                if (player.hasHeavyWeapon) {
                    heavyWeapon.addReserveAmmo(30)
                    root.hitNotificationText = "COLLECTED AMMO CACHE (+" + sniperGain + " SNIPER, +30 PLASMA)"
                } else {
                    root.hitNotificationText = "COLLECTED AMMO CACHE (+" + sniperGain + " SNIPER ROUNDS)"
                }
                root.hitNotificationColor = "#f1c40f"
                hitNotificationTimer.restart()
                playSound("pickup")
            }

            // Level 1 Loading Bay Encounter Trigger
            if (levelManager.isInLoadingBay(player.position.x, player.position.z)) {
                if (levelManager.triggerLoadingBay()) {
                    root.hitNotificationText = "ALERT: LOADING BAY BREACHED! ENEMY DRONE WAVE INCOMING!"
                    root.hitNotificationColor = "#e74c3c"
                    hitNotificationTimer.restart()
                    var lbCount = levelManager.loadingBayDroneSpawnCount()
                    for (var j = 0; j < lbCount; ++j) {
                        enemyManager.spawnDrone(levelManager.loadingBayDroneSpawn(j))
                    }
                }
            }
        }
    }

    // ==================== 3D SCENE ====================
    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#080a0e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.NoAA
            effects: root.hallwayDarknessActive ? [ darkHallwayEffect ] : []
        }

        // ==================== ATMOSPHERIC DARK HALLWAY POST-PROCESSING SHADER ====================
        Effect {
            id: darkHallwayEffect

            property real uDarkness: (levelManager && levelManager.currentLevel === 3) ? 0.08 : (root.hallwayDarknessActive ? root.hallwayDarknessLevel : 0.0)
            property real uVignetteStrength: (levelManager && levelManager.currentLevel === 3) ? 0.15 : 0.28
            property real uVignetteRadius: 0.95
            property real uVignetteSmoothness: 0.55
            property real uContrast: (levelManager && levelManager.currentLevel === 3) ? 1.02 : 1.05
            property real uFlashlightOn: root.flashlightActive ? 1.0 : 0.0
            property real uFlashlightRadius: 0.65
            property real uFlashlightIntensity: 0.35
            property real uScanlines: 0.10

            Shader {
                id: darkVert
                stage: Shader.Vertex
                shader: "dark_hallway.vert"
            }
            Shader {
                id: darkFrag
                stage: Shader.Fragment
                shader: "dark_hallway.frag"
            }
            passes: Pass {
                shaders: [ darkVert, darkFrag ]
            }
        }

        PerspectiveCamera {
            id: mainCamera
            position: player.cameraPosition
            eulerRotation: player.cameraRotation
            fieldOfView: root.activeWeapon.currentFov
            clipNear: 5
            clipFar: 5000

            // ==================== TACTICAL FLASHLIGHT ON CAMERA ====================
            SpotLight {
                id: playerFlashlight
                position: Qt.vector3d(0, 0, 0)
                eulerRotation: Qt.vector3d(0, 0, 0)
                color: "#e8f4fc"
                brightness: 9.0
                coneAngle: 55
                innerConeAngle: 30
                visible: root.flashlightActive
                castsShadow: false
            }

            PointLight {
                id: playerFlashlightNear
                position: Qt.vector3d(0, 0, -30)
                color: "#d0e8fc"
                brightness: 2.2
                visible: root.flashlightActive
            }

            // 1. 3D Voxel AK-47 Style Rifle (Sniper Weapon) in player hands
            Node {
                id: weaponHolder
                position: Qt.vector3d(18, -14, -38)
                eulerRotation: Qt.vector3d(0, 180, 0)
                visible: player.currentWeaponIndex === 0 && !sniperWeapon.isAiming

                SequentialAnimation {
                    id: recoilAnim
                    NumberAnimation { target: weaponHolder; property: "position.z"; to: -28; duration: 60; easing.type: Easing.OutQuad }
                    NumberAnimation { target: weaponHolder; property: "position.z"; to: -38; duration: 250; easing.type: Easing.OutCubic }
                }

                SequentialAnimation {
                    id: reloadAnim
                    running: sniperWeapon.isReloading
                    loops: Animation.Infinite
                    NumberAnimation { target: weaponHolder; property: "eulerRotation.x"; to: 15; duration: 350; easing.type: Easing.OutQuad }
                    NumberAnimation { target: weaponHolder; property: "position.y"; to: -20; duration: 350; easing.type: Easing.OutQuad }
                    NumberAnimation { target: weaponHolder; property: "eulerRotation.x"; to: 0; duration: 350; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: weaponHolder; property: "position.y"; to: -14; duration: 350; easing.type: Easing.OutQuad }
                }

                // --- AK-47 RECEIVER (Stamped Gunmetal Steel) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.045, 0.07, 0.28)
                    materials: [ PrincipledMaterial { baseColor: "#25282f"; metalness: 0.75; roughness: 0.45 } ]
                }

                // --- AK-47 DUST COVER (Top Receiver) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.042, 0.025, 0.25)
                    position: Qt.vector3d(0, 4.2, -1.0)
                    materials: [ PrincipledMaterial { baseColor: "#1a1d22"; metalness: 0.8; roughness: 0.35 } ]
                }

                // --- AK-47 WOODEN SHOULDER STOCK ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.038, 0.08, 0.25)
                    position: Qt.vector3d(0, -2.5, -24)
                    eulerRotation: Qt.vector3d(-6, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#793c18"; roughness: 0.65 } ]
                }
                // Steel Buttplate
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.040, 0.088, 0.025)
                    position: Qt.vector3d(0, -3.8, -36)
                    eulerRotation: Qt.vector3d(-6, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#141619"; metalness: 0.85; roughness: 0.4 } ]
                }

                // --- AK-47 WOODEN PISTOL GRIP ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.035, 0.09, 0.045)
                    position: Qt.vector3d(0, -6.8, -7)
                    eulerRotation: Qt.vector3d(-18, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#6c3515"; roughness: 0.65 } ]
                }

                // --- AK-47 CURVED BANANA MAGAZINE (Upper Section) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.036, 0.10, 0.07)
                    position: Qt.vector3d(0, -6.5, 4)
                    eulerRotation: Qt.vector3d(10, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#1b1d21"; metalness: 0.7; roughness: 0.5 } ]
                }
                // --- AK-47 CURVED BANANA MAGAZINE (Lower Curved Section) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.034, 0.09, 0.065)
                    position: Qt.vector3d(0, -13.2, 7.5)
                    eulerRotation: Qt.vector3d(22, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#17191d"; metalness: 0.7; roughness: 0.5 } ]
                }

                // --- AK-47 WOODEN LOWER HANDGUARD ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.046, 0.048, 0.18)
                    position: Qt.vector3d(0, -0.6, 21)
                    materials: [ PrincipledMaterial { baseColor: "#7e401c"; roughness: 0.65 } ]
                }

                // --- AK-47 WOODEN UPPER GAS TUBE HANDGUARD ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.040, 0.032, 0.16)
                    position: Qt.vector3d(0, 3.2, 20)
                    materials: [ PrincipledMaterial { baseColor: "#723918"; roughness: 0.65 } ]
                }

                // --- AK-47 GAS BLOCK ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.030, 0.052, 0.04)
                    position: Qt.vector3d(0, 2.6, 31)
                    materials: [ PrincipledMaterial { baseColor: "#22252a"; metalness: 0.8; roughness: 0.4 } ]
                }

                // --- AK-47 LONG STEEL BARREL ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.022, 0.022, 0.42)
                    position: Qt.vector3d(0, 0.6, 35)
                    materials: [ PrincipledMaterial { baseColor: "#16181b"; metalness: 0.9; roughness: 0.3 } ]
                }

                // --- AK-47 FRONT SIGHT TOWER & POST ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.026, 0.062, 0.035)
                    position: Qt.vector3d(0, 3.4, 49)
                    materials: [ PrincipledMaterial { baseColor: "#1a1c20"; metalness: 0.8; roughness: 0.4 } ]
                }

                // --- AK-47 SLANTED COMPENSATOR / MUZZLE BRAKE ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.026, 0.026, 0.05)
                    position: Qt.vector3d(0, 0.6, 55)
                    materials: [ PrincipledMaterial { baseColor: "#121417"; metalness: 0.8; roughness: 0.4 } ]
                }

                // --- AK-47 BOLT CARRIER / CHARGING HANDLE ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.03, 0.018, 0.028)
                    position: Qt.vector3d(-2.8, 1.2, 2.0)
                    materials: [ PrincipledMaterial { baseColor: "#9aa0a6"; metalness: 0.95; roughness: 0.2 } ]
                }

                // --- TACTICAL SNIPER SCOPE SYSTEM ---
                // Scope Mount
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.024, 0.028, 0.16)
                    position: Qt.vector3d(0, 5.8, -2)
                    materials: [ PrincipledMaterial { baseColor: "#181a1d"; metalness: 0.8 } ]
                }
                // Main Scope Tube
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.034, 0.034, 0.28)
                    position: Qt.vector3d(0, 8.2, -1)
                    materials: [ PrincipledMaterial { baseColor: "#121316"; metalness: 0.85; roughness: 0.3 } ]
                }
                // Front Objective Bell
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.044, 0.044, 0.06)
                    position: Qt.vector3d(0, 8.2, 12)
                    materials: [ PrincipledMaterial { baseColor: "#181a1d"; metalness: 0.8 } ]
                }
                // Coated Optical Blue Lens
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.036, 0.036, 0.01)
                    position: Qt.vector3d(0, 8.2, 15)
                    materials: [ PrincipledMaterial { baseColor: "#00b0ff"; roughness: 0.1 } ]
                }

                // Muzzle Flash Effect
                Model {
                    id: muzzleFlash
                    source: "#Cube"
                    scale: Qt.vector3d(0.12, 0.12, 0.12)
                    position: Qt.vector3d(0, 0.6, 58)
                    visible: false
                    materials: [ PrincipledMaterial { baseColor: "#ffcc00"; lighting: PrincipledMaterial.NoLighting } ]
                }
                PointLight {
                    id: sniperFlashLight
                    position: Qt.vector3d(0, 0.6, 58)
                    color: "#ffcc00"
                    brightness: 8.0
                    visible: muzzleFlash.visible
                }
            }

            // 2. 3D Voxel Heavy Sci-Fi Plasma Cannon / Repeater in player hands
            Node {
                id: heavyWeaponHolder
                position: Qt.vector3d(18, -14, -36)
                eulerRotation: Qt.vector3d(0, 180, 0)
                visible: player.currentWeaponIndex === 1 && !heavyWeapon.isAiming

                SequentialAnimation {
                    id: heavyRecoilAnim
                    NumberAnimation { target: heavyWeaponHolder; property: "position.z"; to: -30; duration: 40; easing.type: Easing.OutQuad }
                    NumberAnimation { target: heavyWeaponHolder; property: "position.z"; to: -36; duration: 110; easing.type: Easing.OutQuad }
                }

                SequentialAnimation {
                    id: heavyReloadAnim
                    running: heavyWeapon.isReloading
                    loops: Animation.Infinite
                    NumberAnimation { target: heavyWeaponHolder; property: "eulerRotation.z"; to: -15; duration: 300; easing.type: Easing.OutQuad }
                    NumberAnimation { target: heavyWeaponHolder; property: "position.y"; to: -20; duration: 300; easing.type: Easing.OutQuad }
                    NumberAnimation { target: heavyWeaponHolder; property: "eulerRotation.z"; to: 0; duration: 300; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: heavyWeaponHolder; property: "position.y"; to: -14; duration: 300; easing.type: Easing.OutQuad }
                }

                // --- MAIN HEAVY CHASSIS (Carbon-Titanium Composite) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.065, 0.09, 0.34)
                    materials: [ PrincipledMaterial { baseColor: "#151921"; roughness: 0.35; metalness: 0.85 } ]
                }

                // --- UPPER RADIATOR & HEAT SHROUD ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.055, 0.035, 0.28)
                    position: Qt.vector3d(0, 5.2, -1)
                    materials: [ PrincipledMaterial { baseColor: "#0f1218"; roughness: 0.5 } ]
                }

                // --- REINFORCED SKELETAL STOCK ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.055, 0.085, 0.22)
                    position: Qt.vector3d(0, -2.0, -22)
                    materials: [ PrincipledMaterial { baseColor: "#11141a"; roughness: 0.6 } ]
                }

                // --- TACTICAL COMBAT GRIP ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.038, 0.095, 0.05)
                    position: Qt.vector3d(0, -6.8, -7)
                    eulerRotation: Qt.vector3d(-16, 0, 0)
                    materials: [ PrincipledMaterial { baseColor: "#0a0c10"; roughness: 0.8 } ]
                }

                // --- SUPERCHARGED GLOWING PLASMA BATTERY CORE ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.048, 0.052, 0.16)
                    position: Qt.vector3d(0, -4.5, 7)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                // Magnetic Cell Containment Brackets
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.056, 0.060, 0.025)
                    position: Qt.vector3d(0, -4.5, 3)
                    materials: [ PrincipledMaterial { baseColor: "#222731"; metalness: 0.8 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.056, 0.060, 0.025)
                    position: Qt.vector3d(0, -4.5, 11)
                    materials: [ PrincipledMaterial { baseColor: "#222731"; metalness: 0.8 } ]
                }

                // --- TWIN PLASMA ACCELERATOR RAILS (Top & Bottom) ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.030, 0.030, 0.38)
                    position: Qt.vector3d(0, 2.2, 28)
                    materials: [ PrincipledMaterial { baseColor: "#1a222d"; roughness: 0.3; metalness: 0.9 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.030, 0.030, 0.38)
                    position: Qt.vector3d(0, -2.0, 28)
                    materials: [ PrincipledMaterial { baseColor: "#1a222d"; roughness: 0.3; metalness: 0.9 } ]
                }

                // --- 3x GLOWING MAGNETIC INDUCTION COILS ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.058, 0.064, 0.025)
                    position: Qt.vector3d(0, 0.1, 19)
                    materials: [ PrincipledMaterial { baseColor: "#00f0ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.055, 0.060, 0.025)
                    position: Qt.vector3d(0, 0.1, 29)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.052, 0.056, 0.025)
                    position: Qt.vector3d(0, 0.1, 39)
                    materials: [ PrincipledMaterial { baseColor: "#00b0ff"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // --- PLASMA PROJECTOR MUZZLE NOZZLE ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.054, 0.062, 0.05)
                    position: Qt.vector3d(0, 0.1, 46)
                    materials: [ PrincipledMaterial { baseColor: "#15181e"; metalness: 0.85; roughness: 0.4 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.032, 0.040, 0.015)
                    position: Qt.vector3d(0, 0.1, 48.5)
                    materials: [ PrincipledMaterial { baseColor: "#76ffff"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // --- TOP HOLOGRAPHIC OPTIC HOUSING & EMITTER ---
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.032, 0.036, 0.14)
                    position: Qt.vector3d(0, 7.8, 1)
                    materials: [ PrincipledMaterial { baseColor: "#181d24"; roughness: 0.6 } ]
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.028, 0.028, 0.01)
                    position: Qt.vector3d(0, 8.8, 6.5)
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }

                // Plasma Muzzle Flash & Light
                Model {
                    id: heavyMuzzleFlash
                    source: "#Cube"
                    scale: Qt.vector3d(0.14, 0.14, 0.14)
                    position: Qt.vector3d(0, 0.1, 51)
                    visible: false
                    materials: [ PrincipledMaterial { baseColor: "#00e5ff"; lighting: PrincipledMaterial.NoLighting } ]
                }
                PointLight {
                    id: heavyFlashLight
                    position: Qt.vector3d(0, 0.1, 51)
                    color: "#00e5ff"
                    brightness: 9.0
                    visible: heavyMuzzleFlash.visible
                }
            }
        }

        // Lighting: Industrial facility corridor illumination
        DirectionalLight {
            eulerRotation: Qt.vector3d(-55, 30, 0)
            brightness: (levelManager && levelManager.currentLevel === 3) ? 3.5 : 2.4
            ambientColor: (levelManager && levelManager.currentLevel === 3) ? "#5a6878" : "#424a59"
        }

        PointLight {
            position: (levelManager && levelManager.currentLevel === 3) ? Qt.vector3d(2000, 300, 2000) : Qt.vector3d(800, 240, 800)
            brightness: (levelManager && levelManager.currentLevel === 3) ? 7.5 : 6.0
            color: (levelManager && levelManager.currentLevel === 3) ? "#f5e6cb" : "#d8e6f8"
        }

        // ==================== DYNAMIC TILE-TO-BLOCK LEVEL RENDERER ====================
        LevelView {
            id: levelView
            levelManager: levelManager
            bossArena: bossArena
            animationManager: animationManager
            cameraYaw: root.frameCameraYaw
        }

        // ==================== 3D BULLET TRACERS (Stage V8) ====================
        Repeater3D {
            model: 8
            Node {
                readonly property var tracerItem: (index < animationManager.tracers.length) ? animationManager.tracers[index] : null
                visible: tracerItem !== null && tracerItem.alpha > 0.01
                position: tracerItem ? Qt.vector3d(tracerItem.midX, tracerItem.midY, tracerItem.midZ) : Qt.vector3d(0, -9999, 0)
                eulerRotation: tracerItem ? Qt.vector3d(tracerItem.pitch, tracerItem.yaw, 0) : Qt.vector3d(0, 0, 0)
                Model {
                    source: "#Cube"
                    scale: tracerItem ? Qt.vector3d(0.04, 0.04, tracerItem.length / 100.0) : Qt.vector3d(0, 0, 0)
                    materials: [
                        PrincipledMaterial {
                            baseColor: tracerItem ? tracerItem.color : "#ffffff"
                            lighting: PrincipledMaterial.NoLighting
                            opacity: tracerItem ? tracerItem.alpha : 0.0
                        }
                    ]
                }
            }
        }

        // ==================== 3D HIT SPARKS & BLOCK DEBRIS (Stage V8) ====================
        Repeater3D {
            model: 16
            Model {
                readonly property var sparkItem: (index < animationManager.sparks.length) ? animationManager.sparks[index] : null
                visible: sparkItem !== null && sparkItem.alpha > 0.01
                source: "#Cube"
                position: sparkItem ? Qt.vector3d(sparkItem.x, sparkItem.y, sparkItem.z) : Qt.vector3d(0, -9999, 0)
                scale: sparkItem ? Qt.vector3d(sparkItem.size / 100.0, sparkItem.size / 100.0, sparkItem.size / 100.0) : Qt.vector3d(0, 0, 0)
                materials: [
                    PrincipledMaterial {
                        baseColor: sparkItem ? sparkItem.color : "#ffffff"
                        lighting: PrincipledMaterial.NoLighting
                        opacity: sparkItem ? sparkItem.alpha : 0.0
                    }
                ]
            }
        }

        // ==================== 3D VENT EXPLOSION DEBRIS (Stage V8) ====================
        Repeater3D {
            model: 16
            Model {
                readonly property var debrisItem: (index < animationManager.ventBursts.length) ? animationManager.ventBursts[index] : null
                visible: debrisItem !== null && debrisItem.alpha > 0.01
                source: "#Cube"
                position: debrisItem ? Qt.vector3d(debrisItem.x, debrisItem.y, debrisItem.z) : Qt.vector3d(0, -9999, 0)
                scale: debrisItem ? Qt.vector3d(debrisItem.size / 100.0, debrisItem.size / 100.0, debrisItem.size / 100.0) : Qt.vector3d(0, 0, 0)
                materials: [
                    PrincipledMaterial {
                        baseColor: debrisItem ? debrisItem.color : "#ffffff"
                        lighting: PrincipledMaterial.NoLighting
                        opacity: debrisItem ? debrisItem.alpha : 0.0
                    }
                ]
            }
        }

        // ==================== 3D VOXEL ENEMIES (Rendered from pool via Repeater) ====================
        Repeater3D {
            model: enemyManager.poolSize()

            EnemyModel {
                enemyObj: enemyManager.enemyAt(index)
                cameraYaw: root.frameCameraYaw
            }
        }

        // ==================== 3D VOXEL PICKUPS ====================
        // Food Pack
        Node {
            position: pickupFood.renderPosition
            eulerRotation: Qt.vector3d(0, pickupFood.rotationY, 0)
            visible: !pickupFood.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.35, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; roughness: 0.5 } ]
            }
        }
        // Bandage
        Node {
            position: pickupBandage.renderPosition
            eulerRotation: Qt.vector3d(0, pickupBandage.rotationY, 0)
            visible: !pickupBandage.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.35, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#3498db"; roughness: 0.5 } ]
            }
        }
        // Medkit
        Node {
            position: pickupMedkit.renderPosition
            eulerRotation: Qt.vector3d(0, pickupMedkit.rotationY, 0)
            visible: !pickupMedkit.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.40, 0.40, 0.40)
                materials: [ PrincipledMaterial { baseColor: "#e74c3c"; roughness: 0.5 } ]
            }
        }
        // Extra Bandage (Loading Bay)
        Node {
            position: pickupExtraBandage.renderPosition
            eulerRotation: Qt.vector3d(0, pickupExtraBandage.rotationY, 0)
            visible: !pickupExtraBandage.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.35, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#3498db"; roughness: 0.5 } ]
            }
        }
        // Extra Food Pack (Pre-Elevator)
        Node {
            position: pickupExtraFood.renderPosition
            eulerRotation: Qt.vector3d(0, pickupExtraFood.rotationY, 0)
            visible: !pickupExtraFood.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.35, 0.35, 0.35)
                materials: [ PrincipledMaterial { baseColor: "#2ecc71"; roughness: 0.5 } ]
            }
        }
        // Extra Medkit
        Node {
            position: pickupExtraMedkit.renderPosition
            eulerRotation: Qt.vector3d(0, pickupExtraMedkit.rotationY, 0)
            visible: !pickupExtraMedkit.isCollected
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.40, 0.40, 0.40)
                materials: [ PrincipledMaterial { baseColor: "#e74c3c"; roughness: 0.5 } ]
            }
        }
    }

    // ==================== INPUT HANDLING & CONTROLS ====================
    Item {
        id: inputHandler
        anchors.fill: parent
        focus: true

        property bool moveForward: false
        property bool moveBackward: false
        property bool moveLeft: false
        property bool moveRight: false

        function syncMovement() {
            player.setMoveInput(moveForward, moveBackward, moveLeft, moveRight)
        }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (gameManager.isPlaying) {
                    gameManager.pauseGame()
                } else if (gameManager.isPaused) {
                    gameManager.resumeGame()
                    root.mouseLookActive = true
                }
                event.accepted = true
                return
            }

            // Story screen: Enter/Return/Space continues
            if (gameManager.isStoryText) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    storyScreen.continueRequested()
                }
                event.accepted = true
                return
            }

            if (!gameManager.isPlaying) return

            if (event.key === Qt.Key_W) { moveForward = true; syncMovement() }
            else if (event.key === Qt.Key_S) { moveBackward = true; syncMovement() }
            else if (event.key === Qt.Key_A) { moveLeft = true; syncMovement() }
            else if (event.key === Qt.Key_D) { moveRight = true; syncMovement() }
            else if (event.key === Qt.Key_Space) player.jump()
            else if (event.key === Qt.Key_Control || event.key === Qt.Key_C) player.setCrouch(true)
            else if (event.key === Qt.Key_Q) player.switchWeapon()
            else if (event.key === Qt.Key_R) root.activeWeapon.reload()
            else if (event.key === Qt.Key_1) player.useFoodPack()
            else if (event.key === Qt.Key_2) player.useBandage()
            else if (event.key === Qt.Key_3) player.useMedkit()
            else if (event.key === Qt.Key_F) {
                root.flashlightActive = !root.flashlightActive
                root.hitNotificationText = root.flashlightActive ? "TACTICAL FLASHLIGHT: [ENGAGED]" : "TACTICAL FLASHLIGHT: [DISABLED]"
                root.hitNotificationColor = root.flashlightActive ? "#00e5ff" : "#95a5a6"
                hitNotificationTimer.restart()
            }
            else if (event.key === Qt.Key_H) {
                root.hallwayDarknessActive = !root.hallwayDarknessActive
                root.hitNotificationText = root.hallwayDarknessActive ? "DARK HALLWAY SHADER: [ATMOSPHERIC ON]" : "DARK HALLWAY SHADER: [OFF]"
                root.hitNotificationColor = root.hallwayDarknessActive ? "#2ecc71" : "#e67e22"
                hitNotificationTimer.restart()
            }

            event.accepted = true
        }

        Keys.onReleased: function(event) {
            if (!gameManager.isPlaying) return

            if (event.key === Qt.Key_W) { moveForward = false; syncMovement() }
            else if (event.key === Qt.Key_S) { moveBackward = false; syncMovement() }
            else if (event.key === Qt.Key_A) { moveLeft = false; syncMovement() }
            else if (event.key === Qt.Key_D) { moveRight = false; syncMovement() }
            else if (event.key === Qt.Key_Control || event.key === Qt.Key_C) player.setCrouch(false)

            event.accepted = true
        }

        MouseArea {
            id: mouseController
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: root.mouseLookActive ? Qt.BlankCursor : Qt.ArrowCursor
            hoverEnabled: true

            property real lastX: 0
            property real lastY: 0
            property bool firstMove: true

            onWheel: function(wheel) {
                if (gameManager.isPlaying) {
                    player.switchWeapon()
                }
            }

            onPressed: function(mouse) {
                if (!gameManager.isPlaying) return

                if (!root.mouseLookActive) {
                    root.mouseLookActive = true
                    firstMove = true
                    return
                }

                if (mouse.button === Qt.RightButton) {
                    root.activeWeapon.toggleAim()
                } else if (mouse.button === Qt.LeftButton) {
                    var yawRad = (player.yaw * Math.PI) / 180.0
                    var pitchRad = (player.pitch * Math.PI) / 180.0
                    var dir = Qt.vector3d(
                        Math.sin(yawRad) * Math.cos(pitchRad),
                        -Math.sin(pitchRad),
                        -Math.cos(yawRad) * Math.cos(pitchRad)
                    )
                    root.activeWeapon.shootAll(player.cameraPosition, dir, gameWorld, enemyManager, bossArena)
                }
            }

            onPositionChanged: function(mouse) {
                if (!root.mouseLookActive || !gameManager.isPlaying) return

                if (firstMove) {
                    lastX = mouse.x
                    lastY = mouse.y
                    firstMove = false
                    return
                }

                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y

                if (Math.abs(dx) > 0 || Math.abs(dy) > 0) {
                    player.handleMouseMove(dx, dy)
                }

                var edgeMargin = 40
                if (mouse.x < edgeMargin || mouse.x > root.width - edgeMargin ||
                    mouse.y < edgeMargin || mouse.y > root.height - edgeMargin) {
                    player.centerCursor(root)
                    lastX = root.width / 2
                    lastY = root.height / 2
                }
            }
        }
    }

    // ==================== HUD OVERLAY ====================
    HUD {
        id: hud
        anchors.fill: parent
        visible: gameManager.isPlaying

        playerHealth: player.health
        playerMaxHealth: player.maxHealth
        weaponIndex: player.currentWeaponIndex
        hasHeavyWeapon: player.hasHeavyWeapon
        weaponName: player.currentWeaponIndex === 0 ? "SNIPER RIFLE" : "PLASMA REPEATER"
        ammo: root.activeWeapon.ammo
        maxAmmo: root.activeWeapon.maxAmmo
        reserveAmmo: root.activeWeapon.reserveAmmo
        isReloading: root.activeWeapon.isReloading
        isScoped: root.activeWeapon.isAiming
        score: gameManager.score

        sniperAmmo: sniperWeapon.ammo
        sniperReserve: sniperWeapon.reserveAmmo
        heavyAmmo: heavyWeapon.ammo
        heavyReserve: heavyWeapon.reserveAmmo

        // Nearest enemy info from EnemyManager
        enemyHealth: enemyManager.nearestEnemyHealth
        enemyMaxHealth: enemyManager.nearestEnemyMaxHealth
        enemyDead: enemyManager.nearestEnemyDead
        enemyState: enemyManager.nearestEnemyState
        enemyType: enemyManager.nearestEnemyType
        activeEnemyCount: enemyManager.activeCount

        isLevel3: levelManager.currentLevel === 3
        activeVents: bossArena.activeVentsCount
        totalVents: bossArena.totalVents
        totalVentHp: bossArena.totalVentHp
        maxTotalVentHp: bossArena.maxTotalVentHp
        bossArenaRef: bossArena
        objectiveText: (levelManager.currentLevel === 3)
            ? "THE LOGIC CORE // OBJECTIVE: Destroy all 4 glowing Cyan Cooling Vents! (Drones spawn infinitely)"
            : (levelManager.currentLevelName + " // OBJECTIVE: Reach the extraction tile")
        hitFeedbackText: root.hitNotificationText
        hitFeedbackColor: root.hitNotificationColor
        foodPacks: player.inventory ? player.inventory.foodPacks : 0
        bandages: player.inventory ? player.inventory.bandages : 0
        medkits: player.inventory ? player.inventory.medkits : 0

        levelName: levelManager.currentLevelName
        difficultyName: gameManager.difficultyName
        fps: root.currentFps
        damageFlashIntensity: animationManager.damageFlash
        healFlashIntensity: animationManager.healFlash
        flashlightActive: root.flashlightActive
        hallwayDarknessActive: root.hallwayDarknessActive
    }

    // ==================== STORY SCREEN (STAGE V2) ====================
    StoryScreen {
        id: storyScreen
        anchors.fill: parent
        visible: gameManager.isStoryText
        title: levelManager.storyTitle
        storyText: levelManager.storyText
        isWin: levelManager.currentLevel > 3 || gameManager.isWon
        onContinueRequested: {
            if (levelManager.currentLevel > 3 || gameManager.isWon) {
                gameManager.triggerWin()
                root.mouseLookActive = false
            } else {
                gameManager.continueFromStory()
                audioManager.playAmbient(levelManager.currentLevel)
                root.mouseLookActive = true
                inputHandler.forceActiveFocus()
            }
        }
    }

    // ==================== MENUS & MODALS ====================
    MainMenu {
        id: mainMenu
        anchors.fill: parent
        visible: gameManager.isMainMenu
        gameManager: gameManager
        onStartGameRequested: {
            var lvl = mainMenu.selectedLevel ? mainMenu.selectedLevel : 1
            root.setupLevel(lvl)
            gameManager.startGame()
        }
        onStartLevelRequested: function(lvl) {
            mainMenu.selectedLevel = lvl
            root.setupLevel(lvl)
            gameManager.startGame()
        }
        onExitRequested: {
            Qt.quit()
        }
    }

    PauseMenu {
        id: pauseMenu
        anchors.fill: parent
        visible: gameManager.isPaused
        gameManager: gameManager
        currentLevel: levelManager.currentLevel
        onResumeRequested: {
            gameManager.resumeGame()
            audioManager.playAmbient(levelManager.currentLevel)
            root.mouseLookActive = true
            inputHandler.forceActiveFocus()
        }
        onRestartRequested: {
            root.setupLevel(levelManager.currentLevel)
            gameManager.resumeGame()
            audioManager.playAmbient(levelManager.currentLevel)
            root.mouseLookActive = true
            inputHandler.forceActiveFocus()
        }
        onChangeLevelRequested: function(lvl) {
            root.setupLevel(lvl)
            gameManager.resumeGame()
            audioManager.playAmbient(lvl)
            root.mouseLookActive = true
            inputHandler.forceActiveFocus()
        }
        onMainMenuRequested: {
            audioManager.stopAmbient()
            enemyManager.clearAll()
            gameManager.returnToMainMenu()
            root.mouseLookActive = false
        }
    }

    GameOver {
        id: gameOver
        anchors.fill: parent
        visible: gameManager.isGameOver || (gameManager.isWon && !gameManager.isStoryText)
        isWon: gameManager.isWon
        finalScore: gameManager.score
        onRestartRequested: {
            root.setupLevel(levelManager.currentLevel)
            gameManager.restartGame()
            root.mouseLookActive = true
            inputHandler.forceActiveFocus()
        }
        onMainMenuRequested: {
            audioManager.stopAmbient()
            enemyManager.clearAll()
            gameManager.returnToMainMenu()
            root.mouseLookActive = false
        }
    }
}
