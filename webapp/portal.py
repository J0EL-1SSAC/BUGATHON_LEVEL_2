#!/usr/bin/env python3
"""LPHU Level 2 internal records portal.

The intentional SQL-injection flaw is confined to this CTF service. The service uses
a protected Unix socket so a Level 1 www-data shell cannot browse it directly.
"""
import base64
import grp
import html
from http import cookies
import os
import secrets
import socket
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import psycopg2

DB = {
    "host": os.environ.get("LPHU_DB_HOST", "127.0.0.1"),
    "port": os.environ.get("LPHU_DB_PORT", "5432"),
    "dbname": os.environ.get("LPHU_DB_NAME", "lphu_records"),
    "user": os.environ.get("LPHU_DB_USER", "lphu_webapp"),
    "password": os.environ.get("LPHU_DB_PASS", ""),
}
AUDIT_USER = os.environ.get("LPHU_AUDIT_USER", "auditor")
AUDIT_PASS = os.environ.get("LPHU_AUDIT_PASS", "")
FLAG_03 = os.environ.get("LPHU_FLAG_03", "")
FLAG_07 = os.environ.get("LPHU_FLAG_07", "")
FLAG_09 = os.environ.get("LPHU_FLAG_09", "")
FLAG_10 = os.environ.get("LPHU_FLAG_10", "")
INVESTIGATION_COOKIE = "lphu_orientation"
INVESTIGATION_TTL = 60 * 60 * 2
investigations = {}


def db():
    return psycopg2.connect(**DB)


def page(body):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>LPHU Internal Records Portal</title><style>
*{{box-sizing:border-box;font-family:Segoe UI,Tahoma,sans-serif}} body{{margin:0;background:#0f172a;color:#e2e8f0;min-height:100vh;display:flex;justify-content:center;padding:60px 20px}}
.wrap{{width:560px}} .header{{font-size:22px;font-weight:700;letter-spacing:1px}} .sub{{font-size:13px;color:#94a3b8;margin:6px 0 28px}} .panel{{background:#1e293b;border:1px solid #334155;border-radius:8px;padding:28px;box-shadow:0 8px 24px #0006}}
label{{display:block;font-size:13px;color:#cbd5e1;margin-bottom:7px}} input{{width:100%;padding:10px;background:#0f172a;border:1px solid #475569;border-radius:4px;color:#fff;margin-bottom:14px}} button{{padding:10px 18px;background:#0284c7;border:0;border-radius:4px;color:#fff;font-weight:700}} .result,.block{{margin-top:22px;padding:16px;background:#0f172a;border:1px solid #334155;border-radius:6px;white-space:pre-wrap;overflow-wrap:anywhere}} .label{{font-size:11px;letter-spacing:1px;color:#38bdf8;text-transform:uppercase;font-weight:700;margin-bottom:8px}} .flag{{font:16px 'Courier New',monospace;color:#4ade80}} .footer{{margin-top:25px;color:#64748b;font-size:11px}}
</style></head><body><main class="wrap">{body}</main></body></html>'''


def chrome(content):
    return '<div class="header">LPHU Internal Records Portal</div><div class="sub">Student &amp; Staff Record Lookup — Registrar’s Office</div>' + content + '<div class="footer">Madrigal Electromotive Academic Systems — Internal Use Only</div>'


class UnixHTTPServer(ThreadingHTTPServer):
    address_family = socket.AF_UNIX


class Handler(BaseHTTPRequestHandler):
    server_version = "LPHU-Records/2.0"
    sys_version = ""

    def send_html(self, status, body, headers=None):
        payload = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(payload)

    def investigation_session(self):
        """Return opaque, server-side progress for the orientation exercise."""
        now = time.monotonic()
        for token, state in list(investigations.items()):
            if now - state["created"] > INVESTIGATION_TTL:
                del investigations[token]

        jar = cookies.SimpleCookie()
        try:
            jar.load(self.headers.get("Cookie", ""))
        except cookies.CookieError:
            pass
        token = jar[INVESTIGATION_COOKIE].value if INVESTIGATION_COOKIE in jar else ""
        if token in investigations:
            return investigations[token], None

        token = secrets.token_urlsafe(24)
        investigations[token] = {
            "created": now,
            "valid_lookup": False,
            "missing_lookup": False,
            "unusual_input": False,
        }
        return investigations[token], (
            f"{INVESTIGATION_COOKIE}={token}; Path=/; HttpOnly; SameSite=Lax; Max-Age={INVESTIGATION_TTL}"
        )

    @staticmethod
    def investigation_complete(state):
        return state["valid_lookup"] and state["missing_lookup"] and state["unusual_input"]

    def audit_authorized(self):
        value = self.headers.get("Authorization", "")
        if not value.startswith("Basic "):
            return False
        try:
            username, password = base64.b64decode(value[6:], validate=True).decode().split(":", 1)
            return username == AUDIT_USER and password == AUDIT_PASS
        except (ValueError, UnicodeDecodeError):
            return False

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        path = parsed.path.rstrip("/") or "/"
        params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        investigation, cookie = self.investigation_session()
        session_headers = {"Set-Cookie": cookie} if cookie else {}

        if path == "/orientation":
            review_requested = params.get("review", [""])[0] == "REG-4488"
            if review_requested and self.investigation_complete(investigation):
                review = '<div class="block"><div class="label">REG-4488 observation review</div><p>The comparison has been recorded for the migration team.</p><div class="flag">' + html.escape(FLAG_03) + '</div></div>'
            elif review_requested:
                review = '<div class="block"><div class="label">REG-4488 observation review</div><p>No consistent comparison has been recorded for this staff session. Review the migration notice and return after testing the listed cases.</p></div>'
            else:
                review = ''
            content = '''<div class="panel"><div class="label">Registrar system migration notice</div>
<p>The student-record system was migrated several years ago. Some records were imported from legacy systems and may not follow the current format.</p>
<div class="block"><div class="label">Known record ranges</div>Current student records: 1000–1999<br>Staff records: 2000–2999<br>Archived records: 9000+</div>
<div class="block"><div class="label">Migration details</div>Incident reference: REG-4488<br>Migration batch: REG-4488<br>System: Registrar Records v2<br>Legacy backend: PostgreSQL<br>Status: Migration complete<br>Known issue: Input validation review pending</div>
<div class="block"><div class="label">Audit note</div>A previous audit noted that the lookup system accepts a numeric record identifier.<br><br>Before contacting IT, verify whether the lookup behaves consistently for a valid identifier, an invalid identifier, and unusual input.<br><br><em>“The database does not always behave like the interface suggests.”</em></div>
<form method="get" action="/orientation"><input type="hidden" name="review" value="REG-4488"><button type="submit">Submit REG-4488 observation review</button></form>''' + review + '</div>'
            self.send_html(200, page(chrome(content)), session_headers)
            return

        if path == "/audit":
            if not self.audit_authorized():
                content = '<div class="panel"><h2>Authentication required</h2><p class="sub">Audit review is restricted to the assigned reviewer.</p><div class="block"><div class="label">Protected-resource checkpoint</div><div class="flag">' + html.escape(FLAG_07) + '</div></div></div>'
                session_headers["WWW-Authenticate"] = 'Basic realm="Superlab Audit Review"'
                self.send_html(401, page(chrome(content)), session_headers)
                return
            content = '<div class="panel"><h2>Superlab Reagent Audit — Access Granted</h2><p class="sub">Internal review record, Lot #74-B — auditor session</p><div class="block"><div class="label">Authenticated checkpoint</div><div class="flag">' + html.escape(FLAG_09) + '</div></div><div class="block"><div class="label">Final Level 2 flag</div><div class="flag">' + html.escape(FLAG_10) + '</div></div><div class="block"><div class="label">Level 3 handoff</div>Contact: G. Fring — Los Pollos Hermanos Logistics<br>Reference: LOT-74B-SUPERLAB<br>Continue to Level 3 with this reference.</div></div>'
            self.send_html(200, page(chrome(content)), session_headers)
            return

        if path != "/":
            self.send_html(404, page(chrome('<div class="panel"><h2>404 Not Found</h2></div>')), session_headers)
            return

        record_id = params.get("id", [""])[0]
        if record_id == "":
            result = "Enter a Record ID above to look up a student."
        else:
            # Intentional CTF vulnerability: input is concatenated into SQL.
            query = "SELECT id, name, department, status FROM students WHERE id = " + record_id
            try:
                with db() as conn, conn.cursor() as cur:
                    cur.execute(query)
                    rows = cur.fetchall()
                if record_id.isdecimal() and 1000 <= int(record_id) <= 1999:
                    if rows:
                        investigation["valid_lookup"] = True
                    else:
                        investigation["missing_lookup"] = True
                result = "No record found for ID: " + record_id if not rows else "\n".join(
                    "Record\nID: %s\nName: %s\nDepartment: %s\nStatus: %s\n---" % tuple(str(value) for value in row)
                    for row in rows)
            except Exception as exc:
                investigation["unusual_input"] = True
                result = "Database Error: " + str(exc)

        form = '<div class="panel"><form method="get"><label for="id">Record ID</label><input id="id" name="id" value="' + html.escape(record_id) + '" placeholder="e.g. 1023"><button type="submit">Lookup Record</button></form><div class="result">' + html.escape(result) + '</div></div>'
        self.send_html(200, page(chrome(form)), session_headers)

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


if __name__ == "__main__":
    socket_path = "/run/l2portal/l2portal.sock"
    os.makedirs(os.path.dirname(socket_path), exist_ok=True)
    try:
        os.unlink(socket_path)
    except FileNotFoundError:
        pass
    server = UnixHTTPServer(socket_path, Handler)
    os.chown(socket_path, os.getuid(), grp.getgrnam("l2portal-socket").gr_gid)
    os.chmod(socket_path, 0o660)
    server.serve_forever()
