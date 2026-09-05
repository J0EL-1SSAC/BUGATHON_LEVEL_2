# Level 2 Final Test Report

## Test environment

Preflight was run on the supplied project in the authoring workspace (macOS host,
Python 3.9, Bash). The workspace does not provide Ubuntu systemd, PostgreSQL, SSH, or
a running Docker daemon, so a live VM deployment cannot truthfully be recorded here.
`verify_level2.sh` is the Ubuntu acceptance test and must be run after deployment.

Completed preflight checks:

- `bash -n deploy.sh reset_level2.sh verify_level2.sh`
- Python syntax compilation of `webapp/portal.py`
- Base64 decode assertion for the audit artifact
- Player-facing documentation and deployment/reset scripts contain no checkpoint flags
- Static inspection confirms ten unique checkpoint identifiers after decoding the
  credential artifact
- Regression fixture confirms the exact obsolete `Listen 127.0.0.1:8080` line is
  removed while both IPv4 and IPv6 port-80 Apache listener lines remain

## Ubuntu acceptance matrix

Run `sudo ./deploy.sh && sudo ./verify_level2.sh` on Ubuntu Server. The verifier checks:

| Area | Expected result |
|---|---|
| Services | PostgreSQL, SSH, and `level2-records.service` active |
| Network | SSH on 22; no Level 2 TCP listener on 8080/9090 |
| Database | `lphu_records`, six intended tables, non-superuser read-only app role |
| Boundaries | `www-data` and `heisenberg` cannot read portal source; only `heisenberg` can actually connect to the portal socket |
| Normal operation | Student `1023` lookup returns Marion Q. |
| SQL path | Error surface, UNION route, ticket, schema metadata, internal record, and encoded credential are available |
| Audit | Unauthenticated request is 401; correct Basic authentication returns checkpoints 09/10 and handoff |
| Compatibility | Deployment/reset avoid `/var/www/html`, preserving Levels 0/1 |

## Checkpoint coverage

| Stage | Evidence location | Result |
|---|---|---|
| 01 | SSH pivot welcome artifact | Covered |
| 02 | Heisenberg local operations note | Covered |
| 03 | Internal `/orientation` route | Covered |
| 04 | SQLi-only incident ticket | Covered |
| 05 | PostgreSQL table metadata | Covered |
| 06 | Internal record 501 | Covered |
| 07 | Unauthenticated `/audit/` response | Covered |
| 08 | Decoded audit credential artifact | Covered |
| 09 | Authenticated audit response | Covered |
| 10 | Authenticated final audit response | Covered |

The final authenticated response also includes the `LOT-74B-SUPERLAB` Level 3 handoff.
