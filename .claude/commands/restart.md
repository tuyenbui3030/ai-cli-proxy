# Restart Services

Restart Docker services after configuration changes.

Run:
```bash
docker compose restart cli-proxy-api
docker compose restart backup
```

Then verify services are healthy:
```bash
docker compose ps
```

Report the status after restart.
