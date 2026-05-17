FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN rm -rf build && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make

# ADD LABELS FOR URUNC
LABEL "com.urunc.unikernel.binary"=/app/build/includeos-http-server
LABEL "com.urunc.unikernel.unikernelType"=includeos
LABEL "com.urunc.unikernel.hypervisor"=qemu

ENTRYPOINT ["/app/build/includeos-http-server"]
