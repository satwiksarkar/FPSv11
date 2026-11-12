# Project VANGUARD: College Viva Examination Preparation Guide

This guide contains realistic viva examination questions with concise, technically rigorous answers based **strictly on the actual C++ and QML codebase** of **FPSLabGame - Project VANGUARD**.

---

### Q1: What architecture did you use to bridge C++ and QML, and why?
**Answer:**  
We used Qt's declarative meta-object system (`QObject`, `Q_PROPERTY`, `Q_INVOKABLE`, and `QML_ELEMENT`).
* **C++ Backend**: Houses computationally heavy systems, real-time physics simulation, DDA raycasting, audio management, and state machines (`GameManager`, `Player`, `Weapon`, `EnemyManager`).
* **QML Frontend**: Handles reactive UI layout, particle overlays, and 3D scene-graph rendering via Qt Quick 3D.
* **Communication**: QML binds reactively to C++ `Q_PROPERTY` signals (e.g., `player.health`, `activeWeapon.ammo`) and invokes C++ methods via `Q_INVOKABLE` (e.g., `player.useFoodPack()`, `activeWeapon.fire()`), ensuring complete separation of concerns and 60 FPS performance.

---

### Q2: How are thousands of 3D voxel blocks rendered without dropping below 60 FPS?
**Answer:**  
We implemented hardware instanced rendering using Qt Quick 3D’s `QQuick3DInstancing` in [`TileMapInstancing.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/TileMapInstancing.cpp).  
Instead of creating individual `Model` nodes for every block (which would choke the CPU with draw calls), we read the 2D tile matrix and pack all block 3D translation vectors and scales into a single binary GPU instance table (`InstanceTableEntry`). A single `#Cube` mesh primitive is rendered by the GPU using this instance table in **one single draw call**.

---

### Q3: How does shooting hit detection work? Do you use physics colliders or raycasting?
**Answer:**  
We use analytical **Digital Differential Analysis (DDA) raycasting** in [`Sniper.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Sniper.cpp) and [`HeavyWeapon.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/HeavyWeapon.cpp).  
When the weapon discharges, a 3D ray is projected along the camera's forward vector. The DDA algorithm steps through the discrete 2D level grid cell by cell until it intersects a solid block (`Wall`, `Crate`, `CoreWall`). Simultaneously, cylinder intersection tests check for active enemies and cooling vents along the ray. If an entity is struck before the nearest wall, damage is applied; otherwise, a hit spark is generated at the wall intersection point.

---

### Q4: How is a headshot distinguished from a bodyshot?
**Answer:**  
When an enemy is struck, the hit point height ($y$) along the entity's vertical axis is evaluated:
* If $y \in [110, 160]\text{ units}$ (the upper third of the model), it is classified as a **Headshot** ($80\text{ damage}$ with golden sparks and critical audio).
* If $y \in [0, 110]\text{ units}$, it is classified as a **Bodyshot** ($40\text{ damage}$ with red blood-sparks).

---

### Q5: How do the hostile enemies make decisions? Explain their AI.
**Answer:**  
Enemies run an autonomous Finite State Machine (FSM) implemented in [`Enemy.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Enemy.cpp):
* **Drone (Melee Automaton)**: Starts in `Idle`. When the player enters detection range ($1,200\text{ units}$), it transitions to `Chasing`, moving toward the player at $260\text{ units/s}$. Within $80\text{ units}$, it transitions to `Attacking`, executing a melee swipe dealing $10\text{ damage}$ every second.
* **Sentinel (Ranged Turret)**: Stationary tripod defense battery. It monitors line-of-sight to the player via grid raycasting. If unobstructed and within $1,400\text{ units}$, it enters `Attacking`, firing a plasma bolt dealing $15\text{ damage}$ every $2.0\text{ s}$.

---

### Q6: How do you prevent memory leaks and garbage collection stutters with enemies?
**Answer:**  
We use the **Object Pool Pattern** in [`EnemyManager.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/EnemyManager.cpp).  
During startup, a fixed pool of `MAX_ACTIVE_ENEMIES = 16` objects is pre-allocated on the heap. Spawning an enemy simply fetches an inactive instance from the pool and resets its coordinates. When an enemy dies, it is marked inactive rather than deleted. This ensures **zero dynamic memory allocations (`new`/`delete`) during active combat**.

---

### Q7: How does the game guarantee that maps are always winnable?
**Answer:**  
During level initialization in [`LevelData.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/LevelData.cpp), a **Breadth-First Search (BFS) reachability algorithm** executes from the player's spawn tile (`TileCode::PlayerSpawn = 3`). The queue visits all connected walkable floor cells to confirm that a valid unobstructed path exists to the exit tile (`TileCode::Level1Exit = 4` or `TileCode::Level2Exit = 6`). If unreachable, an error assertion is logged.

---

### Q8: How does player movement and camera looking work? Why doesn't the camera flip over?
**Answer:**  
In [`Player.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/Player.cpp):
* Horizontal movement uses forward and right vectors derived from the camera yaw angle ($\theta$).
* Mouse motion delta directly updates yaw ($\theta$) and pitch ($\phi$).
* To prevent gimbal flip and disorienting camera inversions, pitch is strictly clamped:
  $$\phi = \text{qBound}(-89.0^\circ, \phi + \Delta y, +89.0^\circ)$$

---

### Q9: How do you handle pausing the game?
**Answer:**  
Pausing is coordinated by the `GameManager` state machine:
* Pressing `Esc` changes state to `GameState::Paused`.
* In `Main.qml`, input event forwarding is blocked, mouse cursor lock is released (`Qt.ArrowCursor`), and delta time accumulation in `FrameAnimation` is ignored.
* When paused, enemy updates, projectile physics, and weapon cooldowns are frozen.
* Pressing `Esc` or clicking Resume returns state to `GameState::Playing` and restores mouse locking.

---

### Q10: How do player stats (health, unlocked weapons, ammo) carry over between levels?
**Answer:**  
In [`Main.qml`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/qml/Main.qml), when the player reaches an exit elevator or descent shaft, `advanceToNextLevel()` calls `setupLevel(nextLvl, true)` with `isTransition = true`:
* The player's remaining health, `hasHeavyWeapon` boolean, sniper/plasma magazine ammo, reserve ammo, and inventory items (Food, Bandage, Medkit counts) are preserved in temporary variables.
* The new 3D level geometry is instanced and player coordinates are placed at the new map's spawn point.
* The preserved stats are immediately restored onto the player.
* Full resets to default values only occur when the user explicitly clicks **Restart** or returns to the **Main Menu**.

---

### Q11: How does the Level 3 Boss encounter work?
**Answer:**  
In [`BossArena.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/BossArena.cpp):
* The central VANGUARD core is shielded by an energy barrier and cannot take damage while cooling vents exist.
* Four Corner Cooling Vents ($150\text{ HP}$ each) are placed around the arena.
* The player must snipe or blast all four vents.
* Perimeter Drone spawners reinforce the room every $5.0\text{ s}$, strictly throttled to a maximum of **4 active enemies**.
* When all four vents are destroyed (`activeVentsCount == 0`), the core shield collapses, triggering the victory sequence.

---

### Q12: How is sound playback implemented without causing audio lag or frame drops?
**Answer:**  
In [`AudioManager.cpp`](file:///c:/Users/JOYDEEP/Desktop/FPSv8/qt%20project/src/AudioManager.cpp), sound effects are managed using `QSoundEffect` pools running on low-latency native OS audio backends. Sounds are pre-loaded at launch into memory buffers. Calling `playGunshot()` or `playHitFeedback()` triggers an already-cached voice without touching the hard drive or blocking the main GUI thread.