#!/bin/bash

##############################################################################
# Version Verification Script
# Kiểm tra versions của các images trong docker-compose có match với VERSION.md
##############################################################################

set -e

# Ensure we run from repo root regardless of where script is invoked
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Expected versions (from VERSION.md)
EXPECTED_K3S="v1.31.3-k3s1"
EXPECTED_PORTAINER="2.21.4"
EXPECTED_REGISTRY="2.8.3"
EXPECTED_REGISTRY_UI="2.5.7"
EXPECTED_POSTGRES="18"  # Major version (18.x)
EXPECTED_MONGODB="8.0"  # Exact version

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  K3s Environment Version Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Function to extract image from docker-compose.yaml
get_image() {
    local service=$1
    local image
    image=$(grep -A 5 "  $service:" "$COMPOSE_FILE" | grep "image:" | awk '{print $2}')
    echo "$image"
}

# Function to verify version
verify_version() {
    local service=$1
    local expected=$2
    local actual=$(get_image "$service")
    
    echo -n "  [CHECK] $service: "
    if [ "$actual" == "$expected" ]; then
        echo -e "${GREEN}OK (${actual})${NC}"
        return 0
    else
        echo -e "${RED}MISMATCH (Expected: $expected, Got: $actual)${NC}"
        return 1
    fi
}

# Function to verify PostgreSQL major version (flexible for 18.x)
verify_postgres_version() {
    local service=$1
    local expected_major=$2
    local actual=$(get_image "$service")
    
    echo -n "  [CHECK] $service: "
    # Check if image starts with postgres:18 (supports 18, 18.1, 18.3, etc.)
    if [[ "$actual" =~ ^postgres:${expected_major}(\.|$) ]]; then
        echo -e "${GREEN}OK (${actual})${NC}"
        return 0
    else
        echo -e "${RED}MISMATCH (Expected: postgres:${expected_major}*, Got: $actual)${NC}"
        return 1
    fi
}

# Verify all services
echo -e "${YELLOW}Checking docker-compose.yaml versions...${NC}"
echo ""

ERRORS=0

verify_version "k3s-server" "rancher/k3s:$EXPECTED_K3S" || ((ERRORS++))
verify_version "portainer" "portainer/portainer-ce:$EXPECTED_PORTAINER" || ((ERRORS++))
verify_version "registry" "registry:$EXPECTED_REGISTRY" || ((ERRORS++))
verify_version "registry-ui" "joxit/docker-registry-ui:$EXPECTED_REGISTRY_UI" || ((ERRORS++))
verify_postgres_version "postgres" "$EXPECTED_POSTGRES" || ((ERRORS++))
verify_version "mongodb" "mongo:$EXPECTED_MONGODB" || ((ERRORS++))

echo ""
echo -e "${BLUE}-----------------------------------------------------------${NC}"

# Check if services are running
if docker compose ps &> /dev/null; then
    echo -e "${YELLOW}Checking running containers...${NC}"
    echo ""
    
    docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Image}}"
    
    echo ""
    echo -e "${BLUE}-----------------------------------------------------------${NC}"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All versions verified successfully!${NC}"
    echo ""
    echo -e "${BLUE}Current Setup:${NC}"
    echo "  - K3s (Kubernetes 1.31): $EXPECTED_K3S"
    echo "  - Portainer CE: $EXPECTED_PORTAINER"
    echo "  - Docker Registry: $EXPECTED_REGISTRY"
    echo "  - Registry UI: $EXPECTED_REGISTRY_UI"
    echo "  - PostgreSQL: $EXPECTED_POSTGRES.x"
    echo "  - MongoDB: $EXPECTED_MONGODB"
    exit 0
else
    echo -e "${RED}Found $ERRORS version mismatch(es)!${NC}"
    echo ""
    echo -e "${YELLOW}To fix:${NC}"
    echo "  1. Review docs/VERSION.md for correct versions"
    echo "  2. Update docker-compose.yaml accordingly"
    echo "  3. Run: docker compose pull"
    echo "  4. Run: docker compose up -d"
    exit 1
fi

