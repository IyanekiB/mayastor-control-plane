#!/bin/bash
# Quick script to run and test the Prometheus metrics endpoint

set -e

echo "=== Starting Mayastor Control Plane Metrics Test ==="
echo ""

# Navigate to the project directory
cd /home/azureuser/mayastor-workspace/mayastor-control-plane

echo "Step 1: Starting etcd in Docker..."
docker run -d \
  --name mayastor-etcd-test \
  -p 2379:2379 \
  -p 2380:2380 \
  --rm \
  quay.io/coreos/etcd:latest \
  etcd \
  --advertise-client-urls=http://0.0.0.0:2379 \
  --listen-client-urls=http://0.0.0.0:2379

echo "✓ etcd started"
sleep 3

echo ""
echo "Step 2: Starting Core Agent..."
echo "Run this in a separate terminal:"
echo "  cd /home/azureuser/mayastor-workspace/mayastor-control-plane"
echo "  nix-shell --arg devrustup true --run './target/release/core --store http://localhost:2379'"
echo ""
echo "Press Enter when Core Agent is running..."
read

echo ""
echo "Step 3: Starting REST API..."
echo "Run this in another terminal:"
echo "  cd /home/azureuser/mayastor-workspace/mayastor-control-plane"
echo "  nix-shell --arg devrustup true --run 'RUST_LOG=info ./target/release/rest --dummy-certificates --no-auth --core-grpc http://localhost:50051'"
echo ""
echo "Press Enter when REST API is running..."
read

echo ""
echo "Step 4: Testing metrics endpoint..."
echo ""
curl -k https://localhost:8080/v0/metrics || curl -k http://localhost:8081/v0/metrics
echo ""
echo ""
echo "=== Metrics Test Complete ==="
