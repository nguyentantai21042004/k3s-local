# K3s Local Development & Backup Environment

> **English** | [Tiếng Việt](docs/README_VI.md)

A production-grade, single-node K3s cluster with supporting infrastructure services, designed for local development and emergency backup of homelab workloads.

## Overview

This environment provides a complete Kubernetes stack with essential services including databases (PostgreSQL, MongoDB), caching (Redis), message broker (RabbitMQ), object storage (MinIO), and more—all containerized and ready to run on a local machine.

**Key Features:**
- Single-node K3s cluster (Kubernetes 1.31)
- 9 integrated services with pinned versions
- Resource-optimized for Mac M4 Pro (24GB RAM)
- Health checks and auto-restart for all services
- Web UIs for management (Portainer, Registry, RabbitMQ, MinIO)
- Automated backup scripts
- Internal Docker network with fixed IPs

## Quick Start

```bash
# 1. Clone and navigate
cd /path/to/k3s-local

# 2. (Optional) Configure environment
cp .env.example .env
# Edit .env with your passwords

# 3. Start all services
make up
# Or: docker compose up -d

# 4. Verify versions
make verify

# 5. Check status
docker compose ps
```

## Services & Ports

| Service | Version | Port(s) | Purpose | Web UI |
|---------|---------|---------|---------|--------|
| **K3s** | v1.31.3 | 6443, 80, 443 | Kubernetes cluster | - |
| **Portainer** | 2.21.4 | 9000, 9443 | K8s/Docker management | http://localhost:9000 |
| **Registry** | 2.8.3 | 5001 | Private image registry | - |
| **Registry UI** | 2.5.7 | 8080 | Registry browser | http://localhost:8080 |
| **PostgreSQL** | 18.1 | 5432 | SQL database | - |
| **MongoDB** | 8.0 | 27017 | NoSQL database | - |
| **RabbitMQ** | 4.0 | 5672, 15672 | Message broker | http://localhost:15672 |
| **Redis** | 7.4 | 6379 | In-memory cache | - |
| **MinIO** | 2024-11-07 | 9002, 9003 | S3-compatible storage | http://localhost:9003 |

**Total Resources:** ~8.75 CPUs, ~9.4GB RAM

## Common Commands

```bash
# Start all services
make up

# Start by group
make up-cluster    # K3s + Portainer
make up-db         # PostgreSQL + MongoDB
make up-mq         # RabbitMQ
make up-cache      # Redis
make up-storage    # MinIO

# Logs
make logs-cluster
make logs-db

# Maintenance
make verify        # Check versions
make backup        # Backup all volumes
make updates       # Check for updates

# Stop
make down          # Stop containers
make nuke          # Stop + remove volumes (data loss)
```

## Kubectl Access

### Method 1: Via Container (Recommended for local)
```bash
docker exec -it k3s-server kubectl get nodes
docker exec -it k3s-server kubectl get pods -A
```

### Method 2: From Host Machine
```bash
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
kubectl get nodes
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Network: k3s-network                  │
│                       (172.28.0.0/16)                            │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  K3s Server │  │  Portainer   │  │  Registry    │          │
│  │ 172.28.0.10 │  │ 172.28.0.30  │  │ 172.28.0.40  │          │
│  └─────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  PostgreSQL │  │  MongoDB     │  │  RabbitMQ    │          │
│  │ 172.28.0.50 │  │ 172.28.0.60  │  │ 172.28.0.70  │          │
│  └─────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐                             │
│  │  Redis      │  │  MinIO       │                             │
│  │ 172.28.0.80 │  │ 172.28.0.90  │                             │
│  └─────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

## Documentation

- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Common commands and troubleshooting
- **[Version Guide](docs/VERSION.md)** - Detailed version info and upgrade guides
- **[K3s Integration](docs/K3S_INTEGRATION.md)** - Networking and service communication (TBD)
- **[Vietnamese Docs](docs/README_VI.md)** - Full documentation in Vietnamese
- **[Changelog](CHANGELOG.md)** - Version history

## Project Structure

```
k3s-local/
├── docker-compose.yaml      # Service definitions
├── Makefile                  # Command aliases
├── .env.example             # Environment template
├── docs/
│   ├── QUICK_REFERENCE.md   # Commands & troubleshooting
│   ├── VERSION.md           # Version details
│   ├── K3S_INTEGRATION.md   # Networking guide (TBD)
│   └── README_VI.md         # Vietnamese docs
├── scripts/
│   ├── verify-versions.sh   # Version checker
│   ├── check-updates.sh     # Update checker
│   └── backup-volumes.sh    # Backup utility
└── kubeconfig/
    └── kubeconfig.yaml      # Auto-generated K8s config
```

## Security Notes

**WARNING:** This is a LOCAL development/backup environment, NOT for production use:

- Default passwords are weak (change them in `.env`)
- No TLS for internal communication
- Registry has no authentication
- Services are exposed on localhost only

For production deployment, implement:
- Strong passwords and secrets management
- TLS certificates
- Network policies
- RBAC controls
- Monitoring and alerting

## Requirements

- Docker Desktop 24.0+ with Docker Compose
- 10GB+ free RAM (16GB+ recommended)
- 50GB+ free disk space
- macOS (M-series or Intel), Linux, or Windows with WSL2

## Troubleshooting

**Container not starting?**
```bash
docker logs <container-name>
docker compose restart <service>
```

**K8s API not accessible?**
```bash
# Fix kubeconfig server URL
sed -i '' 's/https:\/\/k3s-server:6443/https:\/\/127.0.0.1:6443/g' kubeconfig/kubeconfig.yaml
```

**Out of resources?**
```bash
docker system prune -a
docker volume prune
```

See [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) for more troubleshooting tips.

---

**Author:** TanTai  
**Last Updated:** November 2025  
**Purpose:** Local K3s development and homelab backup environment
