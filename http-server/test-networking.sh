#!/bin/bash

echo "=== Testing IncludeOS HTTP Server Networking ==="

# Load image into containerd
echo "1. Loading Docker image into containerd..."
docker save shivansh1111/includeos-http-server:latest | sudo ctr -n k8s.io images import -

# Start HTTP server container in background
echo "2. Starting HTTP server (urunc QEMU)..."
sudo ctr -n k8s.io run -d --runtime io.containerd.urunc.v2 docker.io/shivansh1111/includeos-http-server:latest server_test &
sleep 3

# Get container IP
echo "3. Getting container IP..."
SERVER_IP=$(sudo ctr -n k8s.io task ls | grep server_test | awk '{print $3}')
echo "   Server IP: $SERVER_IP"

# Test with side container (busybox with curl)
echo "4. Testing HTTP connectivity from side container..."
sudo ctr -n k8s.io run --rm docker.io/library/busybox:latest side_test sh -c "wget -O - http://$SERVER_IP:8080 2>/dev/null"

# Cleanup
echo "5. Cleaning up..."
sudo ctr -n k8s.io task kill server_test
sudo ctr -n k8s.io container rm server_test

echo "=== Test Complete ==="
