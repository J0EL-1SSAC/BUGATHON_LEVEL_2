#!/bin/bash
set -euo pipefail

# Reset only Level 2 state; /var/www/html (Levels 0/1) is never touched.
[ "${EUID}" -eq 0 ] || { echo "Run as root: sudo ./reset_level2.sh"; exit 1; }

DB_NAME="lphu_records"
APP_ROOT="/var/www/records-portal"
SECRETS_DIR="/etc/lphu-level2"

# Keep reset idempotent across upgrades from the obsolete Apache-backed Level 2
# build. This affects only that named site and its exact loopback Listen line;
# Apache port 80 and all Level 0/1 configuration remain untouched.
if command -v a2dissite >/dev/null 2>&1; then
  a2dissite records-portal.conf >/dev/null 2>&1 || true
fi
rm -f /etc/apache2/sites-enabled/records-portal.conf
rm -f /etc/apache2/sites-available/records-portal.conf
if [ -f /etc/apache2/ports.conf ]; then
  sed -i '/^[[:space:]]*Listen[[:space:]]\+127\.0\.0\.1:8080[[:space:]]*$/d' /etc/apache2/ports.conf
fi
if systemctl is-active --quiet apache2; then
  apache2ctl configtest
  systemctl reload apache2
fi

systemctl stop level2-records.service 2>/dev/null || true
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS ${DB_NAME};"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${DB_NAME};"
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f db/schema.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f db/seed.sql

install -m 0640 -o root -g l2portal webapp/portal.py "${APP_ROOT}/portal.py"
install -m 0600 -o root -g root secrets/portal.env "${SECRETS_DIR}/portal.env"
install -m 0600 -o root -g root secrets/audit-gate.env "${SECRETS_DIR}/audit-gate.env"
install -m 0600 -o root -g root secrets/audit-session.env "${SECRETS_DIR}/audit-session.env"
install -m 0600 -o heisenberg -g heisenberg pivot/ssh_welcome.txt /home/heisenberg/.lphu/ssh-welcome.txt
install -m 0600 -o heisenberg -g heisenberg pivot/ops_note.txt /home/heisenberg/.lphu/registrar-connectivity.txt
install -m 0644 -o root -g root pivot/backup_records.sh /var/www/backup_records.sh
echo 'heisenberg:Sup3rL@bSynth3sis!99' | chpasswd

tmpfiles --create /etc/tmpfiles.d/l2portal.conf
systemctl restart level2-records.service
sudo ./verify_level2.sh
echo "Level 2 reset complete; Levels 0/1 were not modified."
