#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE=${IMAGE:-docker.io/shivansh1111/includeos-http-server:latest}
CONTAINER_NAME=${CONTAINER_NAME:-includeos-http-server-nettest}
NAMESPACE=${NAMESPACE:-k8s.io}
RUNTIME=${RUNTIME:-io.containerd.urunc.v2}
PORT=${PORT:-8080}
STARTUP_TIMEOUT=${STARTUP_TIMEOUT:-30}
CLIENT_IMAGE=${CLIENT_IMAGE:-docker.io/curlimages/curl:8.8.0}
SUDO=${SUDO:-sudo}

cleanup() {
    if command -v nerdctl >/dev/null 2>&1; then
        ${SUDO} nerdctl -n "${NAMESPACE}" rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi
    if command -v docker >/dev/null 2>&1; then
        ${SUDO} docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command '$1' was not found" >&2
        exit 1
    fi
}

http_get() {
    local url=$1

    if command -v curl >/dev/null 2>&1; then
        curl --fail --silent --show-error --max-time 5 "${url}"
        return
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout=5 "${url}"
        return
    fi

    require_command nerdctl
    ${SUDO} nerdctl -n "${NAMESPACE}" run --rm "${CLIENT_IMAGE}" \
        --fail --silent --show-error --max-time 5 "${url}"
}

wait_for_ip() {
    local ip=""
    for _ in $(seq 1 "${STARTUP_TIMEOUT}"); do
        ip=$(${SUDO} nerdctl -n "${NAMESPACE}" inspect \
            -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
            "${CONTAINER_NAME}" 2>/dev/null || true)
        if [[ -n "${ip}" && "${ip}" != "<no value>" ]]; then
            echo "${ip}"
            return 0
        fi
        sleep 1
    done

    echo "error: timed out waiting for ${CONTAINER_NAME} to receive a CNI IP" >&2
    return 1
}

wait_for_http() {
    local url=$1
    local body=""

    for _ in $(seq 1 "${STARTUP_TIMEOUT}"); do
        body=$(http_get "${url}" 2>/dev/null || true)
        if [[ "${body}" == "Hello, world!" ]]; then
            echo "${body}"
            return 0
        fi
        sleep 1
    done

    echo "error: timed out waiting for ${url} to return 'Hello, world!'" >&2
    return 1
}

main() {
    require_command nerdctl

    echo "=== Testing IncludeOS HTTP Server Networking ==="
    echo "Image:      ${IMAGE}"
    echo "Namespace:  ${NAMESPACE}"
    echo "Runtime:    ${RUNTIME}"
    echo "Container:  ${CONTAINER_NAME}"
    echo

    cleanup

    if command -v docker >/dev/null 2>&1 && ! ${SUDO} nerdctl -n "${NAMESPACE}" image inspect "${IMAGE}" >/dev/null 2>&1; then
        echo "1. Importing Docker image into containerd namespace ${NAMESPACE}..."
        docker save "${IMAGE}" | ${SUDO} nerdctl -n "${NAMESPACE}" load
    else
        echo "1. Image already available to nerdctl/containerd, or Docker is unavailable; skipping import."
    fi

    echo "2. Starting IncludeOS HTTP server with urunc..."
    ${SUDO} nerdctl -n "${NAMESPACE}" run -d \
        --name "${CONTAINER_NAME}" \
        --runtime "${RUNTIME}" \
        "${IMAGE}" >/dev/null

    echo "3. Waiting for CNI IP address..."
    SERVER_IP=$(wait_for_ip)
    echo "   Server IP: ${SERVER_IP}"

    echo "4. Waiting for HTTP response..."
    RESPONSE=$(wait_for_http "http://${SERVER_IP}:${PORT}")
    echo "   Response: ${RESPONSE}"

    echo "5. Server logs:"
    ${SUDO} nerdctl -n "${NAMESPACE}" logs "${CONTAINER_NAME}" || true

    echo
    echo "=== Networking test passed ==="
}

main "$@"
