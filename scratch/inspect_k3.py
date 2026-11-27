# scratch/inspect_k3.py
import re

with open("src/LevelData.cpp", "r") as f:
    text = f.read()

match = re.search(r"const int LevelData::level1_v1\[48\]\[48\] = \{([\s\S]*?)\};", text)
if not match:
    print("Could not find level1_v1")
    exit(1)

rows_text = match.group(1).strip().split("},")
matrix = []
for r in rows_text:
    nums = [int(x.strip()) for x in re.findall(r"\d+", r)]
    if len(nums) == 48:
        matrix.append(nums)

print(f"Matrix parsed: {len(matrix)} rows x {len(matrix[0])} cols")
print("\n--- Key 3 Room (rows 5..18, cols 4..18) ---")
header = "    " + " ".join(f"{c:2d}" for c in range(4, 18))
print(header)
for r in range(5, 19):
    row_str = f"{r:2d}: " + " ".join(f"{matrix[r][c]:2d}" for c in range(4, 18))
    print(row_str)

# Find all doors in Level 1
door_match = re.search(r"QList<DoorDef> LevelData::getLevelDoors\(int level, int variant\)[\s\S]*?case 1:[\s\S]*?return \{([\s\S]*?)\};", text)
if door_match:
    print("\n--- Level 1 Doors ---")
    doors_text = door_match.group(1)
    for line in doors_text.strip().split("\n"):
        line = line.strip()
        if line.startswith("{"):
            print(line)

# Find all barriers in PuzzleManager
with open("src/PuzzleManager.cpp", "r") as f:
    pm_text = f.read()

print("\n--- PuzzleManager Barrier Positions ---")
for line in pm_text.split("\n"):
    if "Barrier" in line or "isPositionBlockedByBarrier" in line or "isBarrierBlocking" in line:
        print(line)

print("\n--- Key 3 in LevelView.qml ---")
with open("qml/LevelView.qml", "r") as f:
    lv_lines = f.readlines()
for i, l in enumerate(lv_lines):
    if any(k in l.lower() for k in ["key 3", "sentinel patrol", "pedestal", "laser cage", "laser"]):
        print(f"{i+1}: {l.strip()}")

print("\n--- Rows 0..8, Cols 0..25 ---")
header = "    " + " ".join(f"{c:2d}" for c in range(0, 26))
print(header)
for r in range(0, 9):
    row_str = f"{r:2d}: " + " ".join(f"{matrix[r][c]:2d}" for c in range(0, 26))
    print(row_str)

print("\n--- Rows 5..15, Cols 10..25 ---")
header = "    " + " ".join(f"{c:2d}" for c in range(10, 26))
print(header)
for r in range(5, 16):
    row_str = f"{r:2d}: " + " ".join(f"{matrix[r][c]:2d}" for c in range(10, 26))
    print(row_str)
