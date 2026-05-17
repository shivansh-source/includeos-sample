cmake_minimum_required(VERSION 3.10)
project(includeos-http-server)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(includeos-http-server src/main.cpp)
