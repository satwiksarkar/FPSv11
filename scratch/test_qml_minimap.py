
import os, subprocess

env = os.environ.copy()
qt_bin = r'C:\Qt.11.1\mingw_64in'
mingw_bin = r'C:\Qt\Tools\mingw1310_64in'
env['PATH'] = qt_bin + ';' + mingw_bin + ';' + env.get('PATH', '')
env['QT_LOGGING_RULES'] = 'qt.qml.*=true'

exe = r'build\Desktop_Qt_6_11_1_MinGW_64_bit_Debug\FPSLabGame.exe'
p = subprocess.Popen([exe], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
try:
    stdout, stderr = p.communicate(timeout=3)
except subprocess.TimeoutExpired:
    p.kill()
    stdout, stderr = p.communicate()

print('STDERR:')
for line in stderr.splitlines():
    if 'Minimap' in line or 'TypeError' in line or 'charCodeAt' in line or 'Canvas' in line or 'qml' in line:
        print(line)
