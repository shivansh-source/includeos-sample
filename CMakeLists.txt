cmake_minimum_required(VERSION 3.16)
project(includeos-sample)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the executable
add_executable(includeos-sample src/main.cpp)

# Link IncludeOS libraries
target_include_directories(includeos-sample PRIVATE ${INCLUDEOS_PATH}/include)