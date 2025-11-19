# K3s Local - Tài liệu Tiếng Việt

> [English](../README.md) | **Tiếng Việt**

Môi trường K3s local được thiết kế như một **giải pháp phát triển và backup khẩn cấp** cho cụm Kubernetes homelab.

## Mục đích

Trong trường hợp homelab gặp sự cố hoặc cần môi trường phát triển local, hệ thống này cung cấp:

- ✅ Khôi phục nhanh các workload quan trọng
- ✅ Test và validate manifests trước khi deploy production
- ✅ Phát triển và debug với môi trường tương tự homelab
- ✅ Lưu trữ images trong private registry (không phụ thuộc external registry)
- ✅ Đầy đủ services backend (database, cache, message broker, storage)

## Các Service Được Cung Cấp

| Service | Version | Ports | Tài nguyên | Mô tả |
|---------|---------|-------|------------|-------|
| **K3s Server** | v1.31.3 | 6443, 80, 443, 30000-30100 | 3 CPUs, 4GB | Kubernetes cluster (All-in-one) |
| **Portainer CE** | 2.21.4 | 9000, 9443 | 0.5 CPU, 256MB | Web UI quản lý K8s/Docker |
| **Registry** | 2.8.3 | 5001 | 0.5 CPU, 512MB | Private Docker registry |
| **Registry UI** | 2.5.7 | 8080 | 0.25 CPU, 128MB | Giao diện browse registry |
| **PostgreSQL** | 18.1 | 5432 | 1 CPU, 1GB | SQL database |
| **MongoDB** | 8.0 | 27017 | 1 CPU, 1GB | NoSQL database |
| **RabbitMQ** | 4.0 | 5672, 15672 | 1 CPU, 1GB | Message broker + Management UI |
| **Redis** | 7.4 | 6379 | 0.5 CPU, 512MB | In-memory cache/database |
| **MinIO** | 2024-11-07 | 9002, 9003 | 1 CPU, 1GB | S3-compatible object storage |

**Tổng tài nguyên:** ~8.75 CPUs, ~9.4GB RAM

## Yêu cầu Hệ thống

- **CPU:** 12 cores khuyến nghị (M4 Pro hoặc tương đương)
- **RAM:** 24GB khuyến nghị (tối thiểu 16GB)
- **Disk:** 50GB+ trống
- **Docker:** Desktop 24.0+ với Docker Compose
- **OS:** macOS (M-series/Intel), Linux, hoặc Windows với WSL2

## Cài đặt & Khởi động

### 1. Clone Repository

```bash
cd /path/to/your/workspace
git clone <repo-url> k3s-local
cd k3s-local
```

### 2. Cấu hình Environment Variables

```bash
# Copy file mẫu
cp .env.example .env

# Chỉnh sửa passwords
nano .env  # hoặc vim, code, etc.
```

**Các biến quan trọng cần đổi:**
- `POSTGRES_PASSWORD` - PostgreSQL password
- `MONGO_INITDB_ROOT_PASSWORD` - MongoDB password
- `RABBITMQ_DEFAULT_PASS` - RabbitMQ password
- `REDIS_PASSWORD` - Redis password
- `MINIO_ROOT_PASSWORD` - MinIO secret key

### 3. Verify Versions

```bash
# Kiểm tra versions trước khi start
./scripts/verify-versions.sh
```

### 4. Khởi động Services

```bash
# Start toàn bộ stack
make up

# Hoặc dùng docker compose trực tiếp
docker compose up -d

# Kiểm tra trạng thái
docker compose ps
make status
```

### 5. Verify Health

```bash
# Xem logs
docker compose logs -f

# Kiểm tra K3s
docker exec -it k3s-server kubectl get nodes
docker exec -it k3s-server kubectl get pods -A
```

## Sử dụng Kubectl

K3s cung cấp 2 cách để chạy kubectl commands:

### Cách 1: Exec vào Container (Khuyến nghị cho Dev/Test)

```bash
# kubectl có sẵn trong container
docker exec -it k3s-server kubectl get nodes
docker exec -it k3s-server kubectl get pods -A
docker exec -it k3s-server kubectl apply -f manifest.yaml

# Hoặc vào shell của container
docker exec -it k3s-server sh
kubectl get nodes
exit
```

**Ưu điểm:**
- ✅ Không cần cài kubectl trên máy local
- ✅ Version luôn khớp với K3s server
- ✅ Đơn giản, không lo conflict

### Cách 2: kubectl từ Máy Local (Production-ready)

```bash
# Export KUBECONFIG
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Kiểm tra kết nối
kubectl get nodes
kubectl get pods -A

# Áp dụng manifests
kubectl apply -f your-app.yaml
```

**Ưu điểm:**
- ✅ Quản lý cluster từ xa (remote management)
- ✅ Tích hợp với CI/CD, automation
- ✅ Dùng kubectl plugins

**Troubleshooting:**

Nếu gặp lỗi `connection refused` hoặc `server not found`:

```bash
# Fix server URL trong kubeconfig
sed -i '' 's/https:\/\/k3s-server:6443/https:\/\/127.0.0.1:6443/g' kubeconfig/kubeconfig.yaml

# Test lại
kubectl get nodes
```

> **Giải thích:** K3s auto-generate kubeconfig với server URL là `k3s-server` (container name). Tên này chỉ resolve được trong Docker network. Cần đổi thành `127.0.0.1` để connect từ host machine.

## Quản lý Services theo Nhóm

Makefile cung cấp các commands để quản lý theo nhóm:

### Khởi động theo nhóm

```bash
make up-cluster     # K3s + Portainer
make up-registry    # Registry + Registry UI
make up-db          # PostgreSQL + MongoDB
make up-mq          # RabbitMQ
make up-cache       # Redis
make up-storage     # MinIO
```

### Xem logs theo nhóm

```bash
make logs-cluster
make logs-db
make logs-mq
```

### Restart/Stop theo nhóm

```bash
make restart-db
make down-db
```

## Setup Portainer kết nối K3s

### Bước 1: Tạo Admin Account

```bash
# Mở browser
open http://localhost:9000

# Tạo username và password cho admin
```

### Bước 2: Deploy Portainer Agent vào K3s

```bash
# Export KUBECONFIG
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Deploy Agent
kubectl apply -f https://downloads.portainer.io/ce2-21/portainer-agent-k8s-nodeport.yaml

# Verify
kubectl get pods -n portainer
kubectl get svc -n portainer
```

### Bước 3: Kết nối Portainer với K3s

Trong Portainer UI (http://localhost:9000):

1. Click **"Get Started"** hoặc **"Add Environment"**
2. Chọn **"Agent"**
3. Điền thông tin:
   - **Name:** `k3s-local`
   - **Environment address:** `172.28.0.10:9001` hoặc `k3s-server:9001`
4. Click **"Connect"**

> **Lưu ý:** "Import kubeconfig" là tính năng trả phí. Dùng "Agent" để quản lý miễn phí.

## Kết nối đến Services

### PostgreSQL

```bash
# Via docker exec
docker exec -it postgres psql -U admin -d defaultdb

# Via host machine (cần cài psql)
psql -h localhost -p 5432 -U admin -d defaultdb

# Connection string
postgresql://admin:your_password@localhost:5432/defaultdb
```

### MongoDB

```bash
# Via docker exec
docker exec -it mongodb mongosh -u admin -p your_mongo_password_here

# Connection string
mongodb://admin:your_mongo_password_here@localhost:27017/defaultdb
```

### RabbitMQ

- **AMQP:** `amqp://admin:your_rabbitmq_password_here@localhost:5672/`
- **Management UI:** http://localhost:15672 (login: admin / your_rabbitmq_password_here)

### Redis

```bash
# Via docker exec
docker exec -it redis redis-cli -a your_redis_password_here

# Connection string
redis://:your_redis_password_here@localhost:6379
```

### MinIO

- **API:** http://localhost:9002
- **Console:** http://localhost:9003 (login: admin / your_minio_password_here)
- **S3 endpoint:** http://localhost:9002

## Backup & Restore

### Backup Tất cả Volumes

```bash
# Sử dụng script tự động
make backup
# hoặc
./scripts/backup-volumes.sh

# Backups được lưu tại ./backups/YYYYMMDD_HHMMSS/
# Giữ 5 bản backup gần nhất
```

### Backup từ Homelab

#### A. Backup Kubernetes Manifests

```bash
# Export tất cả resources
kubectl get all --all-namespaces -o yaml > homelab-backup.yaml

# Export từng namespace
kubectl get all -n production -o yaml > production-ns.yaml

# Backup ConfigMaps và Secrets
kubectl get configmap --all-namespaces -o yaml > configmaps.yaml
kubectl get secret --all-namespaces -o yaml > secrets.yaml
```

#### B. Backup Container Images

```bash
# 1. List images đang chạy
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u > images.txt

# 2. Pull images về máy local
while read image; do
  docker pull $image
done < images.txt

# 3. Tag và push lên local registry
while read image; do
  docker tag $image localhost:5001/$(basename $image)
  docker push localhost:5001/$(basename $image)
done < images.txt
```

#### C. Restore trên K3s Local

```bash
# 1. Sửa image URLs trong manifests (nếu dùng local registry)
sed -i '' 's|image: docker.io|image: localhost:5001|g' production-ns.yaml

# 2. Apply manifests
kubectl apply -f production-ns.yaml

# 3. Monitor pods
kubectl get pods -n production -w

# 4. Debug nếu cần
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

## Maintenance

### Kiểm tra Versions

```bash
# Verify versions match VERSION.md
make verify
# hoặc
./scripts/verify-versions.sh
```

### Kiểm tra Updates

```bash
# Check for available updates
make updates
# hoặc
./scripts/check-updates.sh
```

### Update Services

```bash
# 1. Backup trước khi update
make backup

# 2. Sửa version trong docker-compose.yaml
# Xem docs/VERSION.md để biết versions mới nhất

# 3. Pull new images
make pull

# 4. Restart services
make up

# 5. Verify
make verify
kubectl get nodes
```

## Troubleshooting

### K3s không start được

```bash
# Check logs
docker logs k3s-server

# Restart service
make restart-cluster

# Nếu vẫn lỗi, reset hoàn toàn
make nuke  # ⚠️ Xóa tất cả data
make up
```

### Service không kết nối được

```bash
# Kiểm tra container đang chạy
docker compose ps

# Xem logs của service
docker logs <service-name>

# Restart service
docker compose restart <service-name>

# Kiểm tra network
docker network inspect k3s_k3s-network
```

### Hết resources

```bash
# Xem resource usage
docker stats

# K8s resource usage
kubectl top nodes
kubectl top pods -A

# Clean up
docker system prune -a
docker volume prune  # ⚠️ Cẩn thận, xóa volumes không dùng
```

### Registry không accessible

```bash
# Test registry
curl http://localhost:5001/v2/_catalog

# Thêm insecure registry (nếu cần)
# Mac: Docker Desktop > Settings > Docker Engine
# Add: "insecure-registries": ["localhost:5001"]
```

## Security Notes

⚠️ **Đây là môi trường local/backup, KHÔNG dùng cho production:**

- Registry không có authentication
- Kubeconfig có permissions 644
- Sử dụng passwords mặc định trong .env.example
- Không có TLS cho internal communication

**Để production-ready, cần:**
- Enable registry authentication
- Secure kubeconfig permissions (600)
- Sử dụng secrets management (Vault, Sealed Secrets)
- Implement network policies
- Cấu hình TLS certificates
- Enable RBAC policies

## Monitoring Resources

```bash
# Docker stats real-time
docker stats

# K8s metrics (cần cài metrics-server)
kubectl top nodes
kubectl top pods -A

# Disk usage
docker system df
df -h
```

## Tài liệu Tham khảo

### Internal Docs
- [Quick Reference](QUICK_REFERENCE.md) - Commands và troubleshooting
- [Version Guide](VERSION.md) - Chi tiết versions và upgrade guides
- [K3s Integration](K3S_INTEGRATION.md) - Networking và service communication (Đang cập nhật)
- [Changelog](../CHANGELOG.md) - Lịch sử thay đổi

### External Docs
- [K3s Official Docs](https://docs.k3s.io/)
- [Portainer Kubernetes](https://docs.portainer.io/user/kubernetes)
- [Docker Registry](https://docs.docker.com/registry/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [MongoDB Docs](https://www.mongodb.com/docs/)
- [RabbitMQ Docs](https://www.rabbitmq.com/docs/)
- [Redis Docs](https://redis.io/docs/)
- [MinIO Docs](https://min.io/docs/)

## Câu hỏi Thường gặp

**Q: Tôi có thể chạy trên Windows không?**  
A: Có, nhưng cần Windows 11 với WSL2. Một số script có thể cần điều chỉnh.

**Q: Services giao tiếp với nhau như thế nào?**  
A: Xem [K3S_INTEGRATION.md](K3S_INTEGRATION.md) để hiểu về networking.

**Q: Tôi có thể thêm services khác không?**  
A: Có, chỉnh sửa `docker-compose.yaml` và cập nhật Makefile.

**Q: Làm sao để services trong K8s connect đến database?**  
A: Sử dụng fixed IP hoặc service name. Xem [K3S_INTEGRATION.md](K3S_INTEGRATION.md).

---

**Tác giả:** TanTai  
**Cập nhật:** November 2025  
**Mục đích:** Môi trường phát triển K3s local và backup khẩn cấp cho homelab

