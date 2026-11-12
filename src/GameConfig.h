#ifndef GAMECONFIG_H
#define GAMECONFIG_H

/**
 * @file GameConfig.h
 * @brief Centralized game configuration and tuning constants for Project VANGUARD.
 * 
 * All tunable values (movement speeds, physics parameters, weapon damage, enemy AI,
 * spawner timings, and diagnostic switches) are stored in this single header.
 */
namespace GameConfig {

    // === Player Movement & Kinematics ===
    constexpr float PLAYER_WALK_SPEED = 300.0f;       // Units per second
    constexpr float PLAYER_CROUCH_SPEED = 140.0f;     // Slower speed while crouching
    constexpr float PLAYER_JUMP_VELOCITY = 380.0f;    // Upward launch velocity
    constexpr float GRAVITY = 980.0f;                 // Downward gravity acceleration
    constexpr float EYE_HEIGHT_STAND = 160.0f;        // Camera Y offset when standing
    constexpr float EYE_HEIGHT_CROUCH = 90.0f;        // Camera Y offset when crouching
    constexpr float CROUCH_TRANSITION_SPEED = 10.0f;  // Lerp speed for smooth crouching
    constexpr float MOUSE_SENSITIVITY = 0.15f;        // Mouse look sensitivity
    constexpr float PITCH_LIMIT_MIN = -80.0f;         // Downward look limit (degrees)
    constexpr float PITCH_LIMIT_MAX = 80.0f;          // Upward look limit (degrees)

    // === Health System ===
    constexpr int MAX_PLAYER_HEALTH = 100;            // Maximum player HP (carries over between levels)
    constexpr int MAX_ENEMY_HEALTH = 100;             // Base enemy health

    // === Sniper Weapon Tuning ===
    constexpr float SNIPER_FIRE_COOLDOWN = 0.6f;      // Fast bolt-action cycle delay (0.6s for responsive combat)
    constexpr int SNIPER_MAGAZINE_SIZE = 5;           // Default rounds per magazine
    constexpr int SNIPER_MAGAZINE_SIZE_EASY = 10;     // Easy mode magazine capacity (10 rounds in Level 3)
    constexpr int SNIPER_MAGAZINE_SIZE_HARD = 5;      // Hard mode magazine capacity (5 rounds in Level 3)
    constexpr int SNIPER_RESERVE_AMMO = 20;           // Initial reserve ammo
    constexpr float SNIPER_RELOAD_TIME = 2.2f;        // Reload duration in seconds
    constexpr int PLAYER_HEADSHOT_DAMAGE = 100;       // Instantly eliminates enemy targets
    constexpr int PLAYER_BODYSHOT_DAMAGE = 40;        // Body hit damage
    constexpr int ENEMY_HEADSHOT_DAMAGE = 50;         // Enemy head hit on player
    constexpr int ENEMY_BODYSHOT_DAMAGE = 20;         // Enemy body hit on player
    constexpr float ENEMY_MISS_CHANCE = 0.35f;        // 35% chance for enemy shot to miss

    // === Heavy Weapon Tuning (Plasma Repeater) ===
    constexpr int HEAVY_WEAPON_DAMAGE = 25;           // Damage per plasma bolt
    constexpr float HEAVY_FIRE_COOLDOWN = 0.15f;      // Rapid fire rate (6.67 rounds/second)
    constexpr int HEAVY_MAGAZINE_SIZE = 30;           // Magazine capacity
    constexpr int HEAVY_RESERVE_AMMO = 90;            // Initial reserve heavy rounds
    constexpr float HEAVY_RELOAD_TIME = 2.5f;         // Reload time in seconds

    // === Ammo Pickups ===
    constexpr int AMMO_PICKUP_SNIPER = 5;             // Default +5 sniper rounds per ammo tile
    constexpr int AMMO_PICKUP_SNIPER_EASY = 10;       // +10 sniper rounds in Easy mode
    constexpr int AMMO_PICKUP_SNIPER_HARD = 5;        // +5 sniper rounds in Hard mode
    constexpr int AMMO_PICKUP_HEAVY = 30;             // +30 heavy rounds per ammo tile (if owned)

    // === Enemy Archetypes: Drone (Melee Chaser) ===
    constexpr int DRONE_HEALTH = 40;                  // Fragile melee pursuer
    constexpr float DRONE_SPEED = 300.0f;             // ~3 blocks per second (3 * 100 units/s)
    constexpr int DRONE_MELEE_DAMAGE = 10;            // Damage dealt per melee hit
    constexpr float DRONE_ATTACK_COOLDOWN = 1.0f;     // Attack frequency (every 1.0s)
    constexpr float DRONE_ATTACK_RANGE = 120.0f;      // ~1.2 blocks strike distance

    // === Enemy Archetypes: Sentinel (Ranged Gunner) ===
    constexpr int SENTINEL_HEALTH = 100;              // Armored ranged turret/mech
    constexpr float SENTINEL_SHOOT_INTERVAL = 2.0f;   // 2.0s between burst shots
    constexpr int SENTINEL_DAMAGE = 15;               // 15 damage per hit on body
    constexpr float SENTINEL_ACCURACY = 0.60f;        // 60% accuracy
    constexpr float SENTINEL_RANGE_TILES = 25.0f;     // Range ~25 tiles (2500 units)

    // === Boss: Cooling Vents & Mainframe ===
    constexpr int COOLING_VENT_HEALTH = 150;          // Health per cooling vent
    constexpr int TOTAL_COOLING_VENTS = 4;            // 4 vents surrounding the logic core
    constexpr float LEVEL3_SPAWN_INTERVAL = 5.0f;     // Spawns one Drone every 5s from perimeter

    // === AI Management & Performance Limits ===
    constexpr int MAX_ACTIVE_ENEMIES = 30;            // Hard cap across all active enemy entities (supports Level 2 dense waves)
    constexpr float ENEMY_PATHFIND_REFRESH = 0.4f;    // Refresh BFS path every 0.4s (never per-frame)

    // === Score Values ===
    constexpr int DRONE_KILL_SCORE = 50;              // Points awarded for eliminating a Drone
    constexpr int SENTINEL_KILL_SCORE = 150;          // Points awarded for eliminating a Sentinel

    // === Recovery Items ===
    constexpr int HEAL_FOOD_PACK = 20;                // HP restored by Food Pack (Key 1)
    constexpr int HEAL_BANDAGE = 30;                  // HP restored by Bandage (Key 2)
    constexpr int HEAL_MEDKIT = 50;                   // HP restored by Medkit (Key 3)

    // === World & Voxel Proportions ===
    constexpr float BLOCK_SIZE = 100.0f;              // Base grid size for Minecraft cubes
    constexpr float WALL_HEIGHT = 300.0f;             // Standard wall height (3 stacked blocks)
    constexpr float CRATE_HEIGHT = 200.0f;            // Shipping crate height (2 stacked blocks)
    constexpr float BOUNDARY_LIMIT = 5000.0f;         // Fallback map boundary limit

    // === Quality Presets & Visual Effects (Stage V8 & V9) ===
    enum class QualityPreset {
        LOW = 0,
        MEDIUM = 1,
        HIGH = 2
    };

    constexpr QualityPreset CURRENT_QUALITY = QualityPreset::MEDIUM; // Default: MEDIUM

    constexpr bool ENABLE_EFFECTS_RECOIL = true;
    constexpr bool ENABLE_EFFECTS_MUZZLE_FLASH = true;
    constexpr bool ENABLE_EFFECTS_TRACERS = true;
    constexpr bool ENABLE_EFFECTS_HIT_SPARKS = true;
    constexpr bool ENABLE_EFFECTS_DAMAGE_FLASH = true;
    constexpr bool ENABLE_EFFECTS_HEAL = true;
    constexpr bool ENABLE_EFFECTS_VENT_BURST = true;
    constexpr bool ENABLE_EFFECTS_ELEVATOR_GLOW = true;
    constexpr bool ENABLE_AUDIO = true;
    constexpr bool ENABLE_AMBIENT_AUDIO = true;

    // Effect Pool Limits (simple, pooled, zero heap thrashing)
    constexpr int MAX_ACTIVE_TRACERS = 16;
    constexpr int MAX_ACTIVE_SPARKS = 32;
    constexpr int MAX_ACTIVE_DEBRIS = 32;

    // === Diagnostics & Debug ===
    constexpr bool DEBUG_LOG_TILE_COUNTS = true;       // Log tile counts and block counts per level

} // namespace GameConfig

#endif // GAMECONFIG_H
