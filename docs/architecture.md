# Architecture Overview

## System Design

```
                    ┌─────────────────────────────────────┐
                    │           Client Apps               │
                    │  (Claude Code, Cursor, CLI tools)   │
                    └───────────────┬─────────────────────┘
                                    │ OpenAI-compatible API
                                    ▼
┌───────────────────────────────────────────────────────────────────┐
│                        Docker Host                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                   cli-proxy-api                              │  │
│  │                   (eceasy/cli-proxy-api)                     │  │
│  │                                                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │  │
│  │  │ API Router   │  │ Auth Manager │  │ Usage Stats  │       │  │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘       │  │
│  │         │                                                    │  │
│  │  ┌──────┴───────────────────────────────────────────┐       │  │
│  │  │              Provider Adapters                    │       │  │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  │       │  │
│  │  │  │ Gemini │  │ Claude │  │ Codex  │  │ Others │  │       │  │
│  │  │  └────────┘  └────────┘  └────────┘  └────────┘  │       │  │
│  │  └──────────────────────────────────────────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────────────┐    ┌─────────────────────┐               │
│  │       backup        │    │       restore       │               │
│  │    (alpine:latest)  │    │    (alpine:latest)  │               │
│  │                     │    │                     │               │
│  │  - Runs every 5min  │    │  - Runs once on     │               │
│  │  - Exports usage    │    │    startup          │               │
│  │  - Cleans old files │    │  - Imports latest   │               │
│  └──────────┬──────────┘    └──────────┬──────────┘               │
│             │                          │                          │
│             └──────────┬───────────────┘                          │
│                        ▼                                          │
│              ┌─────────────────────┐                              │
│              │    ./backups/       │                              │
│              │  usage-latest.json  │                              │
│              │  usage-*.json       │                              │
│              └─────────────────────┘                              │
└───────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
            ┌───────────────────────────────────────────┐
            │           AI Provider APIs                 │
            │  ┌─────────┐ ┌─────────┐ ┌─────────┐      │
            │  │ Google  │ │Anthropic│ │ OpenAI  │      │
            │  │ Gemini  │ │ Claude  │ │ Codex   │      │
            │  └─────────┘ └─────────┘ └─────────┘      │
            └───────────────────────────────────────────┘
```

## Data Flow

### Request Flow
1. Client sends OpenAI-compatible request to port 8317
2. `cli-proxy-api` authenticates via `api-keys`
3. Router selects provider based on model name
4. Request forwarded to appropriate AI provider
5. Response returned to client

### Backup Flow
1. `backup` container runs every `BACKUP_INTERVAL` minutes
2. Calls `/v0/management/usage/export` API
3. Validates response has `total_requests > 0`
4. Saves timestamped file + updates `usage-latest.json`
5. Cleans up files older than `BACKUP_RETENTION_DAYS`

### Restore Flow
1. `restore` container starts after `cli-proxy-api` is healthy
2. Checks for `usage-latest.json`
3. POSTs data to `/v0/management/usage/import`
4. Container exits (restart: "no")

## Container Dependencies

```
cli-proxy-api (healthy)
       │
       ├──► backup (always running)
       │
       └──► restore (runs once, exits)
```

## Volume Mounts

| Container | Host Path | Container Path | Purpose |
|-----------|-----------|----------------|---------|
| cli-proxy-api | `./config.yaml` | `/CLIProxyAPI/config.yaml` | Service config |
| cli-proxy-api | `./auth/` | `/root/.cli-proxy-api/` | Auth credentials |
| backup | `./backups/` | `/backups/` | Backup storage |
| restore | `./backups/` | `/backups/` | Backup access |
