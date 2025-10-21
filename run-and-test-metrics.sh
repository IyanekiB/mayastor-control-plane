#!/bin/bash
# Automated script to start services and test Prometheus metrics
# This script starts everything in the background and tests the metrics endpoint

set -e

PROJECT_DIR="/home/azureuser/mayastor-workspace/mayastor-control-plane"
cd "$PROJECT_DIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Mayastor Prometheus Metrics - Automated Test            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."

    # Stop REST API
    if [ ! -z "$REST_PID" ]; then
        echo "  Stopping REST API (PID: $REST_PID)..."
        kill $REST_PID 2>/dev/null || true
    fi

    # Stop Core Agent
    if [ ! -z "$CORE_PID" ]; then
        echo "  Stopping Core Agent (PID: $CORE_PID)..."
        kill $CORE_PID 2>/dev/null || true
    fi

    # Stop etcd
    echo "  Stopping etcd container..."
    docker stop mayastor-etcd-test 2>/dev/null || true
    docker rm mayastor-etcd-test 2>/dev/null || true

    echo "✓ Cleanup complete"
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Check if services are already running
if docker ps | grep -q mayastor-etcd-test; then
    echo "⚠️  etcd is already running. Stopping it first..."
    docker stop mayastor-etcd-test 2>/dev/null || true
fi

if lsof -i:8080 >/dev/null 2>&1; then
    echo "⚠️  Port 8080 is already in use. Please free it first."
    lsof -i:8080
    exit 1
fi

# Step 1: Start etcd
echo "📦 Step 1/4: Starting etcd..."
docker run -d \
  --name mayastor-etcd-test \
  -p 2379:2379 \
  -p 2380:2380 \
  quay.io/coreos/etcd:v3.5.9 \
  etcd \
  --advertise-client-urls=http://0.0.0.0:2379 \
  --listen-client-urls=http://0.0.0.0:2379 \
  > /dev/null

echo "  ✓ etcd started on port 2379"
sleep 3

# Verify etcd is ready
if curl -s http://localhost:2379/version >/dev/null; then
    echo "  ✓ etcd is ready"
else
    echo "  ❌ etcd failed to start"
    exit 1
fi

# Step 2: Build if needed
if [ ! -f "target/release/rest" ] || [ ! -f "target/release/core" ]; then
    echo ""
    echo "📦 Step 2/4: Building binaries (this may take a while)..."
    nix-shell --arg devrustup true --run "cargo build -p rest -p agents --release" || {
        echo "  ❌ Build failed"
        exit 1
    }
    echo "  ✓ Build complete"
else
    echo ""
    echo "📦 Step 2/4: Using existing binaries"
fi

# Step 3: Start Core Agent
echo ""
echo "🚀 Step 3/4: Starting Core Agent..."
nix-shell --arg devrustup true --run \
    "RUST_LOG=info ./target/release/core --store http://localhost:2379 2>&1" \
    > /tmp/core-agent.log 2>&1 &
CORE_PID=$!

echo "  ✓ Core Agent started (PID: $CORE_PID)"
echo "    Logs: /tmp/core-agent.log"
sleep 5

# Check if core agent is running
if ! ps -p $CORE_PID > /dev/null; then
    echo "  ❌ Core Agent failed to start. Check logs:"
    tail -20 /tmp/core-agent.log
    exit 1
fi

# Step 4: Start REST API
echo ""
echo "🌐 Step 4/4: Starting REST API..."
nix-shell --arg devrustup true --run \
    "RUST_LOG=info ./target/release/rest --dummy-certificates --no-auth --core-grpc http://localhost:50051 2>&1" \
    > /tmp/rest-api.log 2>&1 &
REST_PID=$!

echo "  ✓ REST API started (PID: $REST_PID)"
echo "    Logs: /tmp/rest-api.log"
echo "    Waiting for REST API to be ready..."
sleep 8

# Check if REST API is running
if ! ps -p $REST_PID > /dev/null; then
    echo "  ❌ REST API failed to start. Check logs:"
    tail -20 /tmp/rest-api.log
    exit 1
fi

# Wait for API to be ready
echo "  Checking if REST API is responding..."
for i in {1..10}; do
    if curl -k -s https://localhost:8080/v0/nodes > /dev/null 2>&1; then
        echo "  ✓ REST API is ready"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "  ❌ REST API didn't respond in time. Check logs:"
        tail -20 /tmp/rest-api.log
        exit 1
    fi
    sleep 2
done

# Test the metrics endpoint
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Testing Prometheus Metrics Endpoint                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 Testing HTTPS endpoint: https://localhost:8080/v0/metrics"
echo ""
echo "Response:"
echo "─────────────────────────────────────────────────────────────"

HTTP_CODE=$(curl -k -s -w "\n%{http_code}" https://localhost:8080/v0/metrics)
BODY=$(echo "$HTTP_CODE" | head -n -1)
CODE=$(echo "$HTTP_CODE" | tail -n 1)

echo "$BODY"
echo "─────────────────────────────────────────────────────────────"
echo "HTTP Status Code: $CODE"
echo ""

if [ "$CODE" == "200" ]; then
    echo "✅ SUCCESS! Metrics endpoint is working and returning data!"
    echo ""
    echo "Metrics found:"
    echo "$BODY" | grep "^mayastor_" | head -5
elif [ "$CODE" == "204" ]; then
    echo "✅ SUCCESS! Metrics endpoint is working!"
    echo ""
    echo "ℹ️  HTTP 204 (No Content) means:"
    echo "   - The endpoint exists and is functional"
    echo "   - No io-engine nodes are currently registered"
    echo "   - This is expected without io-engine running"
    echo ""
    echo "💡 To see actual metrics data, you would need to:"
    echo "   1. Start io-engine instances"
    echo "   2. Register nodes with the control plane"
    echo "   3. Create pools and volumes"
else
    echo "⚠️  Unexpected status code: $CODE"
    echo ""
    echo "Check logs for details:"
    echo "  Core Agent: /tmp/core-agent.log"
    echo "  REST API: /tmp/rest-api.log"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Services are Running                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Services running:"
echo "  • etcd:       http://localhost:2379"
echo "  • Core Agent: grpc://localhost:50051 (PID: $CORE_PID)"
echo "  • REST API:   https://localhost:8080 (PID: $REST_PID)"
echo ""
echo "Logs:"
echo "  • Core Agent: tail -f /tmp/core-agent.log"
echo "  • REST API:   tail -f /tmp/rest-api.log"
echo ""
echo "Test the metrics endpoint:"
echo "  curl -k https://localhost:8080/v0/metrics"
echo ""
echo "Test other endpoints:"
echo "  curl -k https://localhost:8080/v0/nodes"
echo "  curl -k https://localhost:8080/v0/pools"
echo "  curl -k https://localhost:8080/v0/volumes"
echo ""
echo "Press Ctrl+C to stop all services and cleanup..."
echo ""

# Keep running
tail -f /tmp/rest-api.log /tmp/core-agent.log
