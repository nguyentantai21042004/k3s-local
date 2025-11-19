# Version Information

Last updated: **November 19, 2025**

## Current Stable Versions

| Service | Image | Version | Released | Status     |
|---------|-------|---------|----------|------------|
| **K3s** | `rancher/k3s` | `v1.31.3-k3s1` | Oct 2024 | Stable     |
| **Portainer CE** | `portainer/portainer-ce` | `2.21.4` | Oct 2024 | Stable     |
| **Docker Registry** | `registry` | `2.8.3` | Jul 2024 | Stable     |
| **Registry UI** | `joxit/docker-registry-ui` | `2.5.7` | Sep 2024 | Stable     |
| **PostgreSQL** | `postgres` | `18.1` | Nov 13, 2025 | Stable     |

## Version Selection Criteria

### K3s v1.31.3-k3s1
- **Kubernetes Version:** 1.31 (Latest stable)
- **Why this version:**
  - Long-term support (LTS) release
  - Compatible with latest Kubernetes features
  - Proven stability for production workloads
  - Good performance on ARM64 (M4 Pro)
- **Upgrade from:** v1.29.0-k3s1
- **Breaking changes:** None for basic setup
- **Official docs:** https://github.com/k3s-io/k3s/releases

### Portainer CE 2.21.4
- **Why this version:**
  - Pinned version for stability (avoid `latest` tag issues)
  - Full Kubernetes 1.31 support
  - Enhanced security features
  - Better performance monitoring
- **Upgrade from:** latest (unspecified)
- **Breaking changes:** None
- **Official docs:** https://www.portainer.io/

### Docker Registry 2.8.3
- **Why this version:**
  - Latest stable release of Registry v2
  - Security patches included
  - Full OCI compliance
  - Better garbage collection
- **Upgrade from:** 2 (unspecified minor version)
- **Breaking changes:** None
- **Official docs:** https://distribution.github.io/distribution/

### Joxit Registry UI 2.5.7
- **Why this version:**
  - Latest stable with modern UI
  - Support for multi-arch images
  - Image deletion capability
  - Content digest display
  - Better search and filtering
- **Upgrade from:** latest (unspecified)
- **Breaking changes:** None
- **Official docs:** https://github.com/Joxit/docker-registry-ui

### PostgreSQL 18.1
- **PostgreSQL Version:** 18.1 (Official release from PostgreSQL)
- **Release Date:** November 13, 2025
- **Why this version:**
  - PostgreSQL 18 is the latest major version
  - Official release from PostgreSQL project
  - Improved performance and new features
  - Better ARM64 support
  - Enhanced security features
  - Long-term support expected
- **Upgrade from:** N/A (new service)
- **Breaking changes:** None for basic setup
- **Official docs:** https://www.postgresql.org/docs/18/

## Update Schedule

### Recommended Update Frequency

| Component    | Check Frequency | Update Strategy                  |
|--------------|----------------|----------------------------------|
| K3s          | Monthly        | Follow Kubernetes release cycle  |
| Portainer    | Quarterly      | Update on major/minor releases   |
| Registry     | Semi-annually  | Update on security patches       |
| Registry UI  | Quarterly      | Update for new features          |
| PostgreSQL   | Quarterly      | Update on security patches       |

### Before Updating

1. Check release notes for breaking changes
2. Backup existing volumes
3. Test in isolated environment first
4. Verify compatibility between components
5. Review resource requirements

## Security Considerations

### CVE Tracking

- **K3s:** Monitor https://github.com/k3s-io/k3s/security/advisories
- **Portainer:** Monitor https://github.com/portainer/portainer/security
- **Registry:** Monitor https://github.com/distribution/distribution/security
- **Registry UI:** Monitor https://github.com/Joxit/docker-registry-ui/security
- **PostgreSQL:** Monitor https://www.postgresql.org/support/security/

### Security Update Policy

- **Critical vulnerabilities:** Update immediately
- **High severity:** Update within 1 week
- **Medium/Low severity:** Update on regular schedule

## Compatibility Matrix

### K3s + Kubernetes Versions

| K3s Version   | Kubernetes | Docker API | ARM64 Support |
|---------------|------------|------------|---------------|
| v1.31.3-k3s1  | 1.31.x     | v1.24+     | Yes (Full)    |
| v1.30.x-k3s1  | 1.30.x     | v1.24+     | Yes (Full)    |
| v1.29.x-k3s1  | 1.29.x     | v1.24+     | Yes (Full)    |

### Tested Combinations

Current Setup (Verified Working):
- K3s v1.31.3-k3s1
- Portainer CE 2.21.4
- Registry 2.8.3
- Registry UI 2.5.7
- PostgreSQL 18.1
- Docker Engine 24.0+
- macOS Sonoma 14.x (ARM64)

## Upgrade Guide

### Upgrade K3s

```bash
# 1. Backup current data
docker run --rm -v k3s_k3s-server-data:/data -v $(pwd):/backup alpine tar czf /backup/k3s-backup-$(date +%Y%m%d).tar.gz -C /data .

# 2. Update version in docker-compose.yaml
# Change: rancher/k3s:v1.29.0-k3s1
# To:     rancher/k3s:v1.31.3-k3s1

# 3. Pull new image
docker compose pull k3s-server

# 4. Restart service
docker compose up -d k3s-server

# 5. Verify
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
kubectl get nodes
kubectl get pods -A
```

### Upgrade PostgreSQL

```bash
# 1. Backup database
docker exec postgres pg_dump -U admin defaultdb > postgres-backup-$(date +%Y%m%d).sql

# 2. Update version in docker-compose.yaml
# Change: postgres:18.1
# To:     postgres:18.3 (or newer)

# 3. Pull new image
docker compose pull postgres

# 4. Restart service
docker compose up -d postgres

# 5. Verify
docker exec -it postgres psql -U admin -d defaultdb -c "SELECT version();"
```

### Upgrade Other Services

```bash
# Pull all new images
docker compose pull

# Restart all services
docker compose up -d

# Verify all running
docker compose ps
```

## Version History

### 2025-11-13: PostgreSQL Added
- PostgreSQL: Added 18.1 (new service)
- **Release Date:** November 13, 2025 (Official PostgreSQL release)
- **Reason:** Add database service for application workloads

### 2025-11-19: Initial Stable Setup
- K3s: v1.29.0-k3s1 → v1.31.3-k3s1
- Portainer: latest → 2.21.4 (pinned)
- Registry: 2 → 2.8.3 (pinned)
- Registry UI: latest → 2.5.7 (pinned)
- **Reason:** Establish stable baseline with pinned versions

## Useful Links

### Official Documentation
- [K3s Documentation](https://docs.k3s.io/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Registry Documentation](https://distribution.github.io/distribution/)
- [Registry UI GitHub](https://github.com/Joxit/docker-registry-ui)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Release Channels
- [K3s Releases](https://github.com/k3s-io/k3s/releases)
- [Portainer Releases](https://github.com/portainer/portainer/releases)
- [Registry Releases](https://github.com/distribution/distribution/releases)
- [Registry UI Releases](https://github.com/Joxit/docker-registry-ui/releases)
- [PostgreSQL Releases](https://www.postgresql.org/support/versioning/)

### Docker Hub
- [rancher/k3s](https://hub.docker.com/r/rancher/k3s)
- [portainer/portainer-ce](https://hub.docker.com/r/portainer/portainer-ce)
- [registry](https://hub.docker.com/_/registry)
- [joxit/docker-registry-ui](https://hub.docker.com/r/joxit/docker-registry-ui)
- [postgres](https://hub.docker.com/_/postgres)

---

**Note:** Always test updates in a non-production environment first!

