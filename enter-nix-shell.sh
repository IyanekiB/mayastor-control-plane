#!/bin/bash
# Helper script to enter nix-shell with proper environment setup

# Source cargo environment
source "$HOME/.cargo/env"

# Make sure rustup is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Enter nix-shell with rustup support
nix-shell --arg devrustup true
