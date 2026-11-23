import os
import subprocess
import sys

qt_path = r"C:\Qt\6.11.1\mingw_64\bin"
tools_path = r"C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin"
env = os.environ.copy()
env["PATH"] = f"{tools_path};{qt_path};" + env.get("PATH", "")

build_dir = r"build/Desktop_Qt_6_11_1_MinGW_64_bit_Debug"

cmd = ["ninja", "-C", build_dir]
print("Running:", " ".join(cmd))
res = subprocess.run(cmd, env=env, capture_output=True, text=True)
print("STDOUT:")
print(res.stdout)
print("STDERR:")
print(res.stderr)
print("Exit code:", res.returncode)
sys.exit(res.returncode)
