# BUGATHON 2026 — Level 2: The Developer’s Mistake (ORGANIZER)

Keep this file private. Deploy on the same Ubuntu VM as Levels 0/1:

```bash
sudo ./deploy.sh
sudo ./verify_level2.sh
```

Reset only Level 2 with `sudo ./reset_level2.sh`. Neither script writes to
`/var/www/html`.

## Architecture

The protected `l2portal` Python service talks to PostgreSQL as non-superuser
`lphu_webapp`. It listens on `/run/l2portal/l2portal.sock`, owned by `l2portal` and
group `l2portal-socket`; `heisenberg` is the only player account in that group.
Unix-socket forwarding over SSH exposes the portal to the player’s local browser while
preventing the original `www-data` shell from reaching it. There is no Level 2 TCP
listener. SSH remains on port 22; the existing Level 0/1 HTTP service remains untouched.

For upgrades from the deprecated Apache-backed Level 2 build, both deployment and reset
disable and remove only `records-portal.conf` plus its exact `Listen 127.0.0.1:8080`
entry, then validate and reload Apache. They do not alter Apache’s port 80 listener.

Runtime source is `root:l2portal` with `0750` directory / `0640` source permissions.
The source has no embedded flags or audit credentials; protected runtime values are
provided by root-readable environment files. The database role has SELECT only on the
challenge tables, with no superuser, role, database-creation, or write privileges.

## Credentials

| Purpose | Value |
|---|---|
| Pivot account | `heisenberg` / `Sup3rL@bSynth3sis!99` |
| Database application account | `lphu_webapp` / `W3bApp_R34d0nly_2026` |
| Audit account | `auditor` / `Aud1t_R3v13w_2026!` |

## Full solution and checkpoints

1. From the Level 1 `www-data` shell, read `/var/www/backup_records.sh` to recover the
   pivot credential. SSH as `heisenberg`.
2. Read `~/.lphu/ssh-welcome.txt`: `FLAG2_01{ssh_p1v0t_7c2d9a4f}`.
3. Enumerate the new account’s files. `~/.lphu/registrar-connectivity.txt` reveals the
   service’s protected socket, approved SSH forwarding approach, orientation route, and
   `FLAG2_02{l0c4l_0ps_m4p_83be1d}`.
4. Forward `/run/l2portal/l2portal.sock` through SSH to a local TCP browser port, then
   open `/orientation`: `FLAG2_03{1nt3rn4l_r0ut3_5fd902}`.
5. A normal `id=1023` lookup works. A quote produces a PostgreSQL error. The four-column
   query accepts a UNION. Querying `incident_tickets` yields
   `FLAG2_04{qu3ry_c0ntr0l_9a71ce}`.
6. Enumerate `information_schema.tables` / columns. Query the table comment with
   `obj_description('audit_credentials'::regclass)` to obtain
   `FLAG2_05{sch3m4_tr4c3_6b4e18}`.
7. UNION-query `internal_records`; record 501 contains `/audit/` and
   `FLAG2_06{r3c0rd_501_2f8cad}`.
8. Request `/audit/` without credentials. It returns HTTP 401 and
   `FLAG2_07{4ud1t_g4t3_79d3b0}`.
9. UNION-query `audit_credentials`. Remove whitespace from `credential_blob` and Base64
   decode it. The result is the audit credential plus
   `FLAG2_08{d3c0d3d_4cc3ss_15ef92}`.
10. Authenticate to `/audit/` with HTTP Basic authentication. It reveals
    `FLAG2_09{b4s1c_4uth_68c5de}` and final
    `FLAG2_10{f1n4l_r3c0rd_b9a704}`.

## Level 3 handoff

The authenticated audit page gives: `Contact: G. Fring — Los Pollos Hermanos
Logistics`, reference `LOT-74B-SUPERLAB`. Coordinate any Level 3 credential replacement
with its owner by changing the authenticated portal handoff text before deployment.

## Troubleshooting

- Service/socket: `systemctl status level2-records.service` and
  `journalctl -u level2-records.service -n 50 --no-pager`.
- Database: `sudo -u postgres psql -d lphu_records`.
- Socket forwarding: ensure a new `heisenberg` login has the `l2portal-socket` group.
- Run `sudo ./verify_level2.sh`; it performs an actual curl connection as each user,
  rather than incorrectly inferring Unix-socket connectivity from mode bits.
