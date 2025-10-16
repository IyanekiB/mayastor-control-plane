# Environment Setup Guide

This guide covers the setup of the development environment for mayastor-control-plane, including Nix shell configuration and Docker installation.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Nix Environment Setup](#nix-environment-setup)
- [Docker Installation](#docker-installation)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Linux-based operating system (Ubuntu 20.04+ recommended)
- Git installed
- Internet connection for downloading dependencies

## Nix Environment Setup

The project uses Nix for reproducible development environments. Follow these steps to set up Nix properly.

### 1. Install Nix (if not already installed)

If Nix is not installed on your system, install it with:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### 2. Configure Nix Channels

Nix channels provide package definitions. Configure them with:

```bash
# Add the nixpkgs channel
nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs

# Update channels
nix-channel --update
```

This resolves the `file 'nixpkgs' was not found in the Nix search path` error.

### 3. Install Rustup

The project requires Rust and rustup for toolchain management:

```bash
# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source the cargo environment
source $HOME/.cargo/env

# Verify installation
rustup --version
rustc --version
```

### 4. Fix Git Submodules

The project uses a submodule for dependencies. Ensure it points to the correct OpenEBS repository:

**Check current submodule configuration:**
```bash
cat .gitmodules
```

**If it points to a non-existent repository, update it:**

Edit `.gitmodules` to use the OpenEBS repository:
```
[submodule "utils/dependencies"]
    path = utils/dependencies
    url = https://github.com/openebs/mayastor-dependencies.git
    branch = develop
```

**Sync and update the submodule:**
```bash
git config submodule.utils/dependencies.url https://github.com/openebs/mayastor-dependencies.git
git submodule sync
git submodule update --init --recursive
```

### 5. Enter the Nix Shell

Use the provided helper script to enter the nix-shell with proper environment setup:

```bash
# Make the script executable
chmod +x enter-nix-shell.sh

# Enter the shell
./enter-nix-shell.sh
```

**Or manually with:**
```bash
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"
nix-shell --arg devrustup true
```

### 6. Verify Nix Shell Environment

Once inside the nix-shell, verify the environment:

```bash
# Check that rustup is available
rustup --version

# Check that cargo is available
cargo --version

# Verify other tools
which clang
which etcd
```

## Docker Installation

Many tests require Docker to be installed and running. Follow these steps to install Docker on Ubuntu/Debian-based systems.

### 1. Install Docker Engine

```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2. Start and Enable Docker Service

```bash
# Start Docker daemon
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Verify Docker is running
sudo systemctl status docker
```

### 3. Add User to Docker Group

To run Docker without sudo:

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply the group change (option 1: new shell)
newgrp docker

# OR (option 2: log out and log back in)
```

### 4. Verify Docker Installation

```bash
# Test Docker
docker ps

# Run hello-world container
docker run hello-world
```

### 5. Configure Docker for Development

For optimal development experience:

```bash
# Check Docker info
docker info

# Verify Docker socket exists
ls -la /var/run/docker.sock
```

The socket should show:
```
srw-rw---- 1 root docker 0 <date> /var/run/docker.sock
```

## Troubleshooting

### Nix Shell Issues

**Problem: `file 'nixpkgs' was not found in the Nix search path`**
```bash
# Solution: Configure Nix channels
nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
nix-channel --update
```

**Problem: `rustup: command not found`**
```bash
# Solution: Install rustup and source the environment
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
```

**Problem: `bash: shopt: progcomp: invalid shell option name`**
- This is a cosmetic warning and can be safely ignored
- It occurs when bash tries to load completion features that aren't available

**Problem: Submodule clone failures**
```bash
# Solution: Update submodule URL and re-sync
git config submodule.utils/dependencies.url https://github.com/openebs/mayastor-dependencies.git
git submodule sync
git submodule update --init --recursive
```

### Docker Issues

**Problem: `SocketNotFoundError("/var/run/docker.sock")`**
```bash
# Solution: Install and start Docker
sudo systemctl start docker
ls -la /var/run/docker.sock
```

**Problem: `permission denied while trying to connect to the Docker daemon socket`**
```bash
# Solution: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

**Problem: Docker service not starting**
```bash
# Check Docker service status
sudo systemctl status docker

# View Docker logs
sudo journalctl -u docker.service

# Restart Docker
sudo systemctl restart docker
```

### Test Failures

**Problem: Tests fail with Docker socket errors**
- Ensure Docker is installed and running: `docker ps`
- Verify socket permissions: `ls -la /var/run/docker.sock`
- Check if user is in docker group: `groups | grep docker`

**Problem: Pre-commit hook failures**
```bash
# Solution: Bypass pre-commit hooks for testing
git commit --no-verify -m "your message"

# Or update Rust toolchain
rustup update
```

## Quick Start Checklist

Use this checklist to verify your environment is properly configured:

- [ ] Nix installed and channels configured
- [ ] Rustup and Rust toolchain installed
- [ ] Git submodules cloned successfully
- [ ] Can enter nix-shell without errors
- [ ] Docker installed and running
- [ ] User added to docker group
- [ ] Docker socket accessible at `/var/run/docker.sock`
- [ ] Can run `docker ps` without sudo
- [ ] Tests can create Docker containers

## Additional Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Docker Documentation](https://docs.docker.com/)
- [Rust Installation Guide](https://www.rust-lang.org/tools/install)
- [OpenEBS Mayastor Documentation](https://github.com/openebs/mayastor)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the project's main README.md
2. Search existing GitHub issues
3. Create a new issue with:
   - Your OS and version
   - Steps to reproduce the problem
   - Full error messages
   - Output of diagnostic commands
