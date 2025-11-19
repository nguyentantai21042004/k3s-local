COMPOSE ?= docker compose
COMPOSE_FILE ?= docker-compose.yaml
DC := $(COMPOSE) -f $(COMPOSE_FILE)

CLUSTER_SERVICES := k3s-server portainer
REGISTRY_SERVICES := registry registry-ui
DATABASE_SERVICES := postgres mongodb
ALL_SERVICES := $(CLUSTER_SERVICES) $(REGISTRY_SERVICES) $(DATABASE_SERVICES)

.PHONY: help \
	up up-all down stop restart \
	up-cluster down-cluster restart-cluster logs-cluster \
	up-registry down-registry restart-registry logs-registry \
	up-db down-db restart-db logs-db \
	status ps pull verify updates backup clean nuke

help:
	@echo "K3s Emergency Backup Environment"
	@echo "Usage:"
	@echo "  make up             # Start entire stack (cluster + registry)"
	@echo "  make down           # Stop and remove containers"
	@echo "  make up-cluster     # Start K3s + Portainer pair"
	@echo "  make up-registry     # Start Registry + Registry UI pair"
	@echo "  make up-db           # Start PostgreSQL + MongoDB"
	@echo "  make logs-cluster   # Tail logs for K3s + Portainer"
	@echo "  make logs-registry  # Tail logs for Registry pair"
	@echo "  make logs-db         # Tail logs for PostgreSQL + MongoDB"
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

