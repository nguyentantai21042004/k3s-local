# Version Information

> Last updated: **November 19, 2025**

## Current Stable Versions

| Service | Image | Version | Released | Status |
|---------|-------|---------|----------|--------|
| **K3s** | `rancher/k3s` | `v1.31.3-k3s1` | Oct 2024 | Stable |
| **Portainer CE** | `portainer/portainer-ce` | `2.21.4` | Oct 2024 | Stable |
| **Docker Registry** | `registry` | `2.8.3` | Jul 2024 | Stable |
| **Registry UI** | `joxit/docker-registry-ui` | `2.5.7` | Sep 2024 | Stable |
| **PostgreSQL** | `postgres` | `18.1` | Nov 13, 2025 | Stable |
| **MongoDB** | `mongo` | `8.0` | Nov 2025 | Stable |
| **RabbitMQ** | `rabbitmq` | `4.0-management-alpine` | Oct 2024 | Stable |
| **Redis** | `redis` | `7.4-alpine` | Nov 2024 | Stable |
| **MinIO** | `minio/minio` | `RELEASE.2024-11-07` | Nov 2024 | Stable |

## Version Selection Rationale

All versions are **pinned** (no `latest` tags) for stability and reproducibility.

**K3s v1.31.3** - Latest stable, K8s 1.31, ARM64 optimized  
**Portainer 2.21.4** - Full K8s 1.31 support, enhanced security  
**Registry 2.8.3** - Latest stable v2, security patches, OCI compliant  
**Registry UI 2.5.7** - Modern UI, multi-arch support, image deletion  
**PostgreSQL 18.1** - Latest major version, official release Nov 13 2025  
**MongoDB 8.0** - Latest major, time-series collections, improved aggregation  
**RabbitMQ 4.0** - Latest stable, alpine-based, includes management UI  
**Redis 7.4** - Latest in 7.x series, alpine-based, new data structures  
**MinIO 2024-11-07** - Latest stable, S3-compatible, includes console UI

## Update Schedule

| Component | Check Frequency | Update Strategy |
|-----------|----------------|-----------------|
| K3s | Monthly | Follow Kubernetes release cycle |
| Portainer | Quarterly | Update on major/minor releases |
| Registry | Semi-annually | Update on security patches |
| Registry UI | Quarterly | Update for new features |
| PostgreSQL | Quarterly | Update on security patches |
| MongoDB | Quarterly | Update on security patches |
| RabbitMQ | Quarterly | Update on security patches |
| Redis | Quarterly | Update on security patches |
| MinIO | Quarterly | Update on security patches |

### Before Updating

1. ✅ Check release notes for breaking changes
2. ✅ Backup existing volumes: `make backup`
3. ✅ Test in isolated environment first (if critical)
4. ✅ Verify compatibility between components
5. ✅ Review resource requirements

## Security & CVE Tracking

Monitor security advisories:

- **K3s:** https://github.com/k3s-io/k3s/security/advisories
- **Portainer:** https://github.com/portainer/portainer/security
- **Registry:** https://github.com/distribution/distribution/security
- **Registry UI:** https://github.com/Joxit/docker-registry-ui/security
- **PostgreSQL:** https://www.postgresql.org/support/security/
- **MongoDB:** https://www.mongodb.com/docs/manual/release-notes/
- **RabbitMQ:** https://www.rabbitmq.com/security.html
- **Redis:** https://redis.io/docs/management/security/
- **MinIO:** https://github.com/minio/minio/security

**Security Update Policy:**
- **Critical:** Update immediately
- **High:** Update within 1 week
- **Medium/Low:** Update on regular schedule

## Tested & Verified

**Current Setup** (November 2025):
- K3s v1.31.3-k3s1
- Portainer CE 2.21.4
- Registry 2.8.3
- Registry UI 2.5.7
- PostgreSQL 18.1
- MongoDB 8.0
- RabbitMQ 4.0
- Redis 7.4
- MinIO RELEASE.2024-11-07
- Docker Engine 24.0+
- macOS Sonoma 14.x (ARM64)

## Upgrade Guides

### General Upgrade Process

```bash
# 1. Backup
make backup

# 2. Edit docker-compose.yaml (update version)
nano docker-compose.yaml

# 3. Pull new images
make pull

# 4. Restart services
make up

# 5. Verify
make verify
docker compose ps
```

### K3s Upgrade

```bash
# Backup K3s data
docker run --rm -v k3s_k3s-server-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/k3s-backup-$(date +%Y%m%d).tar.gz -C /data .

# Update in docker-compose.yaml
# Change: rancher/k3s:v1.31.3-k3s1
# To:     rancher/k3s:v1.32.0-k3s1 (or newer)

# Apply
docker compose pull k3s-server
docker compose up -d k3s-server

# Verify
kubectl get nodes
kubectl get pods -A
```

### Database Upgrades

**PostgreSQL:**
```bash
docker exec postgres pg_dump -U admin defaultdb > backup-$(date +%Y%m%d).sql
# Update version, restart
docker compose up -d postgres
docker exec -it postgres psql -U admin -d defaultdb -c "SELECT version();"
```

**MongoDB:**
```bash
docker exec mongodb mongodump --uri="mongodb://admin:pass@localhost:27017/defaultdb" --out=/backup
# Update version, restart
docker compose up -d mongodb
docker exec -it mongodb mongosh --eval "db.version()"
```

**Redis:**
```bash
docker exec redis redis-cli -a password SAVE
# Update version, restart
docker compose up -d redis
docker exec -it redis redis-cli -a password INFO server | grep redis_version
```

### Service Upgrades

**RabbitMQ:**
```bash
# Export definitions
docker exec rabbitmq rabbitmqctl export_definitions /tmp/defs.json
docker cp rabbitmq:/tmp/defs.json ./rabbitmq-backup.json
# Update version, restart, import if needed
```

**MinIO:**
```bash
# Backup via volume or mc client
# Update version, restart
docker compose up -d minio
docker exec -it minio mc ready local
```

## Compatibility Matrix

| K3s Version | Kubernetes | kubectl | Docker API | ARM64 |
|-------------|------------|---------|------------|-------|
| v1.31.3-k3s1 | 1.31.x | 1.30-1.32 | v1.24+ | ✅ Full |
| v1.30.x-k3s1 | 1.30.x | 1.29-1.31 | v1.24+ | ✅ Full |
| v1.29.x-k3s1 | 1.29.x | 1.28-1.30 | v1.24+ | ✅ Full |

## Version History

**2025-11-20:** Added Redis 7.4 + MinIO (v1.5.0)  
**2025-11-20:** Added RabbitMQ 4.0 (v1.4.0)  
**2025-11-20:** Added MongoDB 8.0 (v1.3.0)  
**2025-11-20:** Added PostgreSQL 18.1 (v1.2.0)  
**2025-11-19:** Established baseline with pinned versions (v1.1.0)

See [CHANGELOG.md](../CHANGELOG.md) for detailed history.

## Official Documentation

**Services:**
- [K3s Docs](https://docs.k3s.io/)
- [Portainer Docs](https://docs.portainer.io/)
- [Docker Registry](https://distribution.github.io/distribution/)
- [Registry UI](https://github.com/Joxit/docker-registry-ui)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [MongoDB](https://www.mongodb.com/docs/)
- [RabbitMQ](https://www.rabbitmq.com/docs/)
- [Redis](https://redis.io/docs/)
- [MinIO](https://min.io/docs/)

**Release Channels:**
- [K3s Releases](https://github.com/k3s-io/k3s/releases)
- [Portainer Releases](https://github.com/portainer/portainer/releases)
- [Registry Releases](https://github.com/distribution/distribution/releases)
- [Registry UI Releases](https://github.com/Joxit/docker-registry-ui/releases)
- [PostgreSQL Releases](https://www.postgresql.org/support/versioning/)
- [MongoDB Releases](https://www.mongodb.com/docs/manual/release-notes/)
- [RabbitMQ Releases](https://www.rabbitmq.com/changelog.html)
- [Redis Releases](https://redis.io/download/)
- [MinIO Releases](https://github.com/minio/minio/releases)

**Docker Hub:**
- [rancher/k3s](https://hub.docker.com/r/rancher/k3s)
- [portainer/portainer-ce](https://hub.docker.com/r/portainer/portainer-ce)
- [registry](https://hub.docker.com/_/registry)
- [joxit/docker-registry-ui](https://hub.docker.com/r/joxit/docker-registry-ui)
- [postgres](https://hub.docker.com/_/postgres)
- [mongo](https://hub.docker.com/_/mongo)
- [rabbitmq](https://hub.docker.com/_/rabbitmq)
- [redis](https://hub.docker.com/_/redis)
- [minio/minio](https://hub.docker.com/r/minio/minio)

---

**Note:** Always test updates in non-production environments first!
