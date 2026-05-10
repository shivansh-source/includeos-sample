# includeos-sample

A simple application template for [IncludeOS](https://github.com/includeos/IncludeOS) unikernel.

## Requirements

* [IncludeOS Compiler Toolchain](https://github.com/includeos/IncludeOS)
* [CMake](https://cmake.org/) (3.16+)
* [QEMU](https://www.qemu.org/) or [Solo5](https://github.com/Solo5/solo5) for running the application
* [Docker](https://www.docker.com/) for building the container image

## Usage

### Build the IncludeOS Application Locally

```bash
# Create build directory
mkdir -p build
cd build

# Configure with CMake
cmake ..

# Build the application
make