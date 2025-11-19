#!/bin/bash

##############################################################################
# Backup Docker Volumes
# Backup all K3s environment volumes to local files
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

# Backup directory
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SUBDIR="$BACKUP_DIR/$TIMESTAMP"

# Volumes to backup
VOLUMES=(
    "k3s_k3s-server-data"
    "k3s_portainer-data"
    "k3s_registry-data"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  K3s Volume Backup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_SUBDIR"
echo -e "${YELLOW}Backup directory: ${CYAN}$BACKUP_SUBDIR${NC}"
echo ""

# Function to backup volume
backup_volume() {
    local volume=$1
    local backup_file="$BACKUP_SUBDIR/${volume//\//_}.tar.gz"
    
    echo -e "Backing up ${CYAN}$volume${NC}..."
    
    # Check if volume exists
    if ! docker volume inspect "$volume" &> /dev/null; then
        echo -e "  ${YELLOW}Volume not found, skipping${NC}"
        echo ""
        return 0
    fi
    
    # Backup volume
    if docker run --rm \
        -v "$volume:/data:ro" \
        -v "$BACKUP_SUBDIR:/backup" \
        alpine \
        tar czf "/backup/$(basename $backup_file)" -C /data . 2>/dev/null; then
        
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "  ${GREEN}Success${NC} - Size: $size"
        echo -e "  $backup_file"
    else
        echo -e "  ${RED}Failed${NC}"
        return 1
    fi
    echo ""
}

# Backup all volumes
FAILED=0
for volume in "${VOLUMES[@]}"; do
    backup_volume "$volume" || ((FAILED++))
done

echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"

# Create metadata file
METADATA_FILE="$BACKUP_SUBDIR/backup-info.txt"
cat > "$METADATA_FILE" << EOF
K3s Environment Backup
======================

Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Host: $(hostname)
Docker Version: $(docker --version)

Volumes Backed Up:
EOF

for volume in "${VOLUMES[@]}"; do
    if [ -f "$BACKUP_SUBDIR/${volume//\//_}.tar.gz" ]; then
        size=$(du -h "$BACKUP_SUBDIR/${volume//\//_}.tar.gz" | cut -f1)
        echo "  - $volume ($size)" >> "$METADATA_FILE"
    fi
done

echo "" >> "$METADATA_FILE"
echo "Docker Compose Version:" >> "$METADATA_FILE"
grep "image:" "$PROJECT_ROOT/docker-compose.yaml" >> "$METADATA_FILE"

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    total_size=$(du -sh "$BACKUP_SUBDIR" | cut -f1)
    echo -e "${GREEN}Backup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Backup Summary:${NC}"
    echo "  Location: $BACKUP_SUBDIR"
    echo "  Total Size: $total_size"
    echo "  Files:"
    ls -lh "$BACKUP_SUBDIR" | tail -n +2 | awk '{print "    " $9 " (" $5 ")"}'
    echo ""
    echo -e "${YELLOW}To restore:${NC}"
    echo "  cd $BACKUP_SUBDIR"
    echo "  docker run --rm -v VOLUME_NAME:/data -v \$(pwd):/backup alpine sh -c 'cd /data && tar xzf /backup/FILE.tar.gz'"
else
    echo -e "${RED}Backup failed for $FAILED volume(s)${NC}"
    exit 1
fi

# Cleanup old backups (keep last 5)
echo ""
echo -e "${YELLOW}Cleaning up old backups...${NC}"
if [ -d "$BACKUP_DIR" ]; then
    cd "$BACKUP_DIR"
    ls -t | tail -n +6 | xargs -I {} rm -rf {} 2>/dev/null || true
    cd - > /dev/null
fi
echo -e "${GREEN}Keeping 5 most recent backups${NC}"

