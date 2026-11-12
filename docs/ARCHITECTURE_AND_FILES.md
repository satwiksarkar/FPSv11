# Project VANGUARD: Architecture & File Breakdown

**Application**: FPSLabGame - Project VANGUARD  
**Framework**: Qt 6.11.1 (Qt Quick 3D, C++17, QML, CMake)  
**Root Directory**: [FPSLabGame](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project)

---

## 1. Directory Tree

`
FPSv8/qt project/
├── CMakeLists.txt                 # Master CMake configuration file
├── main.cpp                       # C++ entry point, logging, QML engine loader
├── master_prompt.txt              # Specification requirements and level design
├── README.md                      # Primary project overview and viva guide
├── assets/
│   ├── sounds/                    # Retro 8-bit procedural / wav audio clips
│   │   ├── armory_hum.wav         # Level 2 ambient background hum
│   │   ├── core_hum.wav           # Level 3 VANGUARD core hum
│   │   ├── death.wav              # Player elimination audio
│   │   ├── door.wav               # Elevator and shaft mechanical door slide
│   │   ├── enemy_hit.wav          # Ballistic impact feedback sound
│   │   ├── enemy_shot.wav         # Sentinel plasma laser discharge sound
│   │   ├── factory_hum.wav        # Level 1 fabrication floor ambient hum
│   │   ├── gunshot.wav            # Sniper rifle acoustic report
│   │   ├── heavy_gunshot.wav      # Plasma repeater high-energy burst sound
│   │   ├── level_clear.wav        # Level transition musical cue
│   │   ├── pickup.wav             # Ammo, medical, and weapon acquisition sound
│   │   ├── plasma_shot.wav        # Plasma weapon discharge
│   │   ├── reload.wav             # Weapon reload mechanism sound
│   │   └── vent_explode.wav       # Cooling vent destruction acoustic explosion
│   └── textures/                  # 16x16 Nearest-filtered voxel textures
│       ├── crate.png              # Metal shipping container block texture
│       ├── drone.png              # Aggressive aerial drone armor texture
│       ├── floor.png              # Industrial steel grating floor texture
│       ├── sentinel.png           # Heavy tripod sentinel turret texture
│       ├── vent.png               # Level 3 cooling vent core texture
│       └── wall.png               # Modular reinforced blast wall texture
├── docs/
│   ├── ARCHITECTURE_AND_FILES.md  # File-by-file analysis & communication graph
│   ├── FLOWCHARTS_AND_UML.md      # Game/story flowcharts & Mermaid UML class diagram
│   ├── UI_WIREFRAMES.md           # Text wireframes of all 2D retro UI screens
│   ├── TECHNICAL_EXPLANATIONS.md  # Instancing, DDA, BFS, FSM, and boss mechanics
│   ├── VIVA_PREPARATION_GUIDE.md  # College lab viva Q&A based on exact code
│   └── PROJECT_SPEC_AND_FUTURE.md # Tech stack summary and future roadmap
├── qml/
│   ├── EnemyModel.qml             # 3D visual hierarchy & animations for Drones & Sentinels
│   ├── GameOver.qml               # Game Over & Victory score summary screen
│   ├── HUD.qml                    # Retro sci-fi HUD (health, ammo, crosshair, scope dot)
│   ├── LevelView.qml              # 3D instanced voxel renderer for walls, crates, pillars
│   ├── Main.qml                   # Main QML application shell, 3D viewport, input controller
│   ├── MainMenu.qml               # Main menu UI (Start, Instructions, Difficulty, Exit)
│   ├── PauseMenu.qml              # Pause menu UI (Resume, Restart, Level select, Main Menu)
│   ├── StoryScreen.qml            # Narrative terminal briefings for Level 1, 2, 3, and Win
│   └── VentModel.qml              # 3D interactive model & billboard HP for Cooling Vents
├── scripts/
│   ├── generate_assets.py         # Waveform audio generator for procedural sounds
│   └── generate_vanguard_textures.py # 16x16 PNG texture generator
└── src/
    ├── AnimationManager.h/.cpp    # 3D bullet tracers, spark particles, damage flashes
    ├── AudioManager.h/.cpp        # QSoundEffect multi-channel low-latency audio player
    ├── BossArena.h/.cpp           # VANGUARD boss logic, vent management, shield state
    ├── CollisionSystem.h/.cpp     # AABB and cylinder swept collision detection
    ├── CoolingVent.h/.cpp         # Level 3 destructible cooling vent entities
    ├── Door.h/.cpp                # Animated elevator/shaft sliding doors
    ├── Enemy.h/.cpp               # Drone (chaser) & Sentinel (ranged) entity logic & FSM
    ├── EnemyManager.h/.cpp        # Fixed-pool enemy spawner, memory pool & tick manager
    ├── GameConfig.h               # Central constants, balance tuning, physics values
    ├── GameManager.h/.cpp         # Master state machine (MainMenu, Playing, Paused, etc.)
    ├── GameWorld.h/.cpp           # World physics, gravity, and ground clamp manager
    ├── HealthSystem.h/.cpp        # Reusable component for entity vitality and damage
    ├── HeavyWeapon.h/.cpp         # Rapid-fire dual-barrel plasma repeater logic
    ├── Inventory.h/.cpp           # Player item management (Food, Bandages, Medkits)
    ├── LevelData.h/.cpp           # 2D tile matrix definitions, spawns, reachability checks
    ├── LevelManager.h/.cpp        # Active level loader, runtime tile query, exit triggers
    ├── Pickup.h/.cpp              # 3D collectable items (health, ammo, weapons)
    ├── Player.h/.cpp              # First-person kinematics, mouse-look, inventory holder
    ├── Sniper.h/.cpp              # Precision sniper rifle with DDA raycast hitscan
    ├── TileMapInstancing.h/.cpp   # QQuick3DInstancing hardware instancing table builder
    └── Weapon.h/.cpp              # Base class for firearms (ammo, cooldown, reload)
`

---

## 2. File-by-File Breakdown

### Build & Root Configuration
* [CMakeLists.txt](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/CMakeLists.txt)
  * **Role**: Configures the CMake build system for Qt 6.11.1.
  * **Function**: Declares the executable target FPSLabGame, registers all C++ source files, binds QML modules via qt_add_qml_module(), links Qt modules (Core, Gui, Quick, Quick3D, Multimedia), and configures post-build asset deployment.
  * **Dependencies**: Talk to CMake tools and Qt 6 SDK.

* [main.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/main.cpp)
  * **Role**: Application entry point.
  * **Function**: Initializes QGuiApplication, sets the surface format to QQuick3D::idealSurfaceFormat(), installs a file message handler (ileLogHandler writing to un_debug.log), and instantiates QQmlApplicationEngine loading module FPSLabGame, component Main.
  * **Dependencies**: Connects to QQmlApplicationEngine and Windows console attachment.

* [src/GameConfig.h](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/GameConfig.h)
  * **Role**: Central gameplay configuration and constants header.
  * **Function**: Declares tile dimensions (BLOCK_SIZE = 100.0f), player speeds, jump velocity, gravity, camera heights, weapon stats (fire rate, reload duration, damage), enemy stats, and difficulty multipliers.

---

### Core Gameplay Engine (src/)

* [src/GameManager.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/GameManager.h)
  * **Role**: Finite state machine for application lifecycle.
  * **State Flow**: MainMenu $\to$ StoryText $\to$ Playing $\to$ Paused $\to$ GameOver / Won.
  * **Talks to**: HUD.qml, MainMenu.qml, PauseMenu.qml, GameOver.qml, StoryScreen.qml, Main.qml.

* [src/LevelData.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/LevelData.h)
  * **Role**: Immutable map storage and level topology.
  * **Function**: Contains raw int arrays for Level 1 (32x32), Level 2 (64x64), and Level 3 (40x40). Stores tile definitions (Wall=1, Crate=2, PlayerSpawn=3, Elevator=4, Shaft=6, Cache=7, Trap=8, CoreWall=9). Implements BFS reachability validation to guarantee winnable paths.
  * **Talks to**: LevelManager.

* [src/LevelManager.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/LevelManager.h)
  * **Role**: Runtime level manager and dynamic trigger tracker.
  * **Function**: Loads levels, exposes active map dimensions to QML, checks trigger tiles (Loading Bay, Heavy Weapon Cache, extraction exits), and tracks tile pickups.
  * **Talks to**: LevelData, TileMapInstancing, Main.qml.

* [src/TileMapInstancing.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/TileMapInstancing.h)
  * **Role**: High-performance GPU hardware instancer.
  * **Function**: Subclasses QQuick3DInstancing. Converts 2D tile arrays into GPU instance transform tables (InstanceTableEntry) allowing thousands of 3D cubes to render in a single GPU draw call.
  * **Talks to**: LevelManager, LevelView.qml.

* [src/Player.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Player.h)
  * **Role**: First-person player controller and entity coordinator.
  * **Function**: Manages 3D kinematic movement, mouse look (pitch [-89, +89] and yaw), crouching height lerping, jumping, gravity, weapon selection, and inventory delegation.
  * **Talks to**: GameWorld, HealthSystem, Inventory, CollisionSystem, Main.qml.

* [src/GameWorld.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/GameWorld.h)
  * **Role**: World physics simulation environment.
  * **Function**: Provides spatial bounding queries, gravity application, ground plane clamping, and world reset logic.
  * **Talks to**: Player, CollisionSystem.

* [src/CollisionSystem.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/CollisionSystem.h)
  * **Role**: Fast grid-aligned collision resolution.
  * **Function**: Performs swept-AABB player-to-world block collision, cylinder-to-block collision, and point-in-tile spatial lookups.
  * **Talks to**: LevelManager, Player, Enemy.

* [src/HealthSystem.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/HealthSystem.h)
  * **Role**: Vitality and damage management component.
  * **Function**: Handles current/max HP clamping, damage deduction, healing, death notification, and health percentage calculation for reactive UI updates.
  * **Talks to**: Player, Enemy, CoolingVent.

* [src/Inventory.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Inventory.h)
  * **Role**: Consumable item inventory storage.
  * **Function**: Tracks counts for Food Packs (+20 HP), Bandages (+30 HP), and Medkits (+50 HP). Dispatches health restoration upon item consumption.
  * **Talks to**: Player, HealthSystem, HUD.qml.

* [src/Pickup.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Pickup.h)
  * **Role**: 3D in-world interactive pickup item.
  * **Function**: Tracks 3D position, collection status, proximity check against player, and bobbing animation state.
  * **Talks to**: Main.qml, Player, Inventory.

* [src/Door.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Door.h)
  * **Role**: Sliding security door entity.
  * **Function**: Coordinates automatic opening/closing when player enters extraction zones (Elevator and Descent Shaft).
  * **Talks to**: LevelView.qml.

---

### Weapons & Combat Subsystem (src/)

* [src/Weapon.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Weapon.h)
  * **Role**: Base class for player firearms.
  * **Function**: Encapsulates magazine ammo, reserve ammo, cooldown timer, reload duration, firing state, and reactive signals (ired(), mmoChanged(), eloadingChanged()).
  * **Talks to**: Sniper, HeavyWeapon, Main.qml, HUD.qml.

* [src/Sniper.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Sniper.h)
  * **Role**: Bolt-action Voxel Sniper Rifle (AK-47 chassis).
  * **Function**: Manages scoping FOV transitions (60° normal $\to$ 18° zoom), optical zoom state, and 3D raycasting using Digital Differential Analysis (DDA) against grid blocks, enemies, and cooling vents. Detects headshots (80 dmg) vs bodyshots (40 dmg).
  * **Talks to**: Weapon, EnemyManager, BossArena, AnimationManager, HUD.qml.

* [src/HeavyWeapon.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/HeavyWeapon.h)
  * **Role**: Heavy Plasma Cannon / Repeater.
  * **Function**: Manages high-rate automatic plasma firing (0.12 s cooldown, 30 round battery, 20 dmg/shot), holographic zoom (45° FOV), and rapid raycast detection.
  * **Talks to**: Weapon, EnemyManager, BossArena, AnimationManager.

---

### AI & Enemies Subsystem (src/)

* [src/Enemy.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Enemy.h)
  * **Role**: AI finite state machine for hostile automatons.
  * **Entities**:
    * **Drone**: Fast melee chaser (40 HP, speed 260, melee range 80, 10 dmg).
    * **Sentinel**: Armored ranged turret (100 HP, stationary, plasma laser attack every 2.0 s, 15 dmg).
  * **States**: Idle $\to$ Chasing $\to$ Attacking $\to$ Dead.
  * **Talks to**: EnemyManager, HealthSystem, CollisionSystem, Player.

* [src/EnemyManager.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/EnemyManager.h)
  * **Role**: Enemy object pooling and spatial dispatcher.
  * **Function**: Pre-allocates memory for enemies (MAX_ACTIVE_ENEMIES = 16). Spawns Drones and Sentinels without runtime heap allocation, updates active enemies each tick, and performs raycast hit detection.
  * **Talks to**: Enemy, Main.qml, HUD.qml.

* [src/CoolingVent.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/CoolingVent.h)
  * **Role**: Level 3 boss vulnerability targets.
  * **Function**: Manages individual cooling vent vitality (150 HP), damage absorption, and destruction state.
  * **Talks to**: BossArena, VentModel.qml.

* [src/BossArena.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/BossArena.h)
  * **Role**: Level 3 VANGUARD Mainframe boss encounter coordinator.
  * **Function**: Spawns and manages 4 corner cooling vents, regulates perimeter Drone spawner throttling (max 4 active, 5 s respawn interval), and collapses core energy shield when all vents are destroyed.
  * **Talks to**: CoolingVent, EnemyManager, Main.qml.

---

### Visuals, Audio & UI (src/ & qml/)

* [src/AnimationManager.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/AnimationManager.h)
  * **Role**: High-speed particle, tracer, and visual FX coordinator.
  * **Function**: Manages 3D ballistic bullet tracers with fading alpha, hit spark particles, block destruction debris cubes, and red screen damage flashes.
  * **Talks to**: Main.qml.

* [src/AudioManager.h/.cpp](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/AudioManager.h)
  * **Role**: Multi-channel low-latency audio player.
  * **Function**: Manages pooled QSoundEffect instances for gunfire, impacts, explosions, pickups, ambient factory/core loops, and victory stings.
  * **Talks to**: Main.qml.

* [qml/Main.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/Main.qml)
  * **Role**: Root QML application coordinator.
  * **Function**: Sets up the 3D View3D, PerspectiveCamera, tactical lighting, player-held 3D weapon models (AK-47 and Plasma Cannon), particle repeaters, keyboard/mouse input handlers, level progression, and stats persistence.
  * **Talks to**: All QML components and C++ subsystems.

* [qml/HUD.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/HUD.qml)
  * **Role**: 2D retro sci-fi head-up display.
  * **Function**: Displays health bar, ammo counts, consumable inventory badges (1/2/3), radar compass, level name, damage flash vignette, hit notification toasts, center crosshairs, and the scoped illuminated red + aim dot.
  * **Talks to**: Player, Weapon, Inventory, GameManager.

* [qml/LevelView.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/LevelView.qml)
  * **Role**: 3D level geometry coordinator.
  * **Function**: Links TileMapInstancing tables to Model primitives for walls, crates, core pillars, ceilings, and exit markers.
  * **Talks to**: TileMapInstancing, LevelManager.

* [qml/EnemyModel.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/EnemyModel.qml)
  * **Role**: 3D procedural entity renderer for enemies.
  * **Function**: Constructs voxel meshes for Drones (slate armor, glowing red visor, reactor LED) and Sentinels (tripod base, turret head, dual laser barrels) with billboarded overhead health bars.
  * **Talks to**: Enemy, Main.qml.

* [qml/VentModel.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/VentModel.qml)
  * **Role**: 3D Cooling Vent renderer for Level 3.
  * **Function**: Renders heavy reinforced cooling column with glowing cyan coolant conduit and billboarded HP bar.
  * **Talks to**: CoolingVent, BossArena.

* [qml/MainMenu.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/MainMenu.qml)
  * **Role**: Primary retro menu screen.
  * **Function**: Provides Start Game, Level Select, Difficulty selection (Easy/Hard), Instructions popup, and Quit.
  * **Talks to**: GameManager.

* [qml/PauseMenu.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/PauseMenu.qml)
  * **Role**: In-game pause overlay.
  * **Function**: Freezes game loop; allows Resume, Restart Current Level, Change Level, and Return to Main Menu.
  * **Talks to**: GameManager.

* [qml/StoryScreen.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/StoryScreen.qml)
  * **Role**: Mission terminal briefing display.
  * **Function**: Shows typing text objectives on a black CRT screen before each level and on victory. Pauses game loop until acknowledged.
  * **Talks to**: GameManager, LevelManager.

* [qml/GameOver.qml](file:///C:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/GameOver.qml)
  * **Role**: Mission failure and victory score summary screen.
  * **Function**: Displays final score, combat evaluation grade, and Restart/Menu actions.
  * **Talks to**: GameManager.