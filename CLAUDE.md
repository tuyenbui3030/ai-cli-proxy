# AI CLI Proxy Service

> Context file for Claude Code and AI agents

## Project Overview

This is a **Docker-based AI CLI Proxy Service** that proxies requests to various AI model providers (Gemini, Claude, Codex, etc.) through a unified OpenAI-compatible API interface.

### Key Purpose
- Provide a single endpoint for multiple AI providers
- Manage API keys and authentication centrally
- Track usage statistics across all models
- Auto-backup and restore usage data

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                      │
├─────────────────┬─────────────────┬─────────────────────────┤
│  cli-proxy-api  │     backup      │        restore          │
│  (Main Service) │  (Scheduled)    │     (One-time)          │
│                 │                 │                         │
│  - API Proxy    │  - Export data  │  - Import data          │
│  - Management   │  - Cleanup old  │  - Run on startup       │
│  - Auth         │  - Every 5min   │                         │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## File Structure

```
ai-cli-proxy/
├── docker-compose.yml    # Main Docker Compose configuration
├── config.yaml           # CLIProxyAPI configuration (gitignored)
├── config.yaml.example   # Template for config.yaml
├── .env                  # Environment variables (gitignored)
├── .env.example          # Template for .env
├── auth/                 # Auth credential files (gitignored)
│   └── antigravity-*.json
├── backups/              # Usage data backups (gitignored)
│   ├── usage-latest.json.gz
│   └── usage-*.json.gz
├── CLAUDE.md             # This file - AI agent context
└── README.md             # User documentation
```

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `cli-proxy-api` | `eceasy/cli-proxy-api:latest` | 8317 | Main API proxy |
| `backup` | `alpine:latest` | - | Periodic data backup |
| `restore` | `alpine:latest` | - | One-time data restore |

## Common Operations

### Start Services
```bash
docker compose up -d cli-proxy-api backup
```

### View Logs
```bash
docker logs -f cli-proxy-api
docker logs -f cli-proxy-backup
```

### Restart After Config Change
```bash
docker compose restart cli-proxy-api
```

### Check Status
```bash
docker compose ps
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/chat/completions` | POST | OpenAI-compatible chat API |
| `/v1/models` | GET | List available models |
| `/v0/management/usage/export` | GET | Export usage data |
| `/v0/management/usage/import` | POST | Import usage data |
| `/` | GET | Management panel |

## Configuration

### config.yaml
Main service configuration:
- `api-keys`: Authentication keys for API access
- `remote-management`: Management panel settings
- `routing.strategy`: Load balancing strategy (round-robin)
- `gemini-api-key`, `claude-api-key`: Provider API keys

### .env
Environment variables:
- `PORT`: Service port (default: 8317)
- `TZ`: Timezone
- `API_TOKEN`: Token for backup/restore operations
- `BACKUP_INTERVAL`: Backup interval in minutes
- `BACKUP_RETENTION_DAYS`: How long to keep backups

## Development Notes

### Adding New Model Providers
1. Add provider API key in `config.yaml` under appropriate section
2. Restart the service: `docker compose restart cli-proxy-api`

### Backup System
- Backups run every `BACKUP_INTERVAL` minutes (default: 5)
- Only saves if `total_requests > 0` to avoid empty backups
- Old backups cleaned up after `BACKUP_RETENTION_DAYS` days
- `usage-latest.json.gz` always contains most recent valid backup (compressed)

### Restore System
- Runs once on startup
- Imports from `usage-latest.json.gz` (or `usage-latest.json` if exists)
- Container exits after restore (restart: "no")

## Troubleshooting

### Service won't start
```bash
docker compose logs cli-proxy-api
docker inspect cli-proxy-api | grep -A 10 Health
```

### Backup not working
```bash
docker logs cli-proxy-backup
# Check API_TOKEN matches config.yaml api-keys
```

### API returns 401
- Verify `Authorization: Bearer <key>` header
- Check key exists in `config.yaml` under `api-keys`
