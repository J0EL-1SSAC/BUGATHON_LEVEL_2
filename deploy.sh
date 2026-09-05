#!/bin/bash
set -euo pipefail

# Deploys only the isolated Level 2 components. It never writes to /var/www/html.
DB_NAME="lphu_records"
APP_USER="l2portal"
APP_ROOT="/var/www/records-portal"
SECRETS_DIR="/etc/lphu-level2"

[ "${EUID}" -eq 0 ] || { echo "Run as root: sudo ./deploy.sh"; exit 1; }

# A pre-release Level 2 build published the records portal through Apache on
# 127.0.0.1:8080. This build must never use Apache, but an in-place upgrade must
# remove that *specific* obsolete Level 2 configuration. Apache itself and its
# port-80 Level 0/1 configuration are deliberately left alone.
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

apt-get update
apt-get install -y postgresql postgresql-contrib python3 python3-psycopg2 openssh-server curl
systemctl enable --now postgresql ssh

id heisenberg >/dev/null 2>&1 || useradd -m -s /bin/bash heisenberg
echo 'heisenberg:Sup3rL@bSynth3sis!99' | chpasswd
id "${APP_USER}" >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin "${APP_USER}"
getent group l2portal-socket >/dev/null 2>&1 || groupadd --system l2portal-socket
usermod -a -G l2portal-socket heisenberg

install -d -m 0750 -o "${APP_USER}" -g l2portal-socket /run/l2portal
install -d -m 0750 -o root -g "${APP_USER}" "${APP_ROOT}"
install -d -m 0700 -o root -g root "${SECRETS_DIR}"
install -d -m 0700 -o heisenberg -g heisenberg /home/heisenberg/.lphu
install -m 0600 -o heisenberg -g heisenberg pivot/ssh_welcome.txt /home/heisenberg/.lphu/ssh-welcome.txt
install -m 0600 -o heisenberg -g heisenberg pivot/ops_note.txt /home/heisenberg/.lphu/registrar-connectivity.txt
install -m 0644 -o root -g root pivot/backup_records.sh /var/www/backup_records.sh
install -m 0640 -o root -g "${APP_USER}" webapp/portal.py "${APP_ROOT}/portal.py"
install -m 0644 -o root -g root webapp/level2-records.service /etc/systemd/system/level2-records.service
install -m 0600 -o root -g root secrets/portal.env "${SECRETS_DIR}/portal.env"
install -m 0600 -o root -g root secrets/audit-gate.env "${SECRETS_DIR}/audit-gate.env"
install -m 0600 -o root -g root secrets/audit-session.env "${SECRETS_DIR}/audit-session.env"

cat > /etc/tmpfiles.d/l2portal.conf <<'EOF'
d /run/l2portal 0750 l2portal l2portal-socket -
EOF
cat > /etc/default/level2-records <<'EOF'
LPHU_DB_HOST=127.0.0.1
LPHU_DB_PORT=5432
LPHU_DB_NAME=lphu_records
LPHU_DB_USER=lphu_webapp
LPHU_DB_PASS=W3bApp_R34d0nly_2026
LPHU_AUDIT_USER=auditor
LPHU_AUDIT_PASS=Aud1t_R3v13w_2026!
EOF
chown root:root /etc/default/level2-records
chmod 0600 /etc/default/level2-records

# Rebuild just this dedicated database. Existing Level 0/1 web content is untouched.
systemctl stop level2-records.service 2>/dev/null || true
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS ${DB_NAME};"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${DB_NAME};"
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f db/schema.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f db/seed.sql

if grep -qE '^#?PasswordAuthentication ' /etc/ssh/sshd_config; then
  sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
  echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
fi
sshd -t
systemctl restart ssh
tmpfiles --create /etc/tmpfiles.d/l2portal.conf
systemctl daemon-reload
systemctl enable --now level2-records.service

systemctl is-active --quiet level2-records.service || { systemctl status level2-records.service --no-pager; exit 1; }
sudo -u www-data test ! -r "${APP_ROOT}/portal.py" || { echo "ERROR: www-data can read portal source"; exit 1; }
sudo -u heisenberg test ! -r "${APP_ROOT}/portal.py" || { echo "ERROR: heisenberg can read portal source"; exit 1; }

echo "Level 2 deployment complete. Run: sudo ./verify_level2.sh"
