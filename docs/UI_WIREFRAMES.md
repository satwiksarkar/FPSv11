# Project VANGUARD: UI Wireframe Layouts

This document presents ASCII text wireframes for all 2D user interfaces in **FPSLabGame - Project VANGUARD**.

---

## 1. Main Menu Screen (`MainMenu.qml`)

```
+==============================================================================+
|                                                                              |
|       [ PROJECT VANGUARD : CLASSIFIED ROBOTICS RECLAMATION FACILITY ]        |
|                                                                              |
|                     +-----------------------------+                          |
|                     |     [ > START MISSION ]     |                          |
|                     +-----------------------------+                          |
|                     |    DIFFICULTY: [ NORMAL ]   |                          |
|                     +-----------------------------+                          |
|                     |     [ MISSION ARCHIVES ]    |                          |
|                     +-----------------------------+                          |
|                     |     [ OPERATOR MANUAL ]     |                          |
|                     +-----------------------------+                          |
|                     |       [ ABORT & EXIT ]      |                          |
|                     +-----------------------------+                          |
|                                                                              |
| [SYS_STATUS: ONLINE]                  [QT 6.11.1 / MIN_GW / VOXEL ENGINE]    |
+==============================================================================+
```

---

## 2. Operator Manual / Instructions Dialog

```
+==============================================================================+
|                       === TACTICAL OPERATIONS MANUAL ===                     |
|                                                                              |
|  +-----------------------------------+  +---------------------------------+  |
|  | LOCOMOTION CONTROLS               |  | COMBAT & WEAPON SYSTEMS         |  |
|  | - [W/A/S/D] : Kinematic Movement   |  | - [LEFT CLICK]  : Discharge Fire|  |
|  | - [SPACE]   : Jump Maneuver       |  | - [RIGHT CLICK] : Optical Scope |  |
|  | - [CTRL/C]  : Crouch Stance       |  | - [Q / WHEEL]   : Swap Weapon   |  |
|  | - [MOUSE]   : 360 Pitch/Yaw Look  |  | - [R]           : Manual Reload |  |
|  +-----------------------------------+  +---------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  | FIELD MEDICAL & INVENTORY SUPPLIES                                     |  |
|  | - [1] FOOD PACK : Restores +20 Vitality                                |  |
|  | - [2] BANDAGE   : Restores +30 Vitality                                |  |
|  | - [3] MEDKIT    : Restores +50 Vitality                                |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  | MISSION OBJECTIVES                                                     |  |
|  | - LVL 1: Navigate Fabrication Maze -> Clear Loading Bay -> Elevator (4)|  |
|  | - LVL 2: Armory -> Cache (7) Heavy Weapon -> Trap (8) -> Shaft (6)    |  |
|  | - LVL 3: Destroy 4 Cooling Vents -> Collapse VANGUARD AI Shield       |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|                            [ PRESS ESC OR CLICK TO CLOSE ]                   |
+==============================================================================+
```

---

## 3. Mission Terminal Story Screen (`StoryScreen.qml`)

```
+==============================================================================+
|                                                                              |
|  [ VANGUARD MAINFRAME // SECURE TERMINAL DATA LINK ]                         |
|  TIMESTAMP: 2026.10.08_03:15:00 UTC                                         |
|  -------------------------------------------------------------------------   |
|                                                                              |
|  MISSION LOG: LEVEL 1 - FABRICATION FLOORS                                   |
|                                                                              |
|  > You are a senior systems engineer trapped in the automated subterranean   |
|    foundry complex of Project VANGUARD.                                      |
|                                                                              |
|  > The central AI has severed human command protocols and mobilized combat   |
|    automatons. You are armed with a calibrated Voxel Sniper Rifle.           |
|                                                                              |
|  > OBJECTIVE: Navigate the fabrication corridors, eliminate perimeter        |
|    reconnaissance Drones, push through the Loading Bay, and reach the        |
|    extraction elevator.                                                      |
|                                                                              |
|  -------------------------------------------------------------------------   |
|  STATUS: WAITING FOR OPERATOR CONFIRMATION...                                |
|                                                                              |
|                     +-----------------------------------+                    |
|                     |  [ PRESS ENTER OR CLICK TO START] |                    |
|                     +-----------------------------------+                    |
|                                                                              |
+==============================================================================+
```

---

## 4. In-Game Head-Up Display (HUD) (`HUD.qml`)

### A. Unscoped Combat View (Standard Hipfire)
```
+==============================================================================+
| [LVL 1: FABRICATION FLOORS] [DIFFICULTY: NORMAL]                    [60 FPS] |
|                                                                              |
|                                                                              |
|                                     |                                        |
|                                  -- + --    <-- [Crisp White Crosshair]      |
|                                     |                                        |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
| +-------------------------+                      +-------------------------+ |
| | VITALITY: 100 / 100     |                      | VOXEL SNIPER RIFLE      | |
| | [█████████████████████] |                      | MAG: 5 / 5   RES: 20    | |
| +-------------------------+                      +-------------------------+ |
| | INVENTORY: [1]FOOD: 2  [2]BANDAGE: 1  [3]MEDKIT: 1                       | |
| +--------------------------------------------------------------------------+ |
+==============================================================================+
```

### B. Scoped Precision Aim View (Right Click Held)
```
+==============================================================================+
| [OPTICAL MAGNIFICATION: 3.3x]                                       [60 FPS] |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
|                                     +        <-- [Illuminated Precision      |
|                                                           Red Dot Aim: #ff0033]
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
| +-------------------------+                      +-------------------------+ |
| | VITALITY: 100 / 100     |                      | VOXEL SNIPER RIFLE      | |
| | [█████████████████████] |                      | MAG: 5 / 5   RES: 20    | |
| +-------------------------+                      +-------------------------+ |
| | INVENTORY: [1]FOOD: 2  [2]BANDAGE: 1  [3]MEDKIT: 1                       | |
| +--------------------------------------------------------------------------+ |
+==============================================================================+
```

---

## 5. Pause Overlay Menu (`PauseMenu.qml`)

```
+==============================================================================+
|                                                                              |
|                       === SIMULATION SUSPENDED ===                           |
|                                                                              |
|                         CURRENT DEPLOYMENT: LEVEL 2                          |
|                                                                              |
|                        +----------------------------+                        |
|                        |     [ > RESUME MISSION ]   |                        |
|                        +----------------------------+                        |
|                        |    [ RESTART CURRENT MAP ] |                        |
|                        +----------------------------+                        |
|                        |    [ SELECT SECTOR / LVL ] |                        |
|                        +----------------------------+                        |
|                        |     [ RETURN TO TERMINAL ] |                        |
|                        +----------------------------+                        |
|                                                                              |
|                       [ PRESS ESC TO RESUME COMBAT ]                         |
|                                                                              |
+==============================================================================+
```

---

## 6. Mission Outcome (Game Over / Victory) (`GameOver.qml`)

```
+==============================================================================+
|                                                                              |
|                       VANGUARD AI CORE NEUTRALIZED                           |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  | MISSION STATS SUMMARY                                                  |  |
|  | - FINAL COMBAT SCORE    : 4,850 PTS                                    |  |
|  | - COMBAT RATING         : S-RANK [MASTER OPERATOR]                     |  |
|  | - FACILITY STATUS       : SHUTDOWN COMPLETE                            |  |
|  +------------------------------------------------------------------------+  |
|                                                                              |
|                        +----------------------------+                        |
|                        |     [ RESTART CAMPAIGN ]   |                        |
|                        +----------------------------+                        |
|                        |     [ RETURN TO MENU ]     |                        |
|                        +----------------------------+                        |
|                                                                              |
+==============================================================================+
```