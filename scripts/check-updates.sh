#!/bin/bash

##############################################################################
# Check for Available Updates
# Kiểm tra xem có phiên bản mới của các images không
##############################################################################

set -e

# Ensure consistent working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Images to check
IMAGES=(
    "rancher/k3s:v1.31.3-k3s1"
    "portainer/portainer-ce:2.21.4"
    "registry:2.8.3"
    "joxit/docker-registry-ui:2.5.7"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  K3s Environment Update Checker${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Checking for image updates...${NC}"
echo -e "${CYAN}(This may take a moment)${NC}"
echo ""

# Function to check if image exists and get digest
check_image() {
    local image=$1
    local name=$(echo "$image" | cut -d':' -f1)
    local tag=$(echo "$image" | cut -d':' -f2)
    
    echo -e "${BLUE}-----------------------------------------------------${NC}"
    echo -e "[Image] ${CYAN}$name:$tag${NC}"
    echo ""
    
    # Pull image silently to get latest info
    if docker pull "$image" &> /dev/null; then
        # Get local image info
        local local_digest=$(docker images --digests "$image" --format "{{.Digest}}" | head -1)
        local local_size=$(docker images "$image" --format "{{.Size}}" | head -1)
        local local_created=$(docker inspect "$image" --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1)
        
        echo "  Status: ${GREEN}Available${NC}"
        echo "  Size: $local_size"
        echo "  Created: $local_created"
        
        if [ ! -z "$local_digest" ] && [ "$local_digest" != "<none>" ]; then
            echo "  Digest: ${local_digest:0:19}..."
        fi
        
        echo ""
        return 0
    else
        echo "  Status: ${RED}Failed to pull${NC}"
        echo ""
        return 1
    fi
}

# Check each image
FAILED=0
for image in "${IMAGES[@]}"; do
    check_image "$image" || ((FAILED++))
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Summary
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All images pulled successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Image Summary:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | grep -E "rancher/k3s|portainer/portainer-ce|^registry|joxit/docker-registry-ui"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  - Review docs/CHANGELOG.md for breaking changes"
    echo "  - Backup current data: ./scripts/backup-volumes.sh"
    echo "  - Update environment: docker compose up -d"
else
    echo -e "${RED}Failed to pull $FAILED image(s)${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  - Check internet connection"
    echo "  - Verify image names and tags"
    echo "  - Check Docker Hub rate limits"
fi

echo ""
echo -e "${CYAN}For detailed version info, see docs/VERSION.md${NC}"

