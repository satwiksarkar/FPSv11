# Project VANGUARD: Technical Specification & Future Roadmap

This document outlines the final technical specifications, Qt/CMake modules utilized, subsystem responsibilities, and future enhancement roadmaps for **FPSLabGame - Project VANGUARD**.

---

## 1. Technical Stack & Environment

* **Target Operating System**: Microsoft Windows 10 / 11 (64-bit)
* **Application Framework**: Qt 6.11.1
* **C++ Language Standard**: ISO C++17 (`set(CMAKE_CXX_STANDARD 17)`)
* **Build System**: CMake 3.25+ with Ninja / MinGW Makefiles
* **Compiler**: GNU Compiler Collection (MinGW-w64 13.1.0 64-bit)
* **Graphic Engine**: Qt Quick 3D (Scene Graph hardware instanced rendering)
* **Audio Engine**: Qt Multimedia (`QSoundEffect` low-latency multi-channel playback)

---

## 2. Qt Modules & CMake Configuration

The application links against the following Qt modules defined in [`CMakeLists.txt`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/CMakeLists.txt):

```cmake
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    Quick3D
    Multimedia
)
```

* `Qt6::Core`: Foundation primitives, memory models, object trees, signals/slots, file I/O.
* `Qt6::Gui`: Windowing subsystem, input event delivery, OpenGL/Vulkan surface formatting.
* `Qt6::Quick`: Declarative QML engine, scenegraph rendering, animations.
* `Qt6::Quick3D`: 3D spatial node hierarchy, `PerspectiveCamera`, materials (`PrincipledMaterial`), dynamic lighting, and `QQuick3DInstancing`.
* `Qt6::Multimedia`: Low-latency audio mixing and spatial sound effects via `QSoundEffect`.

---

## 3. Subsystem Architectural Mapping

| Subsystem Domain | Responsible Source Files | Functional Role |
|:-----------------|:-------------------------|:----------------|
| **Core Game State** | [`src/GameManager.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/GameManager.h) | Master finite state machine (MainMenu, StoryText, Playing, Paused, GameOver, Won). |
| **Map & Level Data** | [`src/LevelData.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/LevelData.h) | Raw 2D grid arrays, BFS reachability validation, spawn points, extraction coordinates. |
| **Level Flow** | [`src/LevelManager.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/LevelManager.h) | Active level loading, trigger evaluation (Loading bay, armory cache, crossfire ambush). |
| **3D Voxel Instancing** | [`src/TileMapInstancing.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/TileMapInstancing.h) | Hardware-accelerated GPU instance transform table generation for cubes. |
| **Player Controller** | [`src/Player.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Player.h) | 3D kinematics, mouse look, jump impulse, crouch height interpolation, inventory access. |
| **Physics & Collision** | [`src/CollisionSystem.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/CollisionSystem.h), [`src/GameWorld.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/GameWorld.h) | Grid-aligned swept AABB collision and ground plane gravity clamping. |
| **Vitality & Health** | [`src/HealthSystem.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/HealthSystem.h) | Clamped HP bounds, damage deduction, healing signals, death state dispatch. |
| **Inventory & Pickups**| [`src/Inventory.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Inventory.h), [`src/Pickup.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Pickup.h) | Storage and consumption of Food Packs (+20 HP), Bandages (+30 HP), and Medkits (+50 HP). |
| **Weapon Systems** | [`src/Weapon.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Weapon.h), [`src/Sniper.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Sniper.h), [`src/HeavyWeapon.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/HeavyWeapon.h) | Ammo pools, reload timers, DDA grid raycasting, headshot vs bodyshot calculation. |
| **Enemy AI & Spawner**| [`src/Enemy.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Enemy.h), [`src/EnemyManager.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/EnemyManager.h) | Drone chasers and Sentinel turrets, finite state machines, object pooling (max 16). |
| **Boss Arena** | [`src/BossArena.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/BossArena.h), [`src/CoolingVent.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/CoolingVent.h) | Four destructible corner cooling vents, core energy barrier, reinforcement throttling. |
| **Particle FX & Audio**| [`src/AnimationManager.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/AnimationManager.h), [`src/AudioManager.h/.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/AudioManager.h) | 3D bullet tracers, wall impact sparks, block debris, screen damage flash, low-latency audio. |
| **User Interfaces** | [`qml/HUD.qml`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/HUD.qml), [`qml/MainMenu.qml`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/MainMenu.qml), [`qml/StoryScreen.qml`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/StoryScreen.qml), etc. | Reactive HUD, crosshairs, red aim point, interactive terminals, pause and game over menus. |

---

## 4. Omitted / Skipped Features (Per Precedence Rules)

In accordance with strict prompt instructions, the following legacy and optional features were deliberately excluded or retired:
* **Retired Biomes**: All legacy Desert, Forest, and Snow code, textures, and assets were purged to establish a cohesive dark industrial sci-fi aesthetic.
* **Complex Ragdoll Physics**: Enemies dissolve into pixel sparks rather than computing dynamic ragdoll skeletons, ensuring optimal CPU efficiency on low-end lab hardware.
* **Multiplayer / Networking**: Retained strictly as a single-player tactical narrative campaign.

---

## 5. Future Enhancement Roadmap (Marked as NOT Implemented)

The following concepts represent prospective academic and technical expansions for future versions:

1. **[NOT IMPLEMENTED] Dynamic Shadow Mapping (Cascaded Shadow Maps)**:
   * Real-time soft shadow casting from directional floodlights across instanced voxel geometry.
2. **[NOT IMPLEMENTED] A* Spatial Mesh Pathfinding with Dynamic Obstacle Avoidance**:
   * Upgrading the line-of-sight chase vector to an active $A^*$ pathfinding graph around moving crates.
3. **[NOT IMPLEMENTED] Destructible Voxel Environment Mechanics**:
   * Allowing high-caliber sniper rounds or heavy plasma bursts to blow holes through crate obstacles.
4. **[NOT IMPLEMENTED] Shader-Based Post-Processing CRT Distortion Filter**:
   * Custom GLSL fragment shader simulating curved CRT monitor scanlines, phosphor glow, and chromatic aberration.
5. **[NOT IMPLEMENTED] Save / Load State Serializer (JSON Slot Storage)**:
   * Persisting player coordinates, ammo pools, and level progress to `QStandardPaths::AppDataLocation` JSON save files.