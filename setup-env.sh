#!/bin/bash
# Setup script for required environment variables
# Usage: source setup-env.sh

export WORKSPACE_ROOT=$(pwd)
export SUDO=$(which sudo 2>/dev/null || echo /usr/bin/sudo)
export RUST_BACKTRACE=1

echo "Environment variables set:"
echo "  WORKSPACE_ROOT=$WORKSPACE_ROOT"
echo "  SUDO=$SUDO"
echo "  RUST_BACKTRACE=$RUST_BACKTRACE"
echo ""
echo "Checking Docker connectivity..."
if docker info > /dev/null 2>&1; then
    echo "  Docker: OK"
else
    echo "  Docker: ERROR - Cannot connect to Docker daemon"
    echo "  Make sure Docker is running and accessible"
fi
echo ""
echo "You can now run: cargo test -p rest metrics"
