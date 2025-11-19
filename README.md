# K3s Emergency Backup Environment

## Mục đích

Môi trường K3s local này được thiết kế như một **giải pháp backup khẩn cấp** cho cụm Kubernetes đang chạy trên server homelab. Trong trường hợp homelab gặp sự cố, môi trường này cho phép:

- Khôi phục nhanh các workload quan trọng
- Test và validate các manifest trước khi deploy lên production
- Phát triển và debug local với môi trường tương tự homelab
- Lưu trữ images trong registry riêng (không phụ thuộc external registry)

## File Structure

```
k3s/
├── docker-compose.yaml     # Main compose file với pinned versions
├── README.md               # Tài liệu đầy đủ
├── CHANGELOG.md            # Lịch sử thay đổi
├── docs/
│   ├── QUICK_REFERENCE.md  # Quick reference card
│   ├── VERSION.md          # Version chi tiết + update schedule
├── scripts/
│   ├── verify-versions.sh  # Script verify versions
│   ├── check-updates.sh    # Script check for updates
│   └── backup-volumes.sh   # Script backup volumes
├── .gitignore              # Ignore .env file
└── kubeconfig/             # Auto-generated kubeconfig
    └── kubeconfig.yaml
```

## Tài nguyên Máy Hiện tại

**Cấu hình:**
- **RAM:** 24 GB (23GB đang sử dụng, không swap)
- **CPU:** 12 cores (M4 Pro) - ~91% idle
- **Disk:** 100 GB trống

**Phân bổ cho K3s Cluster:**
- **CPU:** 3 cores (dedicated) + 0.5 core (Portainer)
- **RAM:** 4GB (K3s Server) + 256MB (Portainer) = ~4.3GB total
- **Disk:** ~40-80GB cho volumes và images

## Kiến trúc

```
┌─────────────────────────────────────────────┐
│         K3s Single Node (All-in-one)        │
│  ┌──────────────────────────────────────┐   │
│  │    Control Plane + Worker Node       │   │
│  │  - API Server (6443)                 │   │
│  │  - Scheduler                         │   │
│  │  - Controller Manager                │   │
│  │  - Kubelet                           │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
┌───────▼──────┐ ┌──▼──────┐ ┌─▼────────────┐
│  Portainer   │ │ Registry │ │ Registry UI  │
│  (Port 9000) │ │ (5001)   │ │  (8080)      │
└──────────────┘ └──────────┘ └──────────────┘
```

## Components

> **Version Info:** See [docs/VERSION.md](docs/VERSION.md) for detailed version information and update schedule.

### 1. K3s Server (Single Node)
- **Image:** `rancher/k3s:v1.31.3-k3s1` (Kubernetes 1.31)
- **Chế độ:** All-in-one (Control Plane + Worker)
- **Ports:**
  - `6443` - Kubernetes API
  - `80/443` - Ingress HTTP/HTTPS
  - `9001` - Portainer Agent
  - `30000-30100` - NodePort range
- **Resources:** 3 CPUs, 4GB RAM
- **Features:**
  - Traefik disabled (có thể cài NGINX Ingress nếu cần)
  - Kubeconfig tự động export ra `./kubeconfig/kubeconfig.yaml`
  - Port 9001 exposed cho Portainer Agent connection

### 2. Portainer CE
- **Image:** `portainer/portainer-ce:2.21.4`
- **Web UI:** http://localhost:9000
- **Chức năng:** Quản lý K8s và Docker containers qua giao diện web
- **Resources:** 0.5 CPU, 256MB RAM

### 3. Docker Registry
- **Image:** `registry:2.8.3`
- **Port:** Host `5001` → Container `5000`
- **Chức năng:** Private registry để lưu trữ images
- **Use case:** 
  - Backup images từ homelab
  - Push/pull images local không cần internet
  - Đã bật CORS (`Access-Control-Allow-*`) để Registry UI truy cập qua http://localhost:8080

### 4. Registry UI
- **Image:** `joxit/docker-registry-ui:2.5.7`
- **Web UI:** http://localhost:8080
- **Chức năng:** Giao diện web để browse registry images

## Quick Start

### 1. Khởi động môi trường

```bash
# Clone hoặc cd vào folder
cd /Users/tantai/Workspaces/smap/smap-docs/k3s

# (Optional) Verify versions trước khi start
./scripts/verify-versions.sh

# Start bằng Makefile alias (khuyến nghị)
make up            # chạy toàn bộ stack
# Hoặc chỉ chạy từng cặp service:
make up-cluster    # K3s + Portainer
make up-registry   # Registry + Registry UI

# Tạo file .env (optional - có giá trị mặc định)
echo "K3S_TOKEN=k3s-secret-token-2024" > .env

# Start tất cả services
docker compose up -d

# Kiểm tra trạng thái
docker compose ps
```

### 2. Sử dụng kubectl - 2 Cách

K3s cung cấp **2 cách** để chạy kubectl commands:

#### **Cách 1: Exec vào Container** (Khuyến nghị cho Dev/Test)

```bash
# kubectl có sẵn trong container với đúng version
docker exec -it k3s-server kubectl get nodes
docker exec -it k3s-server kubectl get pods -A

# Hoặc vào shell của container luôn
docker exec -it k3s-server sh
# Giờ bạn ở trong container:
kubectl get nodes
kubectl apply -f manifest.yaml
exit
```

**Ưu điểm:**
- Không cần cài kubectl trên máy local
- Version luôn khớp (kubectl = K3s server version)
- Đơn giản, không lo conflict

#### **Cách 2: kubectl từ Máy Local** (Chuẩn Production)

```bash
# Export KUBECONFIG
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Kiểm tra kết nối
kubectl get nodes
kubectl get pods -A
```

**Ưu điểm:**
- Quản lý cluster từ xa (remote management)
- Tích hợp với CI/CD, automation scripts
- Dùng kubectl plugins, tools khác

**Yêu cầu:**
- kubectl version phải tương thích với K3s (không chênh lệch quá 1 minor version)
- K3s v1.31.3 → kubectl v1.30.x, v1.31.x, hoặc v1.32.x đều OK

**Troubleshooting:**

Nếu gặp lỗi `the server could not find the requested resource`:

```bash
# 1. Kiểm tra server URL trong kubeconfig
cat $(pwd)/kubeconfig/kubeconfig.yaml | grep server:

# 2. Nếu thấy: server: https://k3s-server:6443
#    Cần đổi thành: server: https://127.0.0.1:6443
sed -i '' 's/https:\/\/k3s-server:6443/https:\/\/127.0.0.1:6443/g' $(pwd)/kubeconfig/kubeconfig.yaml

# 3. Test lại
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
kubectl get nodes
```

> Giải thích: K3s auto-generate kubeconfig có thể dùng `k3s-server` (container name) làm server URL. Tên này chỉ resolve được trong Docker network, không resolve được từ host machine. Cần đổi thành `127.0.0.1` để connect từ máy Mac.

---

#### Cơ chế hoạt động của Cách 2:

Kubernetes sử dụng Client-Server Architecture qua REST API:

```
┌──────────────────────────────────────────────────────┐
│              Máy Mac của bạn (Client)                │
│                                                      │
│  kubectl ──► Đọc kubeconfig.yaml                   │
│      │       (chứa: API endpoint, certs, keys)      │
│      │                                               │
│      └──► Gọi HTTPS REST API                        │
└──────────────────────┬───────────────────────────────┘
                       │
                       │ Network (qua port 6443)
                       │ HTTPS + TLS Certificates
                       ▼
┌──────────────────────────────────────────────────────┐
│         Container k3s-server (API Server)            │
│                                                      │
│  K3s API Server ◄── Listen trên 0.0.0.0:6443       │
│       │             Exposed ra: localhost:6443       │
│       │                                               │
│       └──► Xử lý request, trả về JSON response      │
└──────────────────────────────────────────────────────┘
```

**Chi tiết:**

1. K3s expose API Server:
   ```yaml
   ports:
     - "6443:6443"  # Kubernetes API Server
   ```

2. kubeconfig.yaml chứa thông tin kết nối:
   ```yaml
   apiVersion: v1
   clusters:
   - cluster:
       server: https://127.0.0.1:6443  # Địa chỉ API
       certificate-authority-data: ...  # CA cert
   users:
   - user:
       client-certificate-data: ...     # Client cert
       client-key-data: ...             # Private key
   ```

3. kubectl gọi API qua HTTPS:
   ```bash
   kubectl get nodes
   # Thực chất tương đương:
   # curl -k https://localhost:6443/api/v1/nodes \
   #   --cert client.crt --key client.key --cacert ca.crt
   ```

**Ví dụ thực tế:**
- Google Kubernetes Engine (GKE): cluster ở cloud, kubectl trên laptop
- Amazon EKS: tương tự
- Homelab: K8s ở server nhà, quản lý từ laptop
- Setup này: K3s trong container, kubectl từ Mac qua localhost:6443

> Lưu ý: Đây là cách Kubernetes được thiết kế từ đầu - remote management qua API!

---

### 3. Setup Portainer kết nối K3s (Lần đầu)

#### Bước 1: Tạo admin account

```bash
# Mở browser tại http://localhost:9000
# Tạo username và password cho admin
```

#### Bước 2: Deploy Portainer Agent vào K3s

```bash
# Ensure KUBECONFIG đã được set
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Deploy Portainer Agent (dùng NodePort)
kubectl apply -f https://downloads.portainer.io/ce2-21/portainer-agent-k8s-nodeport.yaml

# Kiểm tra Agent đã chạy
kubectl get pods -n portainer
kubectl get svc -n portainer
```

#### Bước 3: Kết nối Portainer với K3s

Quay lại Portainer UI (http://localhost:9000):

1. Click "Get Started" hoặc "Add Environment"
2. Chọn "Agent"
3. Điền thông tin:
   - Name: `k3s-local` (hoặc tên bạn muốn)
   - Environment address: 
     - Thử: `172.28.0.10:9001` (K3s server IP trong Docker network)
     - Hoặc: `k3s-server:9001` (Docker service name)
     - Hoặc: `host.docker.internal:9001` (nếu trên Mac)
4. Click "Connect"

#### Bước 4: Verify kết nối

```bash
# Xem resources trong Portainer UI:
# - Namespaces
# - Deployments
# - Services
# - Pods

# Hoặc dùng kubectl để so sánh
kubectl get all -A
```

> Lưu ý: "Import kubeconfig" là Business Feature (trả phí). Dùng "Agent" là cách miễn phí để quản lý K8s cluster.

## Quy trình Backup từ Homelab

### A. Backup Manifests

```bash
# 1. Export tất cả resources từ homelab
kubectl get all --all-namespaces -o yaml > homelab-backup.yaml

# 2. Export từng namespace cụ thể
kubectl get all -n production -o yaml > production-ns.yaml

# 3. Backup ConfigMaps và Secrets
kubectl get configmap --all-namespaces -o yaml > configmaps.yaml
kubectl get secret --all-namespaces -o yaml > secrets.yaml
```

### B. Backup Container Images

```bash
# 1. List images đang chạy trên homelab
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u > images.txt

# 2. Pull images về máy local
while read image; do
  docker pull $image
done < images.txt

# 3. Tag và push lên local registry
while read image; do
  # Tag image với local registry
  docker tag $image localhost:5001/$(basename $image)
  
  # Push to local registry
  docker push localhost:5001/$(basename $image)
done < images.txt
```

### C. Khôi phục trên K3s Local

```bash
# 1. Apply manifests (cần sửa image URLs nếu dùng local registry)
kubectl apply -f production-ns.yaml

# 2. Kiểm tra pods
kubectl get pods -n production -w

# 3. Debug nếu có lỗi
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

## Troubleshooting

### K3s không start được

```bash
# Check logs
docker logs k3s-server

# Restart service
docker compose restart k3s-server

# Nếu vẫn lỗi, xóa volume và start lại
docker compose down -v
docker compose up -d
```

### Kubectl không kết nối được

```bash
# Kiểm tra kubeconfig
cat ./kubeconfig/kubeconfig.yaml

# Ensure container đang chạy
docker ps | grep k3s

# Test connection
curl -k https://localhost:6443
```

### Registry không accessible

```bash
# Test registry
curl http://localhost:5001/v2/_catalog

# Add insecure registry (nếu cần)
# Mac: Docker Desktop > Settings > Docker Engine
# Add: "insecure-registries": ["localhost:5001"]
```

## Monitoring Resources

```bash
# Docker stats
docker stats

# K3s resource usage
kubectl top nodes
kubectl top pods -A

# Disk usage
docker system df
```

## Security Notes

**Lưu ý:** Đây là môi trường local/backup, KHÔNG dùng cho production:

- Registry không có authentication
- Kubeconfig có permissions 644 (readable by all)
- Sử dụng token mặc định cho K3s
- Không có TLS cho internal communication

Để production-ready, cần:
- Enable registry authentication
- Secure kubeconfig permissions
- Use proper TLS certificates
- Implement RBAC policies

## Tài liệu tham khảo

- [K3s Official Docs](https://docs.k3s.io/)
- [Portainer K8s](https://docs.portainer.io/user/kubernetes)
- [Docker Registry](https://docs.docker.com/registry/)

## Maintenance Scripts

Môi trường này đi kèm với các utility scripts để quản lý:

### Verify Versions

```bash
# Kiểm tra versions trong docker-compose match với VERSION.md
./scripts/verify-versions.sh
```

### Check for Updates

```bash
# Kiểm tra và pull versions mới nhất
./scripts/check-updates.sh
```

### Backup Volumes

```bash
# Backup tất cả volumes vào ./backups/
./scripts/backup-volumes.sh

# Backups được lưu với timestamp và giữ 5 bản gần nhất
# Format: ./backups/YYYYMMDD_HHMMSS/
```

## Manual Maintenance

### Manual Backup

```bash
# Backup K3s data
docker run --rm -v k3s_k3s-server-data:/data -v $(pwd):/backup alpine tar czf /backup/k3s-data-backup.tar.gz -C /data .

# Backup Registry data
docker run --rm -v k3s_registry-data:/data -v $(pwd):/backup alpine tar czf /backup/registry-data-backup.tar.gz -C /data .
```

### Manual Update

```bash
# 1. Backup trước khi update
make backup

# 2. Update image version trong docker-compose.yaml
# Xem docs/VERSION.md để biết versions mới nhất

# 3. Pull new images
make pull

# 4. Restart services
make up

# 5. Verify
make verify
kubectl get nodes
```

## Makefile Aliases

Makefile giúp bạn alias các cặp service theo vai trò:

| Target | Service | Vai trò |
|--------|---------|---------|
| `make up` | K3s + Portainer + Registry + Registry UI | Full stack |
| `make up-cluster` | K3s + Portainer | Điều hành cụm K3s + UI quản trị |
| `make up-registry` | Registry + Registry UI | Kho image + giao diện |
| `make logs-cluster` | K3s + Portainer | Theo dõi log cụm |
| `make logs-registry` | Registry pair | Theo dõi log registry |
| `make verify` | scripts/verify-versions.sh | Check versions |
| `make updates` | scripts/check-updates.sh | Kiểm tra version mới |
| `make backup` | scripts/backup-volumes.sh | Backup volumes |
| `make down` / `make nuke` | Toàn bộ stack / + xóa volumes | Dọn môi trường |

Chạy `make help` để xem đầy đủ các alias khác.

## Support

Nếu có vấn đề:
1. Check logs: `docker compose logs -f`
2. Check K8s events: `kubectl get events --all-namespaces`
3. Verify resources: `docker stats`

---
**Last Updated:** November 2025  
**Maintained by:** TanTai  
**Purpose:** Emergency backup environment for homelab K8s cluster
