#!/bin/bash
set -euo pipefail

# Backup destination
DEST="/var/backups/automation/$(date +%F)"
mkdir -p "$DEST"

SERVERS=("192.168.56.121" "192.168.56.122" "192.168.56.123" "192.168.56.124")

for SERVER in "${SERVERS[@]}"; do
  ssh devops@$SERVER "tar czf - /home/devops /etc" > "$DEST/$SERVER-backup.tar.gz"
done

find /var/backups/automation -type f -mtime +30 -delete
