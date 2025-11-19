# Quick Reference Card

## 🚀 Common Commands

### Start/Stop Environment

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Stop and remove volumes (⚠️ DATA LOSS!)
docker compose down -v

# Restart specific service
docker compose restart k3s-server

# View logs
docker compose logs -f
docker compose logs -f k3s-server
```

### Kubectl Commands

```bash
# Setup kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Check cluster
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# Deploy application
kubectl apply -f manifest.yaml

# Get resources
kubectl get deployments -A
kubectl get services -A
kubectl get ingress -A
```

### Registry Commands

```bash
# List images in registry
curl http://localhost:5001/v2/_catalog

# Get tags for image
curl http://localhost:5001/v2/IMAGE_NAME/tags/list

# Push image to local registry
docker tag my-app:latest localhost:5001/my-app:latest
docker push localhost:5001/my-app:latest

# Pull from local registry
docker pull localhost:5001/my-app:latest
```

### PostgreSQL Commands

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U admin -d defaultdb

# Run SQL query
docker exec -it postgres psql -U admin -d defaultdb -c "SELECT version();"

# List databases
docker exec -it postgres psql -U admin -c "\l"

# List tables
docker exec -it postgres psql -U admin -d defaultdb -c "\dt"

# Backup database
docker exec postgres pg_dump -U admin defaultdb > backup.sql

# Restore database
docker exec -i postgres psql -U admin defaultdb < backup.sql
```

### MongoDB Commands

```bash
# Connect to MongoDB
docker exec -it mongodb mongosh -u admin -p your_mongo_password_here

# Run MongoDB command
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"

# List databases
docker exec -it mongodb mongosh --eval "db.adminCommand('listDatabases')"

# Use specific database
docker exec -it mongodb mongosh -u admin -p your_mongo_password_here defaultdb

# Backup database
docker exec mongodb mongodump --uri="mongodb://admin:your_mongo_password_here@localhost:27017/defaultdb" --out=/backup

# Restore database
docker exec -i mongodb mongorestore --uri="mongodb://admin:your_mongo_password_here@localhost:27017/defaultdb" /backup/defaultdb
```

### Maintenance Scripts

```bash
# Verify versions
./verify-versions.sh

# Check for updates
./check-updates.sh

# Backup volumes
./backup-volumes.sh
```

### Setup Portainer Agent

```bash
# 1. Setup kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# 2. Deploy Portainer Agent
kubectl apply -f https://downloads.portainer.io/ce2-21/portainer-agent-k8s-nodeport.yaml

# 3. Verify Agent running
kubectl get pods -n portainer
kubectl get svc -n portainer

# 4. Connect in Portainer UI (http://localhost:9000)
#    - Choose "Agent"
#    - Environment address: 172.28.0.10:9001 or k3s-server:9001
```

## 🌐 Access URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Kubernetes API** | https://localhost:6443 | K8s API Server |
| **Portainer** | http://localhost:9000 | Web UI for K8s/Docker |
| **Registry** | http://localhost:5001 | Docker Registry API |
| **Registry UI** | http://localhost:8080 | Registry Web UI |
| **PostgreSQL** | localhost:5432 | PostgreSQL Database |
| **MongoDB** | localhost:27017 | MongoDB NoSQL Database |

## 📊 Resource Allocation

| Service | CPU | RAM | Port(s) |
|---------|-----|-----|---------|
| K3s Server | 3 cores | 4 GB | 6443, 80, 443, 9001, 30000-30100 |
| Portainer | 0.5 core | 256 MB | 9000, 9443 |
| Registry | 0.5 core | 512 MB | 5001 (container: 5000) |
| Registry UI | 0.25 core | 128 MB | 8080 |
| PostgreSQL | 1 core | 1 GB | 5432 |
| MongoDB | 1 core | 1 GB | 27017 |
| **Total** | **~6.25** | **~6.9 GB** | - |

## 📦 Current Versions

```yaml
K3s:         v1.31.3-k3s1      (Kubernetes 1.31)
Portainer:   2.21.4
Registry:    2.8.3
Registry UI: 2.5.7
PostgreSQL:  18.1
MongoDB:      8.0
```

## 🔧 Troubleshooting

### K3s not starting

```bash
# Check logs
docker logs k3s-server

# Restart
docker compose restart k3s-server

# Nuclear option: remove and recreate
docker compose down
docker volume rm k3s_k3s-server-data
docker compose up -d
```

### Kubectl not connecting

```bash
# Verify kubeconfig
cat ./kubeconfig/kubeconfig.yaml

# Check if server is running
docker ps | grep k3s-server

# Test API
curl -k https://localhost:6443

# Regenerate kubeconfig
docker exec k3s-server cat /output/kubeconfig.yaml > ./kubeconfig/kubeconfig.yaml
```

### Registry issues

```bash
# Test registry
curl http://localhost:5001/v2/_catalog

# Check logs
docker logs registry

# Add insecure registry to Docker
# Mac: Docker Desktop > Settings > Docker Engine
# Add: "insecure-registries": ["localhost:5001"]
```

### PostgreSQL issues

```bash
# Check logs
docker logs postgres

# Test connection
docker exec -it postgres psql -U admin -d defaultdb -c "SELECT version();"

# Check health
docker exec -it postgres pg_isready -U admin

# Connect to database
docker exec -it postgres psql -U admin -d defaultdb
```

### MongoDB issues

```bash
# Check logs
docker logs mongodb

# Test connection
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"

# Check health
docker exec -it mongodb mongosh --eval "db.adminCommand('ping')"

# Connect to database
docker exec -it mongodb mongosh -u admin -p your_mongo_password_here
```

### Out of resources

```bash
# Check Docker stats
docker stats

# Check K8s resources
kubectl top nodes
kubectl top pods -A

# Clean up unused images
docker system prune -a

# Clean up unused volumes (⚠️ careful!)
docker volume prune
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | Service definitions |
| `VERSION.md` | Version details & update guide |
| `CHANGELOG.md` | Change history |
| `README.md` | Full documentation |
| `./kubeconfig/kubeconfig.yaml` | kubectl config |
| `.env` | Environment variables (gitignored) |

## 🔄 Backup/Restore

### Quick Backup

```bash
./backup-volumes.sh
```

### Manual Backup

```bash
# Backup specific volume
docker run --rm \
  -v k3s_k3s-server-data:/data:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/k3s-backup.tar.gz -C /data .
```

### Restore

```bash
# Stop services first
docker compose down

# Restore volume
docker run --rm \
  -v k3s_k3s-server-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/k3s-backup.tar.gz"

# Start services
docker compose up -d
```

## 🎯 Common Tasks

### Deploy from Homelab

```bash
# 1. Export manifests from homelab
kubectl get all -n production -o yaml > production.yaml

# 2. Backup images
kubectl get pods -n production -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' > images.txt

# 3. Pull and push to local registry
while read image; do
  docker pull $image
  docker tag $image localhost:5001/${image##*/}
  docker push localhost:5001/${image##*/}
done < images.txt

# 4. Update manifest to use localhost:5001
sed -i '' 's|image: |image: localhost:5001/|g' production.yaml

# 5. Apply to local K3s
kubectl apply -f production.yaml
```

### Test Manifest

```bash
# Dry run
kubectl apply -f manifest.yaml --dry-run=client

# Apply with validation
kubectl apply -f manifest.yaml --validate=true

# Watch deployment
kubectl get pods -w
```

### Inspect Resources

```bash
# Describe resource
kubectl describe pod POD_NAME

# Get YAML
kubectl get pod POD_NAME -o yaml

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📚 Quick Links

- [Full README](README.md)
- [Version Info](VERSION.md)
- [Changelog](CHANGELOG.md)
- [K3s Docs](https://docs.k3s.io/)
- [Portainer Docs](https://docs.portainer.io/)

---

**💡 Tip:** Bookmark this page for quick reference!

