# Running Snapshot Rebuild Integration Tests

The `snapshot_rebuild` integration test requires a full cluster environment and cannot run in CI.

## Prerequisites

1. Ensure you have the development environment set up:
   ```bash
   cd mayastor-control-plane
   ./enter-nix-shell.sh
   ```

2. Pull required Docker images:
   ```bash
   docker pull openebs/mayastor-io-engine:develop
   docker pull jaegertracing/all-in-one:latest
   ```

3. Configure system for io-engine:
   ```bash
   # Set hugepages
   sudo sysctl -w vm.nr_hugepages=1024

   # Load kernel modules
   sudo modprobe nvme_tcp
   ```

## Running the Test

From within the nix-shell:

```bash
# Set environment variables
export TARGET_REGISTRY=openebs
export RUST_LOG=info

# Run the specific integration test
cargo test --package agents --bin core snapshot_rebuild -- --nocapture --test-threads=1
```

## Expected Behavior

The test will:
1. Build a test cluster with io-engine, etcd, Jaeger, and core services
2. Create a volume with a replica
3. Create a snapshot of the replica
4. Simulate a rebuild from the snapshot
5. Verify the rebuild completes successfully

## Troubleshooting

### "Failed to wait for core to get ready"
- Check that Docker is running: `docker ps`
- Verify hugepages: `cat /proc/meminfo | grep Huge`
- Check available disk space: `df -h`

### "transport error"
- Ensure no other services are using ports 8080, 8081, etc.
- Check Docker networking: `docker network ls`

### "nvme_tcp module not available"
- Some features may be degraded but test should still work
- On Ubuntu: `sudo apt-get install linux-modules-extra-$(uname -r)`
