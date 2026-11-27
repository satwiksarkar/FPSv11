@echo off
set "PATH=C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.11.1\mingw_64\bin;C:\Qt\Tools\CMake_64\bin;%PATH%"
cmake.exe --build build/Desktop_Qt_6_11_1_MinGW_64_bit_Debug --target FPSLabGame
