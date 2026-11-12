cmake_minimum_required(VERSION 3.22)

project(FPSLabGame LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find Qt 6 packages required
find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D Multimedia)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_standard_project_setup()

qt_add_executable(FPSLabGame
    main.cpp
)

qt_add_qml_module(FPSLabGame
    URI FPSLabGame
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/HUD.qml
        qml/MainMenu.qml
        qml/PauseMenu.qml
        qml/GameOver.qml
        qml/StoryScreen.qml
        qml/LevelView.qml
        qml/EnemyModel.qml
        qml/VentModel.qml
    RESOURCES
        qml/dark_hallway.frag
        qml/dark_hallway.vert
        qml/dark_surface.frag
        assets/textures/stone.png
        assets/textures/door.png
        assets/textures/steel_wall.png
        assets/textures/crate.png
        assets/textures/floor_plate.png
        assets/textures/exit_elevator.png
        assets/textures/ammo_box.png
        assets/textures/core_wall.png
        assets/sounds/gunshot.wav
        assets/sounds/plasma_shot.wav
        assets/sounds/reload.wav
        assets/sounds/door.wav
        assets/sounds/enemy_hit.wav
        assets/sounds/death.wav
        assets/sounds/pickup.wav
        assets/sounds/vent_explode.wav
        assets/sounds/level_clear.wav
        assets/sounds/factory_hum.wav
        assets/sounds/armory_hum.wav
        assets/sounds/core_hum.wav
        assets/CREDITS.txt
    SOURCES
        src/GameConfig.h
        src/GameManager.h
        src/GameManager.cpp
        src/LevelData.h
        src/LevelData.cpp
        src/LevelManager.h
        src/LevelManager.cpp
        src/TileMapInstancing.h
        src/TileMapInstancing.cpp
        src/Player.h
        src/Player.cpp
        src/GameWorld.h
        src/GameWorld.cpp
        src/Weapon.h
        src/Weapon.cpp
        src/Sniper.h
        src/Sniper.cpp
        src/HeavyWeapon.h
        src/HeavyWeapon.cpp
        src/Enemy.h
        src/Enemy.cpp
        src/EnemyManager.h
        src/EnemyManager.cpp
        src/HealthSystem.h
        src/HealthSystem.cpp
        src/Inventory.h
        src/Inventory.cpp
        src/Pickup.h
        src/Pickup.cpp
        src/Door.h
        src/Door.cpp
        src/CollisionSystem.h
        src/CollisionSystem.cpp
        src/CoolingVent.h
        src/CoolingVent.cpp
        src/BossArena.h
        src/BossArena.cpp
        src/AudioManager.h
        src/AudioManager.cpp
        src/AnimationManager.h
        src/AnimationManager.cpp
)

target_include_directories(FPSLabGame PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(FPSLabGame PRIVATE
    Qt6::Quick
    Qt6::Quick3D
    Qt6::Multimedia
)

# Ensure sound and texture assets are directly accessible from the executable directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/assets DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
add_custom_command(TARGET FPSLabGame POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/assets
        $<TARGET_FILE_DIR:FPSLabGame>/assets
)

# Standard target properties for desktop app
set_target_properties(FPSLabGame PROPERTIES
    WIN32_EXECUTABLE ON
    MACOSX_BUNDLE ON
)
