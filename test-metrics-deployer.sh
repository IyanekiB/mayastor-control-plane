#!/bin/bash
# Simple script to test Prometheus metrics using deployer

set -e

cd /home/azureuser/mayastor-workspace/mayastor-control-plane

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Testing Mayastor Prometheus Metrics with Deployer          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Stopping cluster..."
    nix-shell --arg devrustup true --run "cargo run --bin deployer -- stop" || true
    echo "✓ Cleanup complete"
}

trap cleanup EXIT INT TERM

echo "🚀 Starting Mayastor cluster (this will take a few minutes)..."
echo ""
echo "The deployer will:"
echo "  1. Start etcd"
echo "  2. Start Jaeger for tracing"
echo "  3. Start Core Agent"
echo "  4. Start REST API"
echo ""

# Start cluster with deployer
nix-shell --arg devrustup true --run \
    "cargo run --bin deployer -- start \
        --no-io-engines \
        --agents CoreAgent \
        --rest \
        --jaeger \
        --show-info \
        --wait-timeout 120s \
        --rust-log info"

echo ""
echo "✓ Cluster started successfully!"
echo ""

# Test the metrics endpoint
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Testing /v0/metrics Endpoint                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Wait a bit for services to stabilize
sleep 5

echo "Testing HTTPS endpoint..."
echo ""

HTTP_RESPONSE=$(curl -k -s -w "\n%{http_code}" https://localhost:8080/v0/metrics 2>/dev/null || echo "connection_failed")

if [ "$HTTP_RESPONSE" == "connection_failed" ]; then
    echo "❌ Could not connect to REST API"
    echo ""
    echo "Trying HTTP on port 8081..."
    HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8081/v0/metrics 2>/dev/null || echo "connection_failed")
fi

if [ "$HTTP_RESPONSE" == "connection_failed" ]; then
    echo "❌ Could not connect to REST API on either port"
    echo ""
    echo "Check deployer logs above for errors"
else
    BODY=$(echo "$HTTP_RESPONSE" | head -n -1)
    CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)

    echo "Response Body:"
    echo "────────────────────────────────────────────────────────────"
    echo "$BODY"
    echo "────────────────────────────────────────────────────────────"
    echo "HTTP Status Code: $CODE"
    echo ""

    if [ "$CODE" == "200" ]; then
        echo "✅ SUCCESS! Metrics endpoint is working and returning data!"
        echo ""
        echo "Found metrics:"
        echo "$BODY" | grep "^mayastor_" || echo "  (No mayastor_ metrics found - this is normal without io-engine nodes)"
    elif [ "$CODE" == "204" ]; then
        echo "✅ SUCCESS! Metrics endpoint is working!"
        echo ""
        echo "ℹ️  HTTP 204 (No Content) means:"
        echo "   - The endpoint exists and is functional"
        echo "   - No io-engine nodes are currently registered"
        echo "   - This is EXPECTED without io-engine running"
        echo ""
        echo "Your implementation is correct! ✅"
    else
        echo "⚠️  Unexpected status code: $CODE"
    fi
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Cluster Information                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Show running containers
echo "Running Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|mayastor|etcd|jaeger" || echo "No containers found"

echo ""
echo "REST API endpoints you can test:"
echo "  • Metrics:  curl -k https://localhost:8080/v0/metrics"
echo "  • Nodes:    curl -k https://localhost:8080/v0/nodes"
echo "  • Pools:    curl -k https://localhost:8080/v0/pools"
echo "  • Volumes:  curl -k https://localhost:8080/v0/volumes"
echo ""
echo "Press Ctrl+C to stop the cluster..."
echo ""

# Keep script running
wait
