# Changelog

All notable changes to this K3s Emergency Backup Environment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.4.0] - 2025-11-20

### Added
- **RabbitMQ 4.0** message broker service
  - Image: `rabbitmq:4.0-management-alpine` (Official RabbitMQ release, Alpine-based)
  - Resources: 1 CPU, 1GB RAM
  - Ports: `5672` (AMQP), `15672` (Management UI)
  - Fixed IP: `172.28.0.70` in k3s-network
  - Health check with `rabbitmq-diagnostics ping`
  - Persistent volume: `rabbitmq-data`
- RabbitMQ environment variables support in `.env.example`:
  - `RABBITMQ_DEFAULT_USER` (default: `admin`)
  - `RABBITMQ_DEFAULT_PASS` (default: `your_rabbitmq_password_here`)
- RabbitMQ volume (`k3s_rabbitmq-data`) added to backup script
- Makefile targets for RabbitMQ management:
  - `make up-mq` - Start RabbitMQ
  - `make down-mq` - Stop RabbitMQ
  - `make restart-mq` - Restart RabbitMQ
  - `make logs-mq` - View RabbitMQ logs

### Changed
- Updated total resource allocation:
  - CPU: ~6.25 cores → ~7.25 cores
  - RAM: ~6.9GB → ~7.9GB
- Updated Makefile: Added `MESSAGE_SERVICES` group for RabbitMQ

## [1.3.0] - 2025-11-20

### Added
- **MongoDB 8.0** NoSQL database service
  - Image: `mongo:8.0` (Official MongoDB release)
  - Resources: 1 CPU, 1GB RAM
  - Port: `27017` (mapped to host)
  - Fixed IP: `172.28.0.60` in k3s-network
  - Health check with `mongosh ping`
  - Persistent volumes: `mongodb-data`, `mongodb-config`
- MongoDB environment variables support in `.env.example`:
  - `MONGO_INITDB_ROOT_USERNAME` (default: `admin`)
  - `MONGO_INITDB_ROOT_PASSWORD` (default: `your_mongo_password_here`)
  - `MONGO_INITDB_DATABASE` (default: `defaultdb`)
- MongoDB volumes (`k3s_mongodb-data`, `k3s_mongodb-config`) added to backup script

### Changed
- Updated total resource allocation:
  - CPU: ~5.25 cores → ~6.25 cores
  - RAM: ~5.9GB → ~6.9GB
- Updated Makefile: Renamed `POSTGRE_SERVICES` to `DATABASE_SERVICES` (includes both PostgreSQL and MongoDB)
- Updated Makefile targets: `up-db`, `down-db`, `restart-db`, `logs-db` now manage both databases

## [1.2.0] - 2025-11-20

### Added
- **PostgreSQL 18.1** database service
  - Image: `postgres:18.1` (Official PostgreSQL release from November 13, 2025)
  - Resources: 1 CPU, 1GB RAM
  - Port: `5432` (mapped to host)
  - Fixed IP: `172.28.0.50` in k3s-network
  - Health check with `pg_isready`
  - Persistent volume: `postgres-data`
- `.env.example` file with environment variable templates
- Makefile targets for PostgreSQL management:
  - `make up-db` - Start PostgreSQL
  - `make down-db` - Stop PostgreSQL
  - `make restart-db` - Restart PostgreSQL
  - `make logs-db` - View PostgreSQL logs
- PostgreSQL volume (`k3s_postgres-data`) added to backup script

### Changed
- Updated total resource allocation:
  - CPU: ~4.25 cores → ~5.25 cores
  - RAM: ~4.9GB → ~5.9GB
- Updated docker-compose.yaml header with PostgreSQL information
- Updated Makefile to include PostgreSQL in `ALL_SERVICES`

### Configuration
- PostgreSQL environment variables support `.env` file:
  - `POSTGRES_USER` (default: `admin`)
  - `POSTGRES_PASSWORD` (default: `your_secure_password_here`)
  - `POSTGRES_DB` (default: `defaultdb`)
- K3s token also supports `.env` file via `K3S_TOKEN`

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

