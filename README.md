# BUGATHON 2026 — LPHU Level 2

`The Developer’s Mistake` is an isolated add-on for the existing Level 0/1 VM.
It intentionally contains a controlled SQL-injection path for use only in the CTF.

## Deploy on Ubuntu Server

```bash
chmod +x deploy.sh reset_level2.sh verify_level2.sh
sudo ./deploy.sh
sudo ./verify_level2.sh
```

The deployment never overwrites or removes `/var/www/html`, so existing Level 0/1
content is left intact. It also removes only the obsolete Level 2 Apache 8080 site
from earlier package versions; Apache port 80 is preserved. See `LEVEL2_PLAYER.md` for the participant brief and keep
`LEVEL2_ORGANIZER.md` private.
