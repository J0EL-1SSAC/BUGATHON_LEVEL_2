#!/bin/bash
# ============================================================
# LPHU Records - Nightly Backup Job
# Runs via cron as part of the registrar backup rotation.
# Syncs /var/www/html to the offsite backup share.
#
# Maintainer: heisenberg (IT Ops - do not remove, breaks cron!)
# ============================================================

BACKUP_USER="heisenberg"
BACKUP_HOST="backup-internal.lphu.local"
BACKUP_DIR="/var/backups/lphu_records"

# TODO: move this to a vault before the audit - ITOPS-4471
# temporary local login for the backup service account
# (same creds as the heisenberg shell account on this box)
SVC_PASSWORD='Sup3rL@bSynth3sis!99'

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/records_$(date +%F).tar.gz" /var/www/html 2>/dev/null

# rsync -az --password-file=<(echo "$SVC_PASSWORD") /var/www/html/ "$BACKUP_USER@$BACKUP_HOST::records/"

echo "[backup_records] completed $(date)"
