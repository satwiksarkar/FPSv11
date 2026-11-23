import os
import subprocess
import sys

qt_path = r"C:\Qt\6.11.1\mingw_64\bin"
tools_path = r"C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin"
env = os.environ.copy()
env["PATH"] = f"{tools_path};{qt_path};" + env.get("PATH", "")

build_dir = r"build/Desktop_Qt_6_11_1_MinGW_64_bit_Debug"
test_cpp = r"C:\Users\HP\.gemini\antigravity\brain\379ff316-6967-455f-8e3f-4390eb1a06af\scratch\test_puzzles_regression.cpp"
test_exe = r"C:\Users\HP\.gemini\antigravity\brain\379ff316-6967-455f-8e3f-4390eb1a06af\scratch\test_puzzles_regression.exe"

obj_dir = os.path.join(build_dir, "CMakeFiles", "FPSLabGame.dir")
objs = []
for root, dirs, files in os.walk(obj_dir):
    for f in files:
        if f.endswith(".obj") and f != "main.cpp.obj":
            objs.append(os.path.join(root, f))

compile_cmd = [
    r"C:\Qt\Tools\mingw1310_64\bin\g++.exe",
    "-g", "-std=gnu++17",
    "-I" + os.path.join(build_dir, "FPSLabGame_autogen/include"),
    "-I.",
    "-Isrc",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtQml",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtCore",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtQuick",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtGui",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtQuick3D",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtQuick3DRuntimeRender",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtQuick3DUtils",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtNetwork",
    "-isystem", r"C:/Qt/6.11.1/mingw_64/include/QtMultimedia",
    test_cpp,
    "-o", test_exe
] + objs + [
    "-L" + r"C:\Qt\6.11.1\mingw_64\lib",
    "-lQt6Core",
    "-lQt6Gui",
    "-lQt6Qml",
    "-lQt6Quick",
    "-lQt6Quick3D",
    "-lQt6Quick3DRuntimeRender",
    "-lQt6Quick3DUtils",
    "-lQt6Network",
    "-lQt6Multimedia"
]

print("Compiling test executable with all project object files...")
comp_res = subprocess.run(compile_cmd, env=env, capture_output=True, text=True)
if comp_res.returncode != 0:
    print("Compilation failed:")
    print(comp_res.stderr)
    sys.exit(comp_res.returncode)

print("Running test executable...")
run_res = subprocess.run([test_exe], env=env, capture_output=True, text=True)
print(run_res.stdout)
if run_res.stderr:
    print("STDERR:")
    print(run_res.stderr)

sys.exit(run_res.returncode)
