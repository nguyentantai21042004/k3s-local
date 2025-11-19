# K3s Integration & Networking Guide

> How K3s workloads communicate with external services (databases, caching, storage)

## Overview

This environment runs **K3s inside a Docker container** on the same Docker network as supporting services (PostgreSQL, MongoDB, Redis, etc.). Understanding how they communicate is crucial for deploying applications.

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Docker Network: k3s-network                    │
│                       Bridge (172.28.0.0/16)                     │
│                                                                  │
│  ┌─────────────────┐                                            │
│  │  k3s-server     │  ← K3s runs inside this container         │
│  │  172.28.0.10    │                                            │
│  │                 │                                            │
│  │  ┌───────────┐  │                                            │
│  │  │ Pod A     │  │  ← Your app pods run INSIDE K3s          │
│  │  │ 10.42.x.x │  │     (K8s internal network)                │
│  │  └───────────┘  │                                            │
│  └─────────────────┘                                            │
│          │                                                       │
│          │ Need to connect to services outside K3s ↓           │
│          │                                                       │
│  ┌───────┴────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ PostgreSQL │  │ MongoDB  │  │ Redis    │  │ RabbitMQ │    │
│  │ 172.28.0.50│  │172.28.0.60│  │172.28.0.80│  │172.28.0.70│    │
│  └────────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │ Registry │  │ Portainer│  │ MinIO    │                     │
│  │172.28.0.40│  │172.28.0.30│  │172.28.0.90│                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
└─────────────────────────────────────────────────────────────────┘
         ↑                                           ↑
         │                                           │
    Host Machine                            External Access
   (Mac/Linux/Win)                       (via exposed ports)
```

## Key Concepts

### 1. Why `localhost` Doesn't Work

**❌ This WILL NOT work inside K8s pods:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: my-app:latest
    env:
    - name: DB_HOST
      value: "localhost"  # ❌ Wrong! localhost = pod itself
    - name: DB_PORT
      value: "5432"
```

**Why?**
- `localhost` inside a pod refers to **that pod's network namespace**, not the host machine
- The database runs in a **different container** (postgres) on the Docker network
- Pods are isolated from the Docker network by default

### 2. How Pods Connect to External Services

**✅ Method 1: Use Docker Service Names** (Recommended)

```yaml
env:
- name: DB_HOST
  value: "postgres"  # ✅ Docker service name
- name: DB_PORT
  value: "5432"
```

K3s container can resolve Docker service names (e.g., `postgres`) to their IPs because they're on the same Docker network.

**✅ Method 2: Use Fixed IPs**

```yaml
env:
- name: DB_HOST
  value: "172.28.0.50"  # ✅ PostgreSQL's fixed IP
- name: DB_PORT
  value: "5432"
```

More explicit but requires knowing IPs. See `docker-compose.yaml` for IP assignments.

**✅ Method 3: Kubernetes Service with ExternalName** (Most K8s-native)

See [Working Examples](#working-examples) below.

## Service IP Reference

| Service | Fixed IP | Container Name | Ports |
|---------|----------|----------------|-------|
| K3s Server | 172.28.0.10 | k3s-server | 6443, 80, 443 |
| Portainer | 172.28.0.30 | portainer | 9000, 9443 |
| Registry | 172.28.0.40 | registry | 5000 (internal) |
| Registry UI | 172.28.0.41 | registry-ui | 80 (internal) |
| PostgreSQL | 172.28.0.50 | postgres | 5432 |
| MongoDB | 172.28.0.60 | mongodb | 27017 |
| RabbitMQ | 172.28.0.70 | rabbitmq | 5672, 15672 |
| Redis | 172.28.0.80 | redis | 6379 |
| MinIO | 172.28.0.90 | minio | 9000, 9001 |

## Working Examples

### Example 1: Deploy App Connecting to PostgreSQL

#### Step 1: Create Kubernetes Secret for Credentials

```bash
kubectl create secret generic postgres-credentials \
  --from-literal=username=admin \
  --from-literal=password=your_secure_password_here \
  --from-literal=database=defaultdb
```

Or from YAML:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  username: admin
  password: your_secure_password_here
  database: defaultdb
```

#### Step 2: Create Service with ExternalName (Optional but recommended)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-external
spec:
  type: ExternalName
  externalName: postgres  # Docker service name
  ports:
  - port: 5432
```

Apply: `kubectl apply -f postgres-service.yaml`

#### Step 3: Deploy Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: localhost:5001/my-app:latest  # ✅ Use local registry
        ports:
        - containerPort: 8080
        env:
        # Method 1: Direct Docker service name
        - name: DB_HOST
          value: "postgres"
        - name: DB_PORT
          value: "5432"
        
        # Method 2: Via ExternalName service (if created)
        # - name: DB_HOST
        #   value: "postgres-external"
        
        # Method 3: Direct IP (less flexible)
        # - name: DB_HOST
        #   value: "172.28.0.50"
        
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: database
```

Apply: `kubectl apply -f app-deployment.yaml`

### Example 2: Multi-Service Application (PostgreSQL + Redis + RabbitMQ)

#### ConfigMap for Service Endpoints

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-endpoints
data:
  postgres.host: "postgres"
  postgres.port: "5432"
  redis.host: "redis"
  redis.port: "6379"
  rabbitmq.host: "rabbitmq"
  rabbitmq.port: "5672"
  minio.endpoint: "http://minio:9000"
```

#### Secrets for Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: service-credentials
type: Opaque
stringData:
  postgres.username: "admin"
  postgres.password: "your_secure_password_here"
  redis.password: "your_redis_password_here"
  rabbitmq.username: "admin"
  rabbitmq.password: "your_rabbitmq_password_here"
  minio.accessKey: "admin"
  minio.secretKey: "your_minio_password_here"
```

#### Deployment Using ConfigMap + Secret

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: localhost:5001/backend:v1.0
        ports:
        - containerPort: 8080
        env:
        # PostgreSQL
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: service-endpoints
              key: postgres.host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: service-endpoints
              key: postgres.port
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: service-credentials
              key: postgres.username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: service-credentials
              key: postgres.password
        
        # Redis
        - name: REDIS_HOST
          valueFrom:
            configMapKeyRef:
              name: service-endpoints
              key: redis.host
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: service-credentials
              key: redis.password
        
        # RabbitMQ
        - name: RABBITMQ_HOST
          valueFrom:
            configMapKeyRef:
              name: service-endpoints
              key: rabbitmq.host
        - name: RABBITMQ_USER
          valueFrom:
            secretKeyRef:
              name: service-credentials
              key: rabbitmq.username
        - name: RABBITMQ_PASSWORD
          valueFrom:
            secretKeyRef:
              name: service-credentials
              key: rabbitmq.password
```

### Example 3: Using Local Registry

Always use the local registry for images to avoid external dependencies:

```bash
# 1. Build image
docker build -t my-app:v1.0 .

# 2. Tag for local registry
docker tag my-app:v1.0 localhost:5001/my-app:v1.0

# 3. Push to local registry
docker push localhost:5001/my-app:v1.0

# 4. Use in K8s manifest
# image: localhost:5001/my-app:v1.0
```

**Important:** K3s can pull from `localhost:5001` because the registry is on the same Docker network.

## Best Practices

### 1. Use Secrets for Sensitive Data

✅ **DO:**
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: password
```

❌ **DON'T:**
```yaml
env:
- name: DB_PASSWORD
  value: "hardcoded_password"  # ❌ Never hardcode!
```

### 2. Use ConfigMaps for Endpoints

Separate configuration from code:

```yaml
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: endpoints
      key: postgres.host
```

### 3. Prefer Docker Service Names Over IPs

✅ Flexible (works even if IP changes):
```yaml
env:
- name: DB_HOST
  value: "postgres"
```

❌ Brittle (breaks if IP changes):
```yaml
env:
- name: DB_HOST
  value: "172.28.0.50"
```

### 4. Use ExternalName Services for Abstraction

Provides a K8s-native abstraction layer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  type: ExternalName
  externalName: postgres
```

Now apps can use `database:5432` instead of `postgres:5432`.

### 5. Test Connectivity from K3s Container

```bash
# Enter K3s container
docker exec -it k3s-server sh

# Test connectivity
ping postgres
nc -zv postgres 5432
nc -zv mongodb 27017
nc -zv redis 6379
```

## Connection Strings Reference

### PostgreSQL

```bash
# Environment variables
DB_HOST=postgres
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=your_secure_password_here
DB_NAME=defaultdb

# Connection string
postgresql://admin:your_secure_password_here@postgres:5432/defaultdb
```

### MongoDB

```bash
# Connection string
mongodb://admin:your_mongo_password_here@mongodb:27017/defaultdb?authSource=admin
```

### Redis

```bash
# Connection string
redis://:your_redis_password_here@redis:6379
```

### RabbitMQ

```bash
# AMQP connection string
amqp://admin:your_rabbitmq_password_here@rabbitmq:5672/
```

### MinIO (S3)

```bash
# Endpoint
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=your_minio_password_here

# AWS SDK config
AWS_ENDPOINT_URL=http://minio:9000
AWS_ACCESS_KEY_ID=admin
AWS_SECRET_ACCESS_KEY=your_minio_password_here
```

### Docker Registry

```bash
# Registry URL (for K8s to pull images)
REGISTRY=localhost:5001

# Or use registry service name
REGISTRY=registry:5000  # Internal Docker network port
```

## Troubleshooting

### Problem: Pod can't connect to database

**Check 1: Verify network connectivity**
```bash
kubectl exec -it <pod-name> -- ping postgres
kubectl exec -it <pod-name> -- nc -zv postgres 5432
```

**Check 2: Verify service is running**
```bash
docker ps | grep postgres
docker logs postgres
```

**Check 3: Verify credentials**
```bash
kubectl get secret postgres-credentials -o yaml
# Check base64 encoded values
```

### Problem: Connection timeout

**Check 1: Port is correct**
```bash
docker ps | grep postgres
# Look for port mappings: 5432->5432
```

**Check 2: Firewall/Network policies**
```bash
# Check Docker network
docker network inspect k3s_k3s-network

# Verify container IPs
docker inspect postgres | grep IPAddress
```

### Problem: DNS resolution fails

**Check 1: K3s DNS**
```bash
kubectl get pods -n kube-system | grep coredns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Check 2: Use IP instead temporarily**
```yaml
env:
- name: DB_HOST
  value: "172.28.0.50"  # Bypass DNS
```

### Problem: Image pull fails from local registry

**Check 1: Registry is accessible**
```bash
docker exec -it k3s-server sh
curl http://registry:5000/v2/_catalog
# or
curl http://localhost:5001/v2/_catalog  # from host
```

**Check 2: Image exists**
```bash
curl http://localhost:5001/v2/<image-name>/tags/list
```

**Check 3: K3s can resolve registry**
```bash
docker exec -it k3s-server ping registry
```

## Advanced: Using Kubernetes Endpoints

For fine-grained control, create a Service with manual Endpoints:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: postgres
subsets:
- addresses:
  - ip: 172.28.0.50  # PostgreSQL container IP
  ports:
  - port: 5432
```

Now pods can use `postgres:5432` as if it were a K8s service.

## Summary

| Connection Method | Pros | Cons | Recommendation |
|-------------------|------|------|----------------|
| Docker service name (`postgres`) | Simple, flexible | Couples to Docker | ✅ Recommended for most cases |
| Fixed IP (`172.28.0.50`) | Explicit | Brittle if IP changes | ⚠️ Use sparingly |
| ExternalName Service | K8s-native, abstracted | More YAML | ✅ Best for production-like setups |
| Manual Endpoints | Full control | Most complex | ⚠️ Only if needed |

**Default recommendation:** Use Docker service names with Kubernetes Secrets/ConfigMaps.

---

**Related Documentation:**
- [README](../README.md) - Main documentation
- [QUICK_REFERENCE](QUICK_REFERENCE.md) - Command reference
- [VERSION](VERSION.md) - Version details

