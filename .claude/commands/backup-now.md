# Manual Backup

Trigger a manual backup of usage data.

Steps:
1. Read the API_TOKEN from .env file
2. Execute backup command:
```bash
docker exec cli-proxy-backup sh -c 'curl -s -o /tmp/manual-backup.json \
  -H "Authorization: Bearer $API_TOKEN" \
  "$API_URL/v0/management/usage/export" && \
  TIMESTAMP=$(date +%Y%m%d_%H%M%S) && \
  cp /tmp/manual-backup.json /backups/usage-$TIMESTAMP.json && \
  cp /tmp/manual-backup.json /backups/usage-latest.json && \
  echo "Backup saved: usage-$TIMESTAMP.json"'
```

3. Verify the backup was created in `backups/` directory.
