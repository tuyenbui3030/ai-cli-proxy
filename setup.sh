#!/bin/bash
# CLIProxyAPI VPS Setup Script

set -e

INSTALL_DIR="${INSTALL_DIR:-/opt/cli-proxy-api}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root or with sudo"
        exit 1
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    else
        log_info "Docker is already installed"
    fi
}

install_compose() {
    if ! docker compose version &> /dev/null; then
        log_info "Installing Docker Compose plugin..."
        apt-get update && apt-get install -y docker-compose-plugin
    else
        log_info "Docker Compose is already installed"
    fi
}

setup_directories() {
    log_info "Creating directory structure at $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR/auth"
    cd "$INSTALL_DIR"
}

# Copy docker-compose.yml from deploy folder
copy_compose_file() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        log_info "Copying docker-compose.yml from deploy folder..."
        cp "$SCRIPT_DIR/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml"
    else
        log_error "docker-compose.yml not found in deploy folder!"
        exit 1
    fi
}

create_config() {
    if [ ! -f config.yaml ]; then
        log_info "Creating default config.yaml..."
        cat > config.yaml << 'CONFIG'
host: ""
port: 8317

remote-management:
  allow-remote: true
  secret-key: "change-this-management-key"
  disable-control-panel: false

auth-dir: "~/.cli-proxy-api"

api-keys:
  - "sk-change-this-api-key"

debug: false
request-retry: 3
max-retry-interval: 30

quota-exceeded:
  switch-project: true
  switch-preview-model: true

routing:
  strategy: "round-robin"
CONFIG
    else
        log_warn "config.yaml already exists, skipping..."
    fi
}

# Copy .env from deploy folder
copy_env_file() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        if [ -f "$SCRIPT_DIR/.env.example" ]; then
            log_info "Copying .env from .env.example..."
            cp "$SCRIPT_DIR/.env.example" "$INSTALL_DIR/.env"
        else
            log_info "Creating default .env file..."
            cat > "$INSTALL_DIR/.env" << 'ENV'
PORT=8317
TZ=Asia/Ho_Chi_Minh
UPDATE_INTERVAL=3600
ENV
        fi
    else
        log_warn ".env already exists, skipping..."
    fi
}

create_management_script() {
    log_info "Creating management script..."
    cat > cli-proxy << 'SCRIPT'
#!/bin/bash
cd /opt/cli-proxy-api || exit 1

case "$1" in
    start)
        docker compose up -d cli-proxy-api
        echo "CLIProxyAPI started"
        ;;
    stop)
        docker compose down
        echo "CLIProxyAPI stopped"
        ;;
    restart)
        docker compose restart cli-proxy-api
        echo "CLIProxyAPI restarted"
        ;;
    logs)
        docker compose logs -f cli-proxy-api
        ;;
    status)
        docker compose ps
        ;;
    update)
        docker compose pull cli-proxy-api
        docker compose up -d cli-proxy-api
        echo "CLIProxyAPI updated"
        ;;
    autoupdate-on)
        docker compose --profile autoupdate up -d watchtower
        echo "Auto-update enabled"
        ;;
    autoupdate-off)
        docker compose --profile autoupdate down
        echo "Auto-update disabled"
        ;;
    config)
        ${EDITOR:-nano} config.yaml
        docker compose restart cli-proxy-api
        ;;
    add-auth)
        if [ -z "$2" ]; then
            echo "Usage: cli-proxy add-auth <path-to-json-file>"
            exit 1
        fi
        cp "$2" auth/
        echo "Auth file added. Server will auto-reload."
        ;;
    *)
        echo "CLIProxyAPI Management"
        echo ""
        echo "Usage: cli-proxy <command>"
        echo ""
        echo "Commands:"
        echo "  start           Start CLIProxyAPI"
        echo "  stop            Stop all services"
        echo "  restart         Restart CLIProxyAPI"
        echo "  logs            View logs"
        echo "  status          Show status"
        echo "  update          Pull & restart"
        echo "  autoupdate-on   Enable auto-update"
        echo "  autoupdate-off  Disable auto-update"
        echo "  config          Edit config"
        echo "  add-auth <file> Add auth file"
        ;;
esac
SCRIPT
    chmod +x cli-proxy
    ln -sf "$INSTALL_DIR/cli-proxy" /usr/local/bin/cli-proxy
}

start_services() {
    log_info "Starting CLIProxyAPI..."
    docker compose up -d cli-proxy-api
    
    read -p "Enable auto-update? (y/N): " enable_autoupdate
    if [[ "$enable_autoupdate" =~ ^[Yy]$ ]]; then
        docker compose --profile autoupdate up -d watchtower
        log_info "Auto-update enabled"
    fi
}

print_summary() {
    local ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    echo ""
    echo "=========================================="
    echo -e "${GREEN}CLIProxyAPI Installation Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "API URL:        http://$ip:8317/v1"
    echo "Management URL: http://$ip:8317"
    echo ""
    echo "Default credentials (CHANGE THESE!):"
    echo "  API Key:        sk-change-this-api-key"
    echo "  Management Key: change-this-management-key"
    echo ""
    echo "Commands: cli-proxy start|stop|logs|update|config"
    echo ""
}

# Copy auth files if present in deploy folder
copy_auth_files() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -d "$SCRIPT_DIR/auth" ] && [ "$(ls -A $SCRIPT_DIR/auth 2>/dev/null)" ]; then
        log_info "Copying auth files..."
        cp -r "$SCRIPT_DIR/auth/"* "$INSTALL_DIR/auth/"
        log_info "Copied $(ls $INSTALL_DIR/auth | wc -l) auth files"
    fi
}

# Copy config.yaml from deploy folder if present
copy_config_file() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -f "$SCRIPT_DIR/config.yaml" ] && [ ! -f "$INSTALL_DIR/config.yaml" ]; then
        log_info "Copying config.yaml from deploy folder..."
        cp "$SCRIPT_DIR/config.yaml" "$INSTALL_DIR/config.yaml"
    fi
}

main() {
    echo ""
    echo "================================"
    echo "  CLIProxyAPI VPS Setup Script"
    echo "================================"
    echo ""
    
    check_root
    install_docker
    install_compose
    setup_directories
    copy_auth_files
    copy_config_file
    copy_env_file
    copy_compose_file
    create_config
    create_management_script
    start_services
    print_summary
}

main "$@"
