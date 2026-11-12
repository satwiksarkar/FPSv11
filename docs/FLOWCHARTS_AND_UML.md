# Project VANGUARD: Flowcharts & UML Diagrams

This document illustrates the narrative progression, game lifecycle finite state machine, and the complete unified class architecture for **FPSLabGame - Project VANGUARD**.

---

## 1. Project VANGUARD Narrative & Campaign Flowchart

`mermaid
flowchart TD
    A[Launch Application] --> B[MAIN MENU Screen]
    B -->|Select Difficulty & Start| C[LEVEL 1 STORY BRIEFING]
    C -->|Objective: Reach Loading Bay & Elevator| D[LEVEL 1: Fabrication Floors]
    
    subgraph Level 1 - Fabrication Floors
        D --> D1[Navigate Tight Industrial Maze]
        D1 --> D2[Eliminate Corridor Drones]
        D2 --> D3[Breach 10x10 Loading Bay Encounter]
        D3 --> D4[Collect Ammo & Medical Supplies]
        D4 --> D5[Step on Extraction Elevator: Tile 4]
    end

    D5 --> E[LEVEL 2 STORY BRIEFING]
    E -->|Objective: Secure Heavy Plasma Weapon & Find Shaft| F[LEVEL 2: The Armory]
    
    subgraph Level 2 - The Armory
        F --> F1[Spawn at West Perimeter]
        F1 --> F2[Locate The Cache: Tile 7]
        F2 -->|Acquire Weapon| F3[Unlock Heavy Plasma Repeater]
        F3 --> F4[Trigger Crossfire Ambush: Tile 8 Trap]
        F4 --> F5[Engage Armored Sentinels & Drones]
        F5 --> F6[Locate Descent Shaft: Tile 6]
    end

    F6 --> G[LEVEL 3 STORY BRIEFING]
    G -->|Objective: Sabotage 4 Cooling Vents & Neutralize Core| H[LEVEL 3: VANGUARD Core Arena]
    
    subgraph Level 3 - VANGUARD Core
        H --> H1[Enter 40x40 Reinforced Arena]
        H1 --> H2[VANGUARD Core Shield Active]
        H2 --> H3[Drones Spawn from Perimeter every 5s Max 4]
        H3 --> H4[Destroy North Vent 0: 150 HP]
        H4 --> H5[Destroy East Vent 1: 150 HP]
        H5 --> H6[Destroy South Vent 2: 150 HP]
        H6 --> H7[Destroy West Vent 3: 150 HP]
        H7 --> H8[Shield Collapses: Core Meltdown Triggered]
    end

    H8 --> I[WIN STORY SCREEN: VANGUARD Neutralized]
    I --> J[VICTORY SCREEN with Final Score]
    J -->|Play Again| B
`

---

## 2. Game Lifecycle State Machine (GameManager)

`mermaid
stateDiagram-v2
    [*] --> MainMenu
    MainMenu --> StoryText : startGame()
    StoryText --> Playing : continueFromStory() [Enter / Space / Click]
    
    Playing --> Paused : pauseGame() [Esc Key]
    Paused --> Playing : resumeGame() [Esc / Resume Button]
    
    Playing --> StoryText : advanceToNextLevel() [Level Transition]
    Playing --> GameOver : triggerGameOver() [Player Health = 0]
    Playing --> Won : triggerWin() [Level 3 Vents Destroyed]
    
    GameOver --> Playing : restartGame() [Restart Button]
    GameOver --> MainMenu : returnToMainMenu()
    
    Won --> MainMenu : returnToMainMenu()
    Won --> Playing : restartGame()
    
    Paused --> MainMenu : returnToMainMenu()
    Paused --> Playing : restartGame()
`

---

## 3. Comprehensive UML Class Diagram

`mermaid
classDiagram
    %% Core State & Level Management
    class GameManager {
        -GameState m_gameState
        -int m_score
        -Difficulty m_difficulty
        +startGame() void
        +pauseGame() void
        +resumeGame() void
        +restartGame() void
        +returnToMainMenu() void
        +triggerGameOver() void
        +triggerWin() void
        +addScore(int points) void
    }

    class LevelData {
        +LEVEL1_SIZE: int = 32
        +LEVEL2_SIZE: int = 64
        +LEVEL3_SIZE: int = 40
        +getTile(level, row, col) int
        +getMapWidth(level) int
        +getMapHeight(level) int
        +getSpawnPoint(level) QVector3D
        +getExitCenterPosition(level) QVector3D
        +checkReachability(level, log) bool
    }

    class LevelManager {
        -int m_currentLevel
        -bool m_heavyWeaponCollected
        +loadLevel(levelIndex) bool
        +getTile(row, col) int
        +isWalkable(row, col) bool
        +consumeHeavyWeaponTile(x, z) bool
        +isExitTile(row, col) bool
    }

    class TileMapInstancing {
        -QByteArray m_instanceData
        -int m_instanceCount
        +buildInstances(level, tileType, height) void
        +getInstanceBuffer() QByteArray
    }

    %% Player & Physics
    class Player {
        -QVector3D m_position
        -float m_yaw
        -float m_pitch
        -bool m_hasHeavyWeapon
        -int m_currentWeaponIndex
        +moveForward(dt) void
        +moveRight(dt) void
        +jump() void
        +setCrouch(bool) void
        +switchWeapon() void
        +giveHeavyWeapon() void
        +takeDamage(amount) void
        +heal(amount) void
        +useFoodPack() bool
        +useBandage() bool
        +useMedkit() bool
        +reset() void
    }

    class GameWorld {
        -QVector3D m_gravity
        -QVector3D m_spawnPosition
        +applyGravity(pos, vel, dt) void
        +clampToGround(pos) QVector3D
        +resetWorld() void
    }

    class CollisionSystem {
        +checkAABB(boxA, boxB) bool
        +checkSweptSphere(start, end, radius, block) bool
        +resolvePlayerCollision(pos, radius, height, levelManager) QVector3D
    }

    class HealthSystem {
        -int m_health
        -int m_maxHealth
        -bool m_isDead
        +takeDamage(amount) void
        +heal(amount) void
        +setHealth(val) void
        +reset() void
    }

    class Inventory {
        -int m_foodPacks
        -int m_bandages
        -int m_medkits
        +addItem(type, count) void
        +useFoodPack(healthSystem) bool
        +useBandage(healthSystem) bool
        +useMedkit(healthSystem) bool
        +reset() void
    }

    class Pickup {
        -QVector3D m_position
        -int m_itemType
        -bool m_isCollected
        +checkCollection(playerPos) bool
        +reset() void
    }

    %% Weapons Subsystem
    class Weapon {
        <<abstract>>
        #int m_ammo
        #int m_maxAmmo
        #int m_reserveAmmo
        #float m_fireCooldown
        #float m_reloadTime
        +fire() bool
        +reload() void
        +update(dt) void
        +setAmmo(ammo) void
        +setReserveAmmo(count) void
        +resetAmmo() void
    }

    class Sniper {
        -bool m_isAiming
        -float m_scopedFov
        -float m_defaultFov
        +setAiming(bool) void
        +shoot(origin, dir, world, enemyManager) HitType
    }

    class HeavyWeapon {
        -bool m_isAiming
        +shoot(origin, dir, world, enemyManager) HitType
    }

    %% AI & Enemies Subsystem
    class Enemy {
        -EnemyType m_type
        -AIState m_state
        -QVector3D m_position
        -float m_attackTimer
        +update(dt, playerPos, world) void
        +takeDamage(amount, isHeadshot) void
        +isDead() bool
    }

    class EnemyManager {
        -QList~Enemy*~ m_enemies
        -int m_activeCount
        +spawnDrone(pos) Enemy*
        +spawnSentinel(pos) Enemy*
        +updateAll(dt, playerPos, world) void
        +checkRayHit(origin, dir, dist) Enemy*
        +clearAll() void
    }

    class CoolingVent {
        -int m_health
        -QVector3D m_position
        -bool m_isDestroyed
        +takeDamage(amount) void
        +isDestroyed() bool
    }

    class BossArena {
        -QList~CoolingVent*~ m_vents
        -float m_droneSpawnTimer
        +activeVentsCount() int
        +damageVent(index, amount) void
        +isCoreDestroyed() bool
        +update(dt, enemyManager) void
    }

    %% Audio & VFX Subsystems
    class AudioManager {
        -QMap~QString, QSoundEffect*~ m_effects
        +playGunshot() void
        +playHeavyGunshot() void
        +playHitFeedback() void
        +playPickup() void
        +playAmbient(level) void
        +stopAmbient() void
    }

    class AnimationManager {
        -QList~TracerData~ m_tracers
        -QList~SparkData~ m_sparks
        +spawnTracer(start, end, type) void
        +spawnSparks(hitPos, normal) void
        +update(dt) void
        +clearAll() void
    }

    %% Relationships
    GameManager --> LevelManager : drives
    GameManager --> Player : controls
    LevelManager --> LevelData : queries
    LevelManager --> TileMapInstancing : builds
    Player --> HealthSystem : contains
    Player --> Inventory : contains
    Player --> GameWorld : interacts
    Player --> CollisionSystem : queries
    Player ..> Weapon : equips
    Weapon <|-- Sniper : inherits
    Weapon <|-- HeavyWeapon : inherits
    Enemy --> HealthSystem : contains
    EnemyManager o-- Enemy : pools & updates
    BossArena o-- CoolingVent : manages 4 vents
    BossArena --> EnemyManager : triggers drone reinforcements
    Sniper ..> EnemyManager : raycasts against
    HeavyWeapon ..> EnemyManager : raycasts against
    Sniper ..> BossArena : raycasts against vents
    HeavyWeapon ..> BossArena : raycasts against vents
    Sniper ..> AnimationManager : spawns tracers
    HeavyWeapon ..> AnimationManager : spawns tracers
    Player ..> AudioManager : plays sounds
    Weapon ..> AudioManager : plays weapon sound