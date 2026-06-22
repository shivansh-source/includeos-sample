#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-shivansh1111/includeos-http-server:latest}"
KERNEL="${KERNEL:-build/includeos-http-server}"

if [ ! -f "${KERNEL}" ]; then
  echo "Missing ${KERNEL}."
  echo "Build a real IncludeOS QEMU kernel first, then rerun this script."
  echo "Do not use the Ubuntu Dockerfile output for urunc testing."
  exit 1
fi

if command -v file >/dev/null 2>&1; then
  file "${KERNEL}"
fi

DOCKER_BUILDKIT=1 docker build -f bunnyfile -t "${IMAGE}" .

echo "Built ${IMAGE} with bunnyfile."
echo "Verify metadata with: docker inspect ${IMAGE}"
