COMPOSE ?= docker compose
COMPOSE_FILE ?= docker-compose.yaml
DC := $(COMPOSE) -f $(COMPOSE_FILE)

CLUSTER_SERVICES := k3s-server portainer
REGISTRY_SERVICES := registry registry-ui
DATABASE_SERVICES := postgres mongodb
MESSAGE_SERVICES := rabbitmq
CACHE_SERVICES := redis
STORAGE_SERVICES := minio
ALL_SERVICES := $(CLUSTER_SERVICES) $(REGISTRY_SERVICES) $(DATABASE_SERVICES) $(MESSAGE_SERVICES) $(CACHE_SERVICES) $(STORAGE_SERVICES)

.PHONY: help \
	up up-all down stop restart \
	up-cluster down-cluster restart-cluster logs-cluster \
	up-registry down-registry restart-registry logs-registry \
	up-db down-db restart-db logs-db \
	up-mq down-mq restart-mq logs-mq \
	up-cache down-cache restart-cache logs-cache \
	up-storage down-storage restart-storage logs-storage \
	status ps pull verify updates backup clean nuke

help:
	@echo "K3s Emergency Backup Environment"
	@echo "Usage:"
	@echo "  make up             # Start entire stack (cluster + registry)"
	@echo "  make down           # Stop and remove containers"
	@echo "  make up-cluster     # Start K3s + Portainer pair"
	@echo "  make up-registry     # Start Registry + Registry UI pair"
	@echo "  make up-db           # Start PostgreSQL + MongoDB"
	@echo "  make up-mq           # Start RabbitMQ"
	@echo "  make up-cache        # Start Redis"
	@echo "  make up-storage      # Start MinIO"
	@echo "  make logs-cluster   # Tail logs for K3s + Portainer"
	@echo "  make logs-registry  # Tail logs for Registry pair"
	@echo "  make logs-db         # Tail logs for PostgreSQL + MongoDB"
	@echo "  make logs-mq         # Tail logs for RabbitMQ"
	@echo "  make logs-cache      # Tail logs for Redis"
	@echo "  make logs-storage    # Tail logs for MinIO"
	@echo "  make verify         # Run scripts/verify-versions.sh"
	@echo "  make updates        # Run scripts/check-updates.sh"
	@echo "  make backup         # Run scripts/backup-volumes.sh"
	@echo "  make nuke           # Down stack and remove volumes"

up: up-all

up-all:
	$(DC) up -d $(ALL_SERVICES)

down:
	$(DC) down

stop:
	$(DC) stop

restart:
	$(DC) restart $(ALL_SERVICES)

up-cluster:
	$(DC) up -d $(CLUSTER_SERVICES)

down-cluster:
	$(DC) stop $(CLUSTER_SERVICES) && $(DC) rm -f $(CLUSTER_SERVICES)

restart-cluster:
	$(DC) restart $(CLUSTER_SERVICES)

logs-cluster:
	$(DC) logs -f $(CLUSTER_SERVICES)

up-registry:
	$(DC) up -d $(REGISTRY_SERVICES)

down-registry:
	$(DC) stop $(REGISTRY_SERVICES) && $(DC) rm -f $(REGISTRY_SERVICES)

restart-registry:
	$(DC) restart $(REGISTRY_SERVICES)

logs-registry:
	$(DC) logs -f $(REGISTRY_SERVICES)

up-db:
	$(DC) up -d $(DATABASE_SERVICES)

down-db:
	$(DC) stop $(DATABASE_SERVICES) && $(DC) rm -f $(DATABASE_SERVICES)

restart-db:
	$(DC) restart $(DATABASE_SERVICES)

logs-db:
	$(DC) logs -f $(DATABASE_SERVICES)

up-mq:
	$(DC) up -d $(MESSAGE_SERVICES)

down-mq:
	$(DC) stop $(MESSAGE_SERVICES) && $(DC) rm -f $(MESSAGE_SERVICES)

restart-mq:
	$(DC) restart $(MESSAGE_SERVICES)

logs-mq:
	$(DC) logs -f $(MESSAGE_SERVICES)

up-cache:
	$(DC) up -d $(CACHE_SERVICES)

down-cache:
	$(DC) stop $(CACHE_SERVICES) && $(DC) rm -f $(CACHE_SERVICES)

restart-cache:
	$(DC) restart $(CACHE_SERVICES)

logs-cache:
	$(DC) logs -f $(CACHE_SERVICES)

up-storage:
	$(DC) up -d $(STORAGE_SERVICES)

down-storage:
	$(DC) stop $(STORAGE_SERVICES) && $(DC) rm -f $(STORAGE_SERVICES)

restart-storage:
	$(DC) restart $(STORAGE_SERVICES)

logs-storage:
	$(DC) logs -f $(STORAGE_SERVICES)

status ps:
	$(DC) ps

pull:
	$(DC) pull

verify:
	./scripts/verify-versions.sh

updates:
	./scripts/check-updates.sh

backup:
	./scripts/backup-volumes.sh

clean:
	$(DC) rm -f

nuke:
	$(DC) down -v

