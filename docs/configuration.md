# Configuration Guide

## Overview

The service requires two configuration files:
- **`.env`**: Environment variables for Docker containers
- **`config.yaml`**: Main service configuration

## Environment Variables (.env)

### Basic Configuration

```env
# Server port (default: 8317)
PORT=8317

# Timezone for logs and backups
TZ=Asia/Ho_Chi_Minh
```

### Backup Configuration

```env
# Token for backup/restore API calls
# MUST match one of the api-keys in config.yaml
API_TOKEN=your-api-key-here

# API URL (internal Docker network)
API_URL=http://cli-proxy-api:8317

# Backup interval in minutes
BACKUP_INTERVAL=5

# Days to keep old backups
BACKUP_RETENTION_DAYS=10
```

## Service Configuration (config.yaml)

### Server Settings

```yaml
host: ""          # Bind address (empty = all interfaces)
port: 8317        # Listen port

tls:
  enable: false   # Enable HTTPS
  cert: ""        # Path to certificate
  key: ""         # Path to private key
```

### Authentication

```yaml
# API keys for client authentication
# Clients use these in Authorization: Bearer <key>
api-keys:
  - "sk-your-api-key-1"
  - "sk-your-api-key-2"
```

### Management Panel

```yaml
remote-management:
  allow-remote: true                    # Allow remote access
  secret-key: "your-secret-key"         # Admin authentication
  disable-control-panel: false          # Disable web UI
  panel-github-repository: "..."        # Panel source
```

### Provider API Keys

#### Google Gemini
```yaml
gemini-api-key:
  - api-key: "AIzaSy..."
  - api-key: "AIzaSy..."  # Multiple keys for rotation
```

#### Anthropic Claude
```yaml
claude-api-key:
  - api-key: "sk-ant-..."
```

#### OpenAI Codex
```yaml
codex-api-key:
  - api-key: "sk-..."
```

### Routing Configuration

```yaml
routing:
  strategy: "round-robin"  # Load balancing strategy

request-retry: 3           # Retry failed requests
max-retry-interval: 30     # Max seconds between retries

quota-exceeded:
  switch-project: true     # Auto-switch on quota limit
  switch-preview-model: true
```

### Advanced Settings

```yaml
debug: false                    # Enable debug logging
logging-to-file: false          # Write logs to file
logs-max-total-size-mb: 100     # Max log file size
usage-statistics-enabled: true  # Track usage stats

proxy-url: ""                   # HTTP proxy for outbound
force-model-prefix: false       # Require model prefix
ws-auth: false                  # WebSocket authentication

auth-dir: "~/.cli-proxy-api"    # Auth credentials directory
```

## Security Best Practices

1. **Generate strong API keys**
   ```bash
   openssl rand -hex 32
   ```

2. **Change default management key**
   ```yaml
   remote-management:
     secret-key: "generated-strong-key"
   ```

3. **Use TLS in production**
   ```yaml
   tls:
     enable: true
     cert: "/path/to/cert.pem"
     key: "/path/to/key.pem"
   ```

4. **Limit API key exposure**
   - Keep `config.yaml` in `.gitignore`
   - Use environment variables where possible

## Validation

After changing configuration:

```bash
# Validate docker-compose.yml
docker compose config

# Restart services
docker compose restart cli-proxy-api

# Check logs for errors
docker logs -f cli-proxy-api
```
