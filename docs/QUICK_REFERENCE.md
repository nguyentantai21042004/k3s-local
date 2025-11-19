# Quick Reference

> Fast command reference for K3s Local Environment

## 🚀 Core Commands

### Makefile Shortcuts

```bash
# Start services
make up              # All services
make up-cluster      # K3s + Portainer  
make up-db           # PostgreSQL + MongoDB
make up-mq           # RabbitMQ
make up-cache        # Redis
make up-storage      # MinIO

# Logs
make logs-cluster
make logs-db

# Maintenance
make verify          # Check versions
make backup          # Backup volumes
make updates         # Check updates

# Stop
make down            # Stop all
make nuke            # Stop + remove volumes
```

### Docker Compose Direct

```bash
docker compose up -d                    # Start all
docker compose ps                       # Status
docker compose logs -f <service>        # Logs
docker compose restart <service>        # Restart
docker compose down                     # Stop
docker compose down -v                  # Stop + remove volumes
```

## 📊 Service Info

| Service | Port | URL/Connection |
|---------|------|----------------|
| K3s API | 6443 | https://localhost:6443 |
| Portainer | 9000 | http://localhost:9000 |
| Registry | 5001 | localhost:5001 |
| Registry UI | 8080 | http://localhost:8080 |
| PostgreSQL | 5432 | localhost:5432 |
| MongoDB | 27017 | localhost:27017 |
| RabbitMQ (AMQP) | 5672 | localhost:5672 |
| RabbitMQ UI | 15672 | http://localhost:15672 |
| Redis | 6379 | localhost:6379 |
| MinIO API | 9002 | http://localhost:9002 |
| MinIO Console | 9003 | http://localhost:9003 |

**Default Credentials:** See `.env.example`

## ☸️ Kubernetes (K3s)

### Kubectl Setup

```bash
# Method 1: Via container (recommended)
docker exec -it k3s-server kubectl get nodes

# Method 2: From host
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
kubectl get nodes
```

### Common K8s Commands

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
kubectl logs <pod> -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl exec -it <pod> -n <namespace> -- sh
```

## 🗄️ Databases

### PostgreSQL

```bash
# Connect
docker exec -it postgres psql -U admin -d defaultdb

# Query
docker exec -it postgres psql -U admin -d defaultdb -c "SELECT version();"

# Backup/Restore
docker exec postgres pg_dump -U admin defaultdb > backup.sql
docker exec -i postgres psql -U admin defaultdb < backup.sql
```

### MongoDB

```bash
# Connect
docker exec -it mongodb mongosh -u admin -p <password>

# Commands
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"
docker exec -it mongodb mongosh --eval "db.adminCommand('listDatabases')"

# Backup/Restore
docker exec mongodb mongodump --uri="mongodb://admin:<pass>@localhost:27017/defaultdb" --out=/backup
docker exec -i mongodb mongorestore --uri="mongodb://admin:<pass>@localhost:27017/defaultdb" /backup/defaultdb
```

### Redis

```bash
# Connect
docker exec -it redis redis-cli -a <password>

# Commands
docker exec -it redis redis-cli -a <password> SET key value
docker exec -it redis redis-cli -a <password> GET key
docker exec -it redis redis-cli -a <password> KEYS "*"
```

## 📦 Registry

```bash
# List images
curl http://localhost:5001/v2/_catalog

# Push image
docker tag my-app:latest localhost:5001/my-app:latest
docker push localhost:5001/my-app:latest

# Pull image
docker pull localhost:5001/my-app:latest
```

## 📨 RabbitMQ

**Management UI:** http://localhost:15672 (admin / password)

```bash
# CLI commands
docker exec -it rabbitmq rabbitmqctl list_queues
docker exec -it rabbitmq rabbitmqctl list_exchanges
docker exec -it rabbitmq rabbitmqctl list_users

# Export/Import definitions
docker exec rabbitmq rabbitmqctl export_definitions /tmp/definitions.json
docker cp rabbitmq:/tmp/definitions.json ./rabbitmq-backup.json
```

## 🪣 MinIO

**Console UI:** http://localhost:9003 (admin / password)

```bash
# Configure client
docker exec -it minio mc alias set local http://localhost:9000 admin <password>

# List buckets
docker exec -it minio mc ls local

# Create bucket
docker exec -it minio mc mb local/mybucket

# Upload/Download
docker exec -i minio mc cp /path/to/file local/mybucket/
docker exec -it minio mc cp local/mybucket/file /path/to/dest
```

## 🔧 Troubleshooting

### Service Not Starting

```bash
# Check logs
docker logs <container-name>

# Restart
docker compose restart <service>

# Full reset
docker compose down
docker volume rm <volume-name>
docker compose up -d
```

### K3s API Not Accessible

```bash
# Fix kubeconfig server URL
sed -i '' 's/https:\/\/k3s-server:6443/https:\/\/127.0.0.1:6443/g' kubeconfig/kubeconfig.yaml

# Test
curl -k https://localhost:6443
```

### Container Health Check Failed

```bash
# Check health status
docker inspect <container> | grep -A 10 Health

# Manual health check
# PostgreSQL
docker exec postgres pg_isready -U admin

# MongoDB  
docker exec mongodb mongosh --eval "db.adminCommand('ping')"

# RabbitMQ
docker exec rabbitmq rabbitmq-diagnostics -q ping

# Redis
docker exec redis redis-cli -a <password> ping

# MinIO
docker exec minio mc ready local
```

### Out of Resources

```bash
# Check resource usage
docker stats

# K8s resource usage (if metrics-server installed)
kubectl top nodes
kubectl top pods -A

# Clean up
docker system prune -a              # Remove unused images
docker volume prune                 # Remove unused volumes (careful!)
docker system df                    # Check disk usage
```

### Network Issues

```bash
# Check network
docker network inspect k3s_k3s-network

# Check container IPs
docker inspect <container> | grep IPAddress

# Test connectivity between containers
docker exec k3s-server ping postgres
docker exec k3s-server ping mongodb
```

## 💾 Backup & Restore

### Automated Backup

```bash
# Backup all volumes
make backup
# Or: ./scripts/backup-volumes.sh

# Backups stored in ./backups/YYYYMMDD_HHMMSS/
# Keeps last 5 backups
```

### Manual Backup

```bash
# Backup specific volume
docker run --rm \
  -v k3s_postgres-data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Restore volume
docker run --rm \
  -v k3s_postgres-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/postgres-backup.tar.gz"
```

## 📚 Documentation Links

- [README](../README.md) - Main documentation
- [Vietnamese Docs](README_VI.md) - Tài liệu tiếng Việt
- [Version Guide](VERSION.md) - Detailed version info
- [K3s Integration](K3S_INTEGRATION.md) - Networking guide (TBD)
- [Changelog](../CHANGELOG.md) - Version history

## 🆘 Need Help?

```bash
# Check all service status
docker compose ps

# View all logs
docker compose logs -f

# Get help on Makefile commands
make help

# Verify versions
make verify
```

---

**Tip:** Bookmark this page for quick access to common commands!
