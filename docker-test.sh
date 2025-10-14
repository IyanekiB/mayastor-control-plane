#!/bin/bash
# Docker diagnostic script

echo "=== Docker Diagnostic ==="
echo ""

echo "1. Docker version:"
docker version
echo ""

echo "2. Docker info:"
docker info 2>&1 | head -20
echo ""

echo "3. Docker socket permissions:"
ls -la /var/run/docker.sock
echo ""

echo "4. Can we list containers?"
docker ps -a
echo ""

echo "5. Can we pull a test image?"
docker pull hello-world:latest
echo ""

echo "6. Can we run a test container?"
docker run --rm hello-world
echo ""

echo "=== All checks complete ==="
