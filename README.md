# Mayastor Control Plane "2.0"

[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fmayastor-control-plane.svg?type=shield&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fmayastor-control-plane?ref=badge_shield&issueType=license)
[![Slack](https://img.shields.io/badge/chat-slack-ff1493.svg?style=flat-square)](https://kubernetes.slack.com/messages/openebs/)
[![Community Meetings](https://img.shields.io/badge/Community-Meetings-blue)](https://github.com/openebs/community/blob/HEAD/README.md#community)
[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

## Getting Started

### Environment Setup

To set up your development environment (Nix shell, Docker, dependencies), please refer to the comprehensive setup guide:

**[Environment Setup Guide](ENVIRONMENT_SETUP.md)**

This guide covers:
- Nix environment configuration
- Rustup installation
- Git submodule setup
- Docker installation and configuration
- Common troubleshooting steps

### Quick Start

```bash
# Clone the repository
git clone https://github.com/openebs/mayastor-control-plane.git
cd mayastor-control-plane

# Initialize submodules
git submodule update --init --recursive

# Enter nix-shell
./enter-nix-shell.sh

# Build the project
cargo build
```

## Links

- [Mayastor](https://github.com/openebs/Mayastor)
- [Environment Setup Guide](ENVIRONMENT_SETUP.md)

## License

Mayastor is developed under Apache 2.0 license at the project level. Some components of the project are derived from
other open source projects and are distributed under their respective licenses.

### Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in Mayastor by you, as defined in the Apache-2.0 license, licensed as above,
without any additional terms or conditions.

[![FOSSA Status](https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fmayastor-control-plane.svg?type=large&issueType=license)](https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopenebs%2Fmayastor-control-plane?ref=badge_large&issueType=license)
