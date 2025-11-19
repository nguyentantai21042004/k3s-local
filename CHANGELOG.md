# Changelog

All notable changes to this K3s Emergency Backup Environment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.1.0] - 2025-11-19

### Added
- Comprehensive `VERSION.md` with detailed version tracking and update guidelines
- Version information in README with reference to VERSION.md
- CHANGELOG.md for tracking changes
- Version pinning for all services (no more `latest` tags)

### Changed
- **K3s**: Upgraded from `v1.29.0-k3s1` to `v1.31.3-k3s1` (Kubernetes 1.31)
- **Portainer CE**: Pinned to `2.21.4` (was `latest`)
- **Docker Registry**: Upgraded from `2` to `2.8.3`
- **Registry UI**: Pinned to `2.5.7` (was `latest`)
- Updated docker-compose header with specific versions
- Enhanced README with image version information

### Fixed
- Docker compose YAML structure: `registry` and `registry-ui` properly indented under `services:`
- Added missing resource limits for registry services
- Added missing network configuration for registry services
- Added missing container names for registry services
- Added missing restart policies for registry services

### Documentation
- Added VERSION.md with version selection criteria
- Added security considerations and CVE tracking
- Added upgrade guides for each component
- Added compatibility matrix
- Enhanced README with version references

## [1.0.0] - 2025-11-19

### Initial Release

- K3s single-node cluster setup
- Portainer CE for web-based management
- Docker Registry for private image storage
- Registry UI for browsing images
- Resource allocation optimized for Mac M4 Pro (24GB RAM)
- Comprehensive README with backup/restore procedures

### Components
- K3s Server: All-in-one (Control Plane + Worker)
- Portainer CE: Web UI on port 9000
- Docker Registry: Private registry on port 5001 (maps to 5000 in container)
- Registry UI: Web interface on port 8080

### Resource Allocation
- Total: ~4.25 CPUs, ~4.9GB RAM
- K3s: 3 CPUs, 4GB RAM
- Portainer: 0.5 CPU, 256MB RAM
- Registry: 0.5 CPU, 512MB RAM
- Registry UI: 0.25 CPU, 128MB RAM

---

## Version Format

Versions follow Semantic Versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes or significant architecture updates
- **MINOR**: New features, component version upgrades
- **PATCH**: Bug fixes, documentation updates

## Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Fixed**: Bug fixes
- **Security**: Security updates
- **Documentation**: Documentation changes

