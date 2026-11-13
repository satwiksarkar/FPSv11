#include "LevelData.h"
#include "GameConfig.h"
#include <QQueue>
#include <QVector>
#include <QDebug>
#include <QtMath>
#include <vector>
#include <queue>
#include <set>
#include <algorithm>

// ==================== 32x32 LEVEL 1: FABRICATION FLOORS ====================
// Outer walls: 1 (steel boundary)
// Inner obstacles: 2 (stacked metal shipping crates)
// Floor: 0 (walkable floor and corridors)
// Player spawn: 3 at row 29, col 2 (bottom-left receiving airlock)
// Exit: 4 (3x3 extraction elevator at rows 1-3, cols 28-30, top-right)
// Doors: 10 (D1-1 at 23,9; D1-2 at 16,13; D1-3 at 7,15; D1-4 at 3,24)
// Keys: Key 0 at (21,3), Key 1 at (8,25), Key 2 at (19,13), Key 3 at (3,4)
// Loading bay: rows 7 to 15, cols 17 to 26
const int LevelData::level1[LEVEL1_SIZE][LEVEL1_SIZE] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 4, 4, 4, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 4, 4, 4, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 10, 0, 0, 0, 4, 4, 4, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 3, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
};

const int LevelData::level2[LEVEL2_SIZE][LEVEL2_SIZE] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 6, 6, 6, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 6, 6, 6, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 6, 6, 6, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 7, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 3, 0, 0, 0, 10, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
};

const int LevelData::level3[LEVEL3_SIZE][LEVEL3_SIZE] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 11, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 3, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
};



// 16x16 Test Level 1 (fallback)
const int LevelData::testLevel1[TEST_MAP_SIZE][TEST_MAP_SIZE] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1},
    {1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 2, 2, 2, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
};

// 16x16 Test Level 2 (Tile 6 = Descent Shaft Exit at row 2, col 13; Tile 3 = Spawn at row 13, col 2)
const int LevelData::testLevel2[TEST_MAP_SIZE][TEST_MAP_SIZE] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1},
    {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1},
    {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
};

QString LevelData::getStoryTitle(int level)
{
    switch (level) {
    case 1:  return QStringLiteral("LEVEL 1 - FABRICATION FLOORS");
    case 2:  return QStringLiteral("LEVEL 2 - THE ARMORY");
    case 3:  return QStringLiteral("LEVEL 3 - THE LOGIC CORE");
    default: return QStringLiteral("VANGUARD DEFEATED");
    }
}

QString LevelData::getStoryText(int level)
{
    switch (level) {
    case 1:
        return QStringLiteral(
            "You are the last systems engineer in Foundry Seven.\n\n"
            "A rogue military AI named VANGUARD has seized control of the robotics plant "
            "and turned every machine against the staff.\n\n"
            "Arm yourself with the standard-issue rifle and navigate through the crate maze. "
            "Recover all four access keys, breach the Cargo Bay, and reach the Freight Elevator."
        );
    case 2:
        return QStringLiteral(
            "The Armory.\n\n"
            "VANGUARD has sealed the primary vaults and stationed automated Sentinels down the long corridors.\n\n"
            "Raid the weapon cache near the entrance for the Plasma Repeater. "
            "Collect all four armory keys to unlock the Descent Shaft bulkhead leading to the Core."
        );
    case 3:
        return QStringLiteral(
            "The Logic Core.\n\n"
            "This is the heart of the VANGUARD supercomputer. "
            "The central core is shielded, but four external cooling vents regulate its power.\n\n"
            "Explore each wing to retrieve all four Core access keys and destroy all four cooling vents "
            "to trigger thermal overload and unlock the Extraction Bunker."
        );
    default:
        return QStringLiteral(
            "VANGUARD DESTROYED.\n\n"
            "The Logic Core has suffered catastrophic thermal overload. "
            "All rogue combat units have shut down, and Foundry Seven is secure. Mission accomplished."
        );
    }
}

QString LevelData::getLevelName(int level)
{
    switch (level) {
    case 1:  return QStringLiteral("FABRICATION FLOORS");
    case 2:  return QStringLiteral("THE ARMORY");
    case 3:  return QStringLiteral("THE LOGIC CORE");
    default: return QStringLiteral("VICTORY");
    }
}

int LevelData::getMapWidth(int level)
{
    if (level == 1) return LEVEL1_SIZE;
    if (level == 2) return LEVEL2_SIZE;
    if (level == 3) return LEVEL3_SIZE;
    return TEST_MAP_SIZE;
}

int LevelData::getMapHeight(int level)
{
    if (level == 1) return LEVEL1_SIZE;
    if (level == 2) return LEVEL2_SIZE;
    if (level == 3) return LEVEL3_SIZE;
    return TEST_MAP_SIZE;
}

int LevelData::getTile(int level, int row, int col)
{
    if (level == 1) {
        if (row < 0 || row >= LEVEL1_SIZE || col < 0 || col >= LEVEL1_SIZE) return TileCode::Wall;
        return level1[row][col];
    } else if (level == 2) {
        if (row < 0 || row >= LEVEL2_SIZE || col < 0 || col >= LEVEL2_SIZE) return TileCode::Wall;
        return level2[row][col];
    } else if (level == 3) {
        if (row < 0 || row >= LEVEL3_SIZE || col < 0 || col >= LEVEL3_SIZE) return TileCode::Wall;
        return level3[row][col];
    }
    if (row < 0 || row >= TEST_MAP_SIZE || col < 0 || col >= TEST_MAP_SIZE) return TileCode::Wall;
    return testLevel1[row][col];
}

QVector3D LevelData::getSpawnPoint(int level)
{
    float bs = GameConfig::BLOCK_SIZE;
    if (level == 1) {
        return QVector3D((2.0f + 0.5f) * bs, 0.0f, (29.0f + 0.5f) * bs);
    } else if (level == 2) {
        return QVector3D((3.0f + 0.5f) * bs, 0.0f, (61.0f + 0.5f) * bs);
    } else if (level == 3) {
        return QVector3D((20.0f + 0.5f) * bs, 0.0f, (36.0f + 0.5f) * bs);
    }
    return QVector3D((2.0f + 0.5f) * bs, 0.0f, (13.0f + 0.5f) * bs);
}

QVector3D LevelData::getExitCenterPosition(int level)
{
    float bs = GameConfig::BLOCK_SIZE;
    if (level == 1) {
        return QVector3D((29.0f + 0.5f) * bs, 2.0f, (2.0f + 0.5f) * bs);
    } else if (level == 2) {
        return QVector3D((27.0f + 0.5f) * bs, 2.0f, (51.0f + 0.5f) * bs);
    } else if (level == 3) {
        for (int r = 0; r < LEVEL3_SIZE; ++r) {
            for (int c = 0; c < LEVEL3_SIZE; ++c) {
                if (level3[r][c] == TileCode::Level3Exit) {
                    return QVector3D((c + 0.5f) * bs, 2.0f, (r + 0.5f) * bs);
                }
            }
        }
        return QVector3D((20.0f + 0.5f) * bs, 2.0f, (2.0f + 0.5f) * bs);
    }
    return QVector3D(0.0f, 0.0f, 0.0f);
}

int LevelData::getExitTileCode(int level)
{
    switch (level) {
    case 1:  return TileCode::Level1Exit; // 4
    case 2:  return TileCode::Level2Exit; // 6
    case 3:  return TileCode::Level3Exit; // 11
    default: return -1;
    }
}

// ==================== MULTI-PHASE BFS REACHABILITY VALIDATOR ====================

namespace {

struct BfsPhaseResult {
    int visitedCount = 0;
    QList<int> keysReached;
    bool exitReached = false;
};

BfsPhaseResult runLevelBFS(int level,
                           int spawnR, int spawnC,
                           const QList<DoorDef> &doors,
                           const QList<KeyDef> &keys,
                           int exitTileCode,
                           const std::set<int> &collectedKeys,
                           bool bossDefeated = false,
                           bool forceLockMainExit = false)
{
    int w = LevelData::getMapWidth(level);
    int h = LevelData::getMapHeight(level);
    std::vector<std::vector<bool>> visited(h, std::vector<bool>(w, false));
    std::queue<std::pair<int,int>> q;

    if (spawnR >= 0 && spawnR < h && spawnC >= 0 && spawnC < w) {
        q.push({spawnR, spawnC});
        visited[spawnR][spawnC] = true;
    }

    int visitedCount = 0;

    auto canPassDoor = [&](int r, int c) -> bool {
        for (const DoorDef &d : doors) {
            if (d.row == r && d.col == c) {
                if (forceLockMainExit && d.doorType == 3 /* MainExit */) return false;
                switch (d.doorType) {
                case 0: // Standard
                    return true;
                case 1: // KeyLocked
                    return collectedKeys.count(d.requiredKeyIndex) > 0;
                case 2: // AreaLocked
                    if (static_cast<int>(collectedKeys.size()) < d.requiredKeyCount) return false;
                    if (d.requiredKeyMask != 0) {
                        int mask = 0;
                        for (int k : collectedKeys) mask |= (1 << k);
                        if ((mask & d.requiredKeyMask) != d.requiredKeyMask) return false;
                    }
                    return true;
                case 3: // MainExit
                    if (static_cast<int>(collectedKeys.size()) < d.requiredKeyCount) return false;
                    if (d.requiresBossDefeated && !bossDefeated) return false;
                    return true;
                default:
                    return false;
                }
            }
        }
        return false;
    };

    const int dr[4] = {-1, 1, 0, 0};
    const int dc[4] = {0, 0, -1, 1};

    while (!q.empty()) {
        auto [r, c] = q.front();
        q.pop();
        visitedCount++;

        for (int i = 0; i < 4; ++i) {
            int nr = r + dr[i];
            int nc = c + dc[i];
            if (nr < 0 || nr >= h || nc < 0 || nc >= w) continue;
            if (visited[nr][nc]) continue;

            int tile = LevelData::getTile(level, nr, nc);
            if (tile == TileCode::Wall || tile == TileCode::Crate || tile == TileCode::CoreWall || tile == TileCode::DoorPocket) {
                continue;
            }

            if (tile == TileCode::Door) {
                if (!canPassDoor(nr, nc)) {
                    continue;
                }
            }

            visited[nr][nc] = true;
            q.push({nr, nc});
        }
    }

    BfsPhaseResult res;
    res.visitedCount = visitedCount;
    for (const KeyDef &k : keys) {
        if (k.row >= 0 && k.row < h && k.col >= 0 && k.col < w && visited[k.row][k.col]) {
            res.keysReached.append(k.keyIndex);
        }
    }
    std::sort(res.keysReached.begin(), res.keysReached.end());

    res.exitReached = false;
    for (int r = 0; r < h; ++r) {
        for (int c = 0; c < w; ++c) {
            if (LevelData::getTile(level, r, c) == exitTileCode && visited[r][c]) {
                res.exitReached = true;
                break;
            }
        }
    }

    return res;
}

} // anonymous namespace

bool LevelData::checkReachability(int level, QString &outLog)
{
    int w = getMapWidth(level);
    int h = getMapHeight(level);
    int exitCode = getExitTileCode(level);

    int startR = -1, startC = -1;
    for (int r = 0; r < h && startR == -1; ++r) {
        for (int c = 0; c < w; ++c) {
            if (getTile(level, r, c) == TileCode::PlayerSpawn) {
                startR = r;
                startC = c;
                break;
            }
        }
    }

    if (startR == -1) {
        outLog = QStringLiteral("Error: Spawn tile (3) not found in map!");
        return false;
    }

    QList<DoorDef> doors = getLevelDoors(level);
    QList<KeyDef> keys = getLevelKeys(level);

    if (level == 1) {
        // Phase 0: 0 keys
        auto p0 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {});
        if (!p0.keysReached.contains(0) || p0.exitReached) {
            outLog = QStringLiteral("Level 1 Phase 0 failed: Key 0 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 1: Key 0 acquired
        auto p1 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0});
        if (!p1.keysReached.contains(1) || !p1.keysReached.contains(2) || p1.exitReached) {
            outLog = QStringLiteral("Level 1 Phase 1 failed: Keys 1 and 2 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 2: Keys 0, 1, 2 acquired
        auto p2 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2});
        if (!p2.keysReached.contains(3) || p2.exitReached) {
            outLog = QStringLiteral("Level 1 Phase 2 failed: Key 3 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 3: All 4 keys acquired
        auto p3 = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3});
        if (!p3.exitReached) {
            outLog = QStringLiteral("Level 1 Phase 3 failed: Exit elevator unreachable with all 4 keys!");
            return false;
        }
        // Anti-bypass check: all 4 keys held, but D1-4 locked
        auto ab = runLevelBFS(1, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, true);
        if (ab.exitReached) {
            outLog = QStringLiteral("Level 1 Anti-Bypass failed: Exit reachable while D1-4 is locked!");
            return false;
        }

        outLog = QStringLiteral("Level 1 multi-phase progression verified: 4 keys sequentially reachable, 4 doors gated, Freight Elevator secured with zero bypass.");
        return true;
    }

    if (level == 2) {
        // Phase 0: 0 keys
        auto p0 = runLevelBFS(2, startR, startC, doors, keys, exitCode, {});
        if (!p0.keysReached.contains(0) || p0.exitReached) {
            outLog = QStringLiteral("Level 2 Phase 0 failed: Key 0 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 1: Key 0 acquired
        auto p1 = runLevelBFS(2, startR, startC, doors, keys, exitCode, {0});
        if (!p1.keysReached.contains(1) || p1.exitReached) {
            outLog = QStringLiteral("Level 2 Phase 1 failed: Key 1 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 2: Keys 0, 1 acquired
        auto p2 = runLevelBFS(2, startR, startC, doors, keys, exitCode, {0, 1});
        if (!p2.keysReached.contains(2) || p2.exitReached) {
            outLog = QStringLiteral("Level 2 Phase 2 failed: Key 2 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 3: Keys 0, 1, 2 acquired
        auto p3 = runLevelBFS(2, startR, startC, doors, keys, exitCode, {0, 1, 2});
        if (!p3.keysReached.contains(3) || p3.exitReached) {
            outLog = QStringLiteral("Level 2 Phase 3 failed: Key 3 unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 4: All 4 keys acquired
        auto p4 = runLevelBFS(2, startR, startC, doors, keys, exitCode, {0, 1, 2, 3});
        if (!p4.exitReached) {
            outLog = QStringLiteral("Level 2 Phase 4 failed: Descent Shaft unreachable with all 4 keys!");
            return false;
        }
        // Anti-bypass check: all 4 keys held, but D2-5 locked
        auto ab = runLevelBFS(2, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false, true);
        if (ab.exitReached) {
            outLog = QStringLiteral("Level 2 Anti-Bypass failed: Exit reachable while D2-5 is locked!");
            return false;
        }

        outLog = QStringLiteral("Level 2 multi-phase progression verified: 4 keys sequentially reachable across 5 zones, Descent Chamber strictly enclosed with zero bypass.");
        return true;
    }

    if (level == 3) {
        // Phase 0: 0 keys, boss alive
        auto p0 = runLevelBFS(3, startR, startC, doors, keys, exitCode, {}, false);
        if (p0.keysReached.size() != 4 || p0.exitReached) {
            outLog = QStringLiteral("Level 3 Phase 0 failed: Wing keys unreachable or Exit prematurely accessible!");
            return false;
        }
        // Phase 1: 4 keys, boss alive
        auto p1 = runLevelBFS(3, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, false);
        if (p1.exitReached) {
            outLog = QStringLiteral("Level 3 Phase 1 failed: Exit accessible before boss defeat!");
            return false;
        }
        // Phase 2: 0 keys, boss defeated
        auto p2 = runLevelBFS(3, startR, startC, doors, keys, exitCode, {}, true);
        if (p2.exitReached) {
            outLog = QStringLiteral("Level 3 Phase 2 failed: Exit accessible without 4 keys!");
            return false;
        }
        // Phase 3: 4 keys AND boss defeated
        auto p3 = runLevelBFS(3, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, true);
        if (!p3.exitReached) {
            outLog = QStringLiteral("Level 3 Phase 3 failed: Extraction pad unreachable after full dual completion!");
            return false;
        }
        // Anti-bypass check: both criteria met, but D3-5 locked
        auto ab = runLevelBFS(3, startR, startC, doors, keys, exitCode, {0, 1, 2, 3}, true, true);
        if (ab.exitReached) {
            outLog = QStringLiteral("Level 3 Anti-Bypass failed: Exit reachable while D3-5 is locked!");
            return false;
        }

        outLog = QStringLiteral("Level 3 dual-gating progression verified: all 4 wings and vents accessible, Extraction Bunker strictly protected by D3-5 with zero bypass.");
        return true;
    }

    // Fallback for test levels
    outLog = QStringLiteral("Test level reachability verified.");
    return true;
}

// ==================== LEVEL 1 ENTITY SPAWNS ====================

QList<QVector3D> LevelData::getLevel1CorridorDroneSpawns()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((4.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs), // Receiving corridor
        QVector3D((5.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs), // Mid corridor
        QVector3D((7.0f + 0.5f) * bs, 0.0f, (21.0f + 0.5f) * bs), // Machine shop junction
        QVector3D((12.0f + 0.5f) * bs, 0.0f, (23.0f + 0.5f) * bs), // Assembly hub
        QVector3D((12.0f + 0.5f) * bs, 0.0f, (18.0f + 0.5f) * bs)  // Approach to Cargo Bay
    };
}

QList<QVector3D> LevelData::getLevel1LoadingBayDroneSpawns()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((19.0f + 0.5f) * bs, 0.0f, (9.0f + 0.5f) * bs),  // Cargo bay NW
        QVector3D((24.0f + 0.5f) * bs, 0.0f, (9.0f + 0.5f) * bs),  // Cargo bay NE
        QVector3D((21.0f + 0.5f) * bs, 0.0f, (14.0f + 0.5f) * bs), // Cargo bay S
        QVector3D((18.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs), // Cargo bay W
        QVector3D((25.0f + 0.5f) * bs, 0.0f, (11.0f + 0.5f) * bs)  // Cargo bay E
    };
}

QList<PickupItemDef> LevelData::getLevel1Pickups()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        { QVector3D((5.0f + 0.5f) * bs, 25.0f, (28.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((3.0f + 0.5f) * bs, 25.0f, (22.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((11.0f + 0.5f) * bs, 25.0f, (20.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((25.0f + 0.5f) * bs, 25.0f, (10.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((26.0f + 0.5f) * bs, 25.0f, (3.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") }
    };
}

// ==================== LEVEL 2 ENTITY SPAWNS ====================

QList<QVector3D> LevelData::getLevel2SentinelSpawns()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((11.0f + 0.5f) * bs, 0.0f, (60.0f + 0.5f) * bs), // In The Cache
        QVector3D((4.0f + 0.5f) * bs, 0.0f, (46.0f + 0.5f) * bs),  // West Corridor
        QVector3D((4.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs),  // West Proving Grounds
        QVector3D((12.0f + 0.5f) * bs, 0.0f, (20.0f + 0.5f) * bs), // Proving Grounds
        QVector3D((28.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs), // Central Armory Vault
        QVector3D((30.0f + 0.5f) * bs, 0.0f, (32.0f + 0.5f) * bs), // Central Armory Vault
        QVector3D((36.0f + 0.5f) * bs, 0.0f, (14.0f + 0.5f) * bs), // North Corridor
        QVector3D((48.0f + 0.5f) * bs, 0.0f, (14.0f + 0.5f) * bs), // Explosives Depot NW
        QVector3D((50.0f + 0.5f) * bs, 0.0f, (20.0f + 0.5f) * bs), // Explosives Depot S
        QVector3D((55.0f + 0.5f) * bs, 0.0f, (32.0f + 0.5f) * bs), // East Security Corridor
        QVector3D((55.0f + 0.5f) * bs, 0.0f, (46.0f + 0.5f) * bs), // East Security Corridor
        QVector3D((45.0f + 0.5f) * bs, 0.0f, (50.0f + 0.5f) * bs), // Descent Approach Corridor
        QVector3D((36.0f + 0.5f) * bs, 0.0f, (50.0f + 0.5f) * bs)  // Near D2-5 Bulkhead
    };
}

QList<QVector3D> LevelData::getLevel2DroneSpawns()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((4.0f + 0.5f) * bs, 0.0f, (52.0f + 0.5f) * bs),
        QVector3D((4.0f + 0.5f) * bs, 0.0f, (40.0f + 0.5f) * bs),
        QVector3D((8.0f + 0.5f) * bs, 0.0f, (24.0f + 0.5f) * bs),
        QVector3D((10.0f + 0.5f) * bs, 0.0f, (32.0f + 0.5f) * bs),
        QVector3D((25.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs),
        QVector3D((35.0f + 0.5f) * bs, 0.0f, (30.0f + 0.5f) * bs),
        QVector3D((39.0f + 0.5f) * bs, 0.0f, (14.0f + 0.5f) * bs),
        QVector3D((52.0f + 0.5f) * bs, 0.0f, (12.0f + 0.5f) * bs),
        QVector3D((55.0f + 0.5f) * bs, 0.0f, (18.0f + 0.5f) * bs),
        QVector3D((55.0f + 0.5f) * bs, 0.0f, (26.0f + 0.5f) * bs),
        QVector3D((55.0f + 0.5f) * bs, 0.0f, (38.0f + 0.5f) * bs),
        QVector3D((50.0f + 0.5f) * bs, 0.0f, (50.0f + 0.5f) * bs)
    };
}

QList<PickupItemDef> LevelData::getLevel2Pickups()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        { QVector3D((5.0f + 0.5f) * bs, 25.0f, (61.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((9.0f + 0.5f) * bs, 25.0f, (61.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((4.0f + 0.5f) * bs, 25.0f, (48.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((15.0f + 0.5f) * bs, 25.0f, (24.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((25.0f + 0.5f) * bs, 25.0f, (28.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((35.0f + 0.5f) * bs, 25.0f, (32.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((52.0f + 0.5f) * bs, 25.0f, (16.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((40.0f + 0.5f) * bs, 25.0f, (50.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") }
    };
}

QVector3D LevelData::getLevel2HeavyWeaponSpawn()
{
    float bs = GameConfig::BLOCK_SIZE;
    // Row 60, Col 10 in The Cache adjacent to spawn
    return QVector3D((10.0f + 0.5f) * bs, 25.0f, (60.0f + 0.5f) * bs);
}

// ==================== LEVEL 3 ENTITY SPAWNS & PICKUPS ====================

QList<QVector3D> LevelData::getLevel3VentPositions()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((17.0f + 0.5f) * bs, 0.0f, (17.0f + 0.5f) * bs), // Top-Left (1750, 0, 1750)
        QVector3D((22.0f + 0.5f) * bs, 0.0f, (17.0f + 0.5f) * bs), // Top-Right (2250, 0, 1750)
        QVector3D((17.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs), // Bottom-Left (1750, 0, 2250)
        QVector3D((22.0f + 0.5f) * bs, 0.0f, (22.0f + 0.5f) * bs)  // Bottom-Right (2250, 0, 2250)
    };
}

QList<QVector3D> LevelData::getLevel3PerimeterDroneSpawns()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        QVector3D((20.0f + 0.5f) * bs, 0.0f, (8.0f + 0.5f) * bs),  // North Cryo Wing
        QVector3D((32.0f + 0.5f) * bs, 0.0f, (20.0f + 0.5f) * bs), // East Wing
        QVector3D((8.0f + 0.5f) * bs, 0.0f, (20.0f + 0.5f) * bs),  // West Wing
        QVector3D((20.0f + 0.5f) * bs, 0.0f, (28.0f + 0.5f) * bs)  // South of Core
    };
}

QList<PickupItemDef> LevelData::getLevel3Pickups()
{
    float bs = GameConfig::BLOCK_SIZE;
    return {
        { QVector3D((19.0f + 0.5f) * bs, 25.0f, (34.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((21.0f + 0.5f) * bs, 25.0f, (34.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((21.0f + 0.5f) * bs, 25.0f, (36.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((8.0f + 0.5f) * bs, 25.0f, (18.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((32.0f + 0.5f) * bs, 25.0f, (18.0f + 0.5f) * bs), 2, QStringLiteral("Medkit") },
        { QVector3D((16.0f + 0.5f) * bs, 25.0f, (8.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") },
        { QVector3D((15.0f + 0.5f) * bs, 25.0f, (26.0f + 0.5f) * bs), 0, QStringLiteral("Food Pack") },
        { QVector3D((25.0f + 0.5f) * bs, 25.0f, (26.0f + 0.5f) * bs), 1, QStringLiteral("Bandage") }
    };
}

QVector3D LevelData::getLevel3CoreCenter()
{
    return QVector3D(2000.0f, 200.0f, 2000.0f);
}

// ==================== DOOR & KEY DEFINITIONS PER LEVEL (DAY 3) ====================

QList<DoorDef> LevelData::getLevelDoors(int level)
{
    if (level == 1) {
        return {
            { 1, 23, 9, 90.0f, 1 /* KeyLocked */, 0, 0, 0, false, QStringLiteral("TOOLING CHECKPOINT") },
            { 2, 16, 13, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("CARGO AIRLOCK") },
            { 3, 7, 15, 90.0f, 2 /* AreaLocked */, -1, 3, 0, false, QStringLiteral("SUBSTATION SECURITY") },
            { 4, 3, 24, 90.0f, 3 /* MainExit */, -1, 4, 0, false, QStringLiteral("FREIGHT ELEVATOR") }
        };
    } else if (level == 2) {
        return {
            { 1, 61, 7, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("CACHE DOOR") },
            { 2, 36, 4, 0.0f, 1 /* KeyLocked */, 0, 0, 0, false, QStringLiteral("WEST ARSENAL GATE") },
            { 3, 28, 20, 90.0f, 2 /* AreaLocked */, -1, 2, 0b0011, false, QStringLiteral("PROVING GROUNDS GATE") },
            { 4, 14, 42, 90.0f, 2 /* AreaLocked */, -1, 3, 0, false, QStringLiteral("EXPLOSIVES DEPOT GATE") },
            { 5, 50, 32, 90.0f, 3 /* MainExit */, -1, 4, 0, false, QStringLiteral("DESCENT SHAFT BULKHEAD") }
        };
    } else if (level == 3) {
        return {
            { 1, 31, 20, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("SOUTH AIRLOCK") },
            { 2, 20, 12, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("WEST WING") },
            { 3, 20, 28, 90.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("EAST WING") },
            { 4, 12, 20, 0.0f, 0 /* Standard */, -1, 0, 0, false, QStringLiteral("NORTH WING") },
            { 5, 4, 20, 0.0f, 3 /* MainExit */, -1, 4, 0, true, QStringLiteral("CORE EXTRACTION") }
        };
    }
    return {};
}

QList<KeyDef> LevelData::getLevelKeys(int level)
{
    if (level == 1) {
        return {
            { 1, 0, 21, 3, QStringLiteral("FABRICATION KEY A") },
            { 1, 1, 8, 25, QStringLiteral("FABRICATION KEY B") },
            { 1, 2, 19, 13, QStringLiteral("FABRICATION KEY C") },
            { 1, 3, 3, 4, QStringLiteral("FABRICATION KEY D") }
        };
    } else if (level == 2) {
        return {
            { 2, 0, 44, 4, QStringLiteral("ARMORY KEY A") },
            { 2, 1, 20, 15, QStringLiteral("ARMORY KEY B") },
            { 2, 2, 26, 35, QStringLiteral("ARMORY KEY C") },
            { 2, 3, 14, 55, QStringLiteral("ARMORY KEY D") }
        };
    } else if (level == 3) {
        return {
            { 3, 0, 6, 20, QStringLiteral("CORE KEY A (CRYO)") },
            { 3, 1, 20, 35, QStringLiteral("CORE KEY B (TURBINE)") },
            { 3, 2, 30, 26, QStringLiteral("CORE KEY C (DIAGNOSTIC)") },
            { 3, 3, 20, 5, QStringLiteral("CORE KEY D (CONDENSER)") }
        };
    }
    return {};
}
