# includeos-sample

A small sample repository for validating IncludeOS support in the `urunc` runtime.  The repository contains:

* `src/main.cpp` - a minimal "Hello, world!" smoke-test binary.
* `http-server/` - a TCP/HTTP sample that listens on port `8080` and returns `Hello, world!`.

## Requirements

* IncludeOS compiler/toolchain or a compatible C++ toolchain for local smoke builds.
* [CMake](https://cmake.org/) 3.16+ for the root smoke-test sample.
* [QEMU](https://www.qemu.org/) and `containerd-shim-urunc-v2` for the urunc/QEMU path.
* Docker, containerd, CNI plugins, and `nerdctl` for the networking test.

## Build the root smoke-test sample locally

```bash
mkdir -p build
cd build
cmake ..
make
./includeos-sample
```

Expected output:

```text
Hello, world!
```

## Build the HTTP server image

```bash
docker build -t shivansh1111/includeos-http-server:latest http-server
```

The `http-server/Dockerfile` adds the urunc labels required by the IncludeOS implementation:

* `com.urunc.unikernel.binary=/app/build/includeos-http-server`
* `com.urunc.unikernel.unikernelType=includeos`
* `com.urunc.unikernel.hypervisor=qemu`

## Run the HTTP server with urunc

A boot-only check verifies that urunc can start the IncludeOS sample:

```bash
docker save shivansh1111/includeos-http-server:latest | sudo ctr -n k8s.io images import -
sudo ctr -n k8s.io run --rm --runtime io.containerd.urunc.v2 \
  docker.io/shivansh1111/includeos-http-server:latest includeos_http_boot
```

Expected log line:

```text
HTTP Server listening on 0.0.0.0:8080...
```

## Networking test

Use `nerdctl` rather than plain `ctr` for the end-to-end networking test.  `nerdctl` applies the containerd CNI configuration and exposes the assigned container IP through `nerdctl inspect`; `ctr task ls` does not contain the container IP address.

```bash
cd http-server
IMAGE=docker.io/shivansh1111/includeos-http-server:latest ./test-networking.sh
```

The script:

1. Optionally imports the Docker image into the `k8s.io` containerd namespace.
2. Starts the sample with `--runtime io.containerd.urunc.v2`.
3. Reads the CNI IP using `nerdctl inspect`.
4. Sends an HTTP request to `http://<container-ip>:8080`.
5. Passes only when the response body is exactly `Hello, world!`.

Useful overrides:

```bash
NAMESPACE=default \
RUNTIME=io.containerd.urunc.v2 \
CONTAINER_NAME=includeos-http-server-nettest \
STARTUP_TIMEOUT=60 \
./test-networking.sh
```

## Troubleshooting networking

* If the script times out waiting for an IP, verify CNI plugins are installed and containerd can create ordinary networked containers with `sudo nerdctl -n k8s.io run --rm alpine ip addr`.
* If the container gets an IP but HTTP times out, check `sudo nerdctl -n k8s.io logs includeos-http-server-nettest` and confirm the server printed `HTTP Server listening on 0.0.0.0:8080...`.
* If you use `ctr` directly, treat it as a boot/log smoke test. For IP discovery and HTTP checks, use `nerdctl` or Kubernetes because they provide the networking and inspection flow needed for CNI-based tests.
