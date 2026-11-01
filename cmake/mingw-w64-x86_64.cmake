# Cross-compile the Windows utility with MinGW-w64 on Linux.
#
#   cmake -S . -B cmake-build-mingw -G Ninja \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
#   cmake --build cmake-build-mingw --parallel
#
# The POSIX thread model is required for std::thread. The unsuffixed
# x86_64-w64-mingw32-g++ alternative on Ubuntu defaults to the win32 model.
#
# CMAKE_CROSSCOMPILING stays enabled. The project install() rule skips
# RUNTIME_DEPENDENCIES when cross-compiling so cmake --install does not ask
# the Linux host resolver to scan a Windows PE.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc-posix)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++-posix)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)
