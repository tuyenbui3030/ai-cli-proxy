# AI CLI Proxy Service

Docker-based proxy service for multiple AI providers with a unified OpenAI-compatible API.

## Quick Start

```bash
# 1. Setup configuration
cp config.yaml.example config.yaml
cp .env.example .env

# 2. Edit config files
nano config.yaml  # Add your API keys
nano .env         # Set API_TOKEN

# 3. Start services
docker compose up -d
```

## Features

- **Unified API**: Single OpenAI-compatible endpoint for Gemini, Claude, Codex, etc.
- **Management Panel**: Web UI at `http://localhost:8317`
- **Auto Backup**: Periodic usage data backup with retention policy
- **Auto Restore**: Restore data on service startup

## Services

| Service | Description | Default Port |
|---------|-------------|--------------|
| `cli-proxy-api` | Main API proxy service | 8317 |
| `backup` | Periodic data backup | - |
| `restore` | One-time data restore on startup | - |

## Configuration

### Environment Variables (`.env`)

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8317` | API port |
| `TZ` | `Asia/Ho_Chi_Minh` | Timezone |
| `API_TOKEN` | - | Token for backup/restore (must match `api-keys` in config.yaml) |
| `BACKUP_INTERVAL` | `5` | Backup interval in minutes |
| `BACKUP_RETENTION_DAYS` | `10` | Days to keep old backups |

### Service Configuration (`config.yaml`)

```yaml
# API keys for client authentication
api-keys:
  - "your-api-key-here"

# Management panel
remote-management:
  allow-remote: true
  secret-key: "your-management-key"

# Provider API keys
gemini-api-key:
  - api-key: "AIzaSy..."

claude-api-key:
  - api-key: "sk-ant-..."
```

## Usage

### API Endpoints

```bash
# Chat completion (OpenAI compatible)
curl -X POST http://localhost:8317/v1/chat/completions \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-claude-sonnet-4-5",
    "messages": [{"role": "user", "content": "Hello"}]
  }'

# List models
curl http://localhost:8317/v1/models \
  -H "Authorization: Bearer your-api-key"
```

### Management

```bash
# Start all services
docker compose up -d

# View logs
docker logs -f cli-proxy-api

# Restart after config change
docker compose restart cli-proxy-api

# Stop all
docker compose down
```

## Backup System

The backup service:
- Exports usage data every `BACKUP_INTERVAL` minutes
- Saves to `backups/usage-YYYYMMDD_HHMMSS.json`
- Maintains `backups/usage-latest.json` for quick restore
- Cleans up files older than `BACKUP_RETENTION_DAYS`
- Skips empty backups (total_requests = 0)

The restore service:
- Runs once on startup
- Imports from `usage-latest.json` if available

## File Structure

```
ai-cli-proxy/
├── docker-compose.yml    # Docker services
├── config.yaml           # Service config (gitignored)
├── config.yaml.example   # Config template
├── .env                  # Environment vars (gitignored)
├── .env.example          # Env template
├── auth/                 # Auth credentials (gitignored)
├── backups/              # Usage data backups
├── CLAUDE.md             # AI agent context
└── README.md             # This file
```

## Security

- Change default `api-keys` in `config.yaml`
- Change `remote-management.secret-key`
- Set strong `API_TOKEN` in `.env`
- Never commit `.env` or `config.yaml`

## Troubleshooting

**Service won't start:**
```bash
docker compose logs cli-proxy-api
```

**Backup not working:**
```bash
docker logs cli-proxy-backup
# Verify API_TOKEN matches config.yaml api-keys
```

**401 Unauthorized:**
- Check `Authorization: Bearer <key>` header
- Verify key exists in `config.yaml` api-keys

## License

MIT
