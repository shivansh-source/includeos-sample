
cmake_minimum_required(VERSION 3.31.6)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

project(includeos_http_server)

find_package(IncludeOS)
include(os)

set(SOURCES
  src/main.cpp
)

os_add_executable(includeos_http_server "IncludeOS HTTP server" ${SOURCES})
os_add_drivers(includeos_http_server virtionet)
os_add_stdout(includeos_http_server default_stdout)
