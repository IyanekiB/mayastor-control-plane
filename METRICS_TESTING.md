# Testing the Metrics Endpoint

This guide explains how to manually test the metrics endpoint using Docker Desktop.

## Prerequisites

- Docker Desktop installed and running
- WSL2 with the repository cloned
- All dependencies installed (Rust, etc.)

## Option 1: Quick Test with Local Build

### 1. Build the REST service locally

```bash
cd /mnt/d/Issue\ \#1698/mayastor-control-plane
source setup-env.sh
cargo build -p rest --release
```

### 2. Start etcd in Docker

```bash
docker run -d \
  --name mayastor-etcd \
  -p 2379:2379 \
  -p 2380:2380 \
  quay.io/coreos/etcd:v3.5.11 \
  /usr/local/bin/etcd \
  --advertise-client-urls=http://0.0.0.0:2379 \
  --listen-client-urls=http://0.0.0.0:2379
```

### 3. Run the REST service

```bash
# Set required environment variables
export ETCD_ENDPOINT=http://localhost:2379
export RUST_LOG=info

# Run the service
./target/release/rest
```

### 4. Test the metrics endpoint

In another terminal:

```bash
# Test metrics endpoint (without auth)
curl http://localhost:8080/v0/metrics

# Or with authentication if enabled
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v0/metrics
```

### 5. Cleanup

```bash
# Stop and remove etcd container
docker stop mayastor-etcd
docker rm mayastor-etcd
```

## Option 2: Using Docker Compose (Full Stack)

### 1. Build and start services

```bash
cd /mnt/d/Issue\ \#1698/mayastor-control-plane
docker compose -f docker-compose.test.yml build
docker compose -f docker-compose.test.yml up -d
```

### 2. Check logs

```bash
# Check REST service logs
docker compose -f docker-compose.test.yml logs rest-service

# Check etcd logs
docker compose -f docker-compose.test.yml logs etcd
```

### 3. Test the metrics endpoint

```bash
# Wait a few seconds for services to start, then test
curl http://localhost:8080/v0/metrics
```

### 4. Cleanup

```bash
docker compose -f docker-compose.test.yml down
```

## Expected Output

The metrics endpoint should return Prometheus-formatted metrics like:

```
# HELP rest_api_requests_total Total number of REST API requests
# TYPE rest_api_requests_total counter
rest_api_requests_total{method="GET",endpoint="/v0/metrics"} 1

# HELP rest_api_request_duration_seconds REST API request duration
# TYPE rest_api_request_duration_seconds histogram
...
```

## Troubleshooting

### Connection refused
- Make sure etcd is running: `docker ps | grep etcd`
- Check REST service logs for startup errors

### Build failures
- Ensure you've sourced `setup-env.sh` to set environment variables
- Check that all dependencies are installed

### Permission errors
- Make sure Docker Desktop is running
- Check that you're in the docker group: `groups`

## Notes

- The integration test (`cargo test -p rest metrics`) requires privileged Docker containers and may not work in WSL2/Docker Desktop
- Manual testing as shown above is the recommended approach for WSL2 environments
- For full integration testing, use a native Linux environment
