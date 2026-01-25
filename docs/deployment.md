# Deployment Guide

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- 512MB+ RAM
- Network access to AI provider APIs

## Initial Setup

### 1. Clone Repository

```bash
git clone <repo-url> ai-cli-proxy
cd ai-cli-proxy
```

### 2. Create Configuration Files

```bash
# Copy templates
cp config.yaml.example config.yaml
cp .env.example .env
```

### 3. Configure API Keys

Edit `config.yaml`:

```yaml
api-keys:
  - "sk-your-secure-api-key"

remote-management:
  secret-key: "your-management-secret"

gemini-api-key:
  - api-key: "AIzaSy..."

claude-api-key:
  - api-key: "sk-ant-..."
```

Edit `.env`:

```env
API_TOKEN=sk-your-secure-api-key
```

### 4. Add Auth Credentials

Place authentication JSON files in `auth/` directory:

```
auth/
├── antigravity-email@gmail.com.json
└── gemini-email@gmail.com-project.json
```

### 5. Start Services

```bash
# Start all services
docker compose up -d

# Verify
docker compose ps
```

## Production Deployment

### Using TLS

1. Obtain SSL certificate (Let's Encrypt, etc.)

2. Update `config.yaml`:
   ```yaml
   tls:
     enable: true
     cert: "/path/to/fullchain.pem"
     key: "/path/to/privkey.pem"
   ```

3. Update port mapping if needed:
   ```yaml
   # docker-compose.yml
   ports:
     - "443:8317"
   ```

### Behind Reverse Proxy (nginx)

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:8317;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Resource Limits

Add to `docker-compose.yml`:

```yaml
services:
  cli-proxy-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
```

## Updating

### Manual Update

```bash
# Pull latest image
docker compose pull cli-proxy-api

# Restart with new image
docker compose up -d cli-proxy-api
```

### Automatic Updates (Watchtower)

Enable in `docker-compose.yml`:

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=3600
    command: cli-proxy-api
    profiles:
      - autoupdate
```

Start with auto-update:

```bash
docker compose --profile autoupdate up -d
```

## Backup Strategy

### Automated Backups

The `backup` service automatically:
- Exports usage data every `BACKUP_INTERVAL` minutes
- Saves compressed backups to `backups/usage-YYYYMMDD_HHMMSS.json.gz`
- Keeps `BACKUP_RETENTION_DAYS` days of history
- Maintains `usage-latest.json.gz` for quick restore

### Manual Backup

```bash
# Export current data
curl -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:8317/v0/management/usage/export \
  | gzip > backup-$(date +%Y%m%d).json.gz
```

### Off-site Backup

Add to crontab:

```bash
# Daily backup to remote storage
0 2 * * * rsync -av /path/to/ai-cli-proxy/backups/ user@backup-server:/backups/
```

## Monitoring

### Health Check

```bash
# Check service health
curl http://localhost:8317/

# Check API is responding
curl -H "Authorization: Bearer $API_TOKEN" \
  http://localhost:8317/v1/models
```

### Log Monitoring

```bash
# Follow logs
docker logs -f cli-proxy-api

# Check backup status
docker logs --tail 50 cli-proxy-backup
```

## Troubleshooting

### Container Won't Start

```bash
docker compose logs cli-proxy-api
docker inspect cli-proxy-api | grep -A 10 Health
```

### API Returns 401

- Verify API key in request matches `config.yaml` api-keys
- Check `Authorization: Bearer <key>` header format

### Backup Failing

```bash
docker logs cli-proxy-backup
# Verify API_TOKEN in .env matches api-keys in config.yaml
```

### High Memory Usage

- Check log file sizes
- Verify `logs-max-total-size-mb` setting
- Consider reducing `BACKUP_RETENTION_DAYS`
