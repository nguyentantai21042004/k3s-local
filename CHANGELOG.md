# Changelog

All notable changes to this project are documented here.  
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.5.0] - 2025-11-20

### Added
- **Redis 7.4-alpine** in-memory cache/database
  - Resources: 0.5 CPU, 512MB RAM | Port: 6379
  - Fixed IP: 172.28.0.80 | Volume: `redis-data`
  - Environment: `REDIS_PASSWORD`
  - Makefile: `make up-cache`, `logs-cache`, etc.
  
- **MinIO RELEASE.2024-11-07** S3-compatible object storage
  - Resources: 1 CPU, 1GB RAM | Ports: 9002 (API), 9003 (Console)
  - Fixed IP: 172.28.0.90 | Volume: `minio-data`
  - Environment: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`
  - Makefile: `make up-storage`, `logs-storage`, etc.

### Changed
- Total resources: ~7.25 CPUs, ~7.9GB RAM → **~8.75 CPUs, ~9.4GB RAM**
- Makefile: Added `CACHE_SERVICES` and `STORAGE_SERVICES` groups

## [1.4.0] - 2025-11-20

### Added
- **RabbitMQ 4.0-management-alpine** message broker
  - Resources: 1 CPU, 1GB RAM | Ports: 5672 (AMQP), 15672 (UI)
  - Fixed IP: 172.28.0.70 | Volume: `rabbitmq-data`
  - Environment: `RABBITMQ_DEFAULT_USER`, `RABBITMQ_DEFAULT_PASS`
  - Makefile: `make up-mq`, `logs-mq`, etc.

### Changed
- Total resources: ~6.25 CPUs, ~6.9GB RAM → **~7.25 CPUs, ~7.9GB RAM**
- Makefile: Added `MESSAGE_SERVICES` group

## [1.3.0] - 2025-11-20

### Added
- **MongoDB 8.0** NoSQL database
  - Resources: 1 CPU, 1GB RAM | Port: 27017
  - Fixed IP: 172.28.0.60 | Volumes: `mongodb-data`, `mongodb-config`
  - Environment: `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`, `MONGO_INITDB_DATABASE`

### Changed
- Total resources: ~5.25 CPUs, ~5.9GB RAM → **~6.25 CPUs, ~6.9GB RAM**
- Makefile: Renamed `POSTGRE_SERVICES` → `DATABASE_SERVICES` (PostgreSQL + MongoDB)
- Targets renamed: `make up-db`, `logs-db` now manage both databases

## [1.2.0] - 2025-11-20

### Added
- **PostgreSQL 18.1** relational database (released Nov 13, 2025)
  - Resources: 1 CPU, 1GB RAM | Port: 5432
  - Fixed IP: 172.28.0.50 | Volume: `postgres-data`
  - Environment: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
  - Makefile: `make up-db`, `logs-db`, etc.
- `.env.example` file for environment variable templates

### Changed
- Total resources: ~4.25 CPUs, ~4.9GB RAM → **~5.25 CPUs, ~5.9GB RAM**

## [1.1.0] - 2025-11-19

### Added
- Comprehensive `VERSION.md` with version tracking and upgrade guides
- `CHANGELOG.md` for change history
- Version pinning for all services (no `latest` tags)

### Changed
- **K3s**: `v1.29.0-k3s1` → `v1.31.3-k3s1` (Kubernetes 1.31)
- **Portainer CE**: Pinned to `2.21.4`
- **Registry**: `2` → `2.8.3`
- **Registry UI**: Pinned to `2.5.7`

### Fixed
- Docker Compose YAML structure and indentation
- Missing resource limits, networks, restart policies for registry services

## [1.0.0] - 2025-11-19

### Initial Release
- K3s v1.29.0-k3s1 single-node cluster (Control Plane + Worker)
- Portainer CE 2.21.4 for web-based management (port 9000)
- Docker Registry 2.8.3 for private images (port 5001)
- Registry UI 2.5.7 for browsing (port 8080)
- Total: ~4.25 CPUs, ~4.9GB RAM
- Optimized for Mac M4 Pro (24GB RAM)

---

## Version Format

**Semantic Versioning:** `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes, architecture updates
- **MINOR**: New features, version upgrades
- **PATCH**: Bug fixes, documentation

## Categories

**Added** | **Changed** | **Deprecated** | **Fixed** | **Security** | **Documentation**
