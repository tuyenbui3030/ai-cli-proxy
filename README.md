# CLIProxyAPI VPS Deployment

Bộ cài đặt Docker tự động cho CLIProxyAPI với auto-update và model warmup scheduler.

## 📦 Cấu trúc thư mục

```
ai-cli-proxy/
├── docker-compose.yml   # Docker Compose config (3 services)
├── config.yaml          # CLIProxyAPI config
├── ofelia.ini           # Cron scheduler config
├── .env                 # Environment variables (tạo từ .env.example)
├── .env.example         # Template cho .env
├── setup.sh             # Script cài đặt tự động
└── auth/                # Auth files
    └── antigravity-*.json
```

## 🐳 Services

| Service | Image | Mô tả |
|---------|-------|-------|
| `cli-proxy-api` | `eceasy/cli-proxy-api` | API Proxy chính |
| `ofelia` | `mcuadros/ofelia` | Cron scheduler cho model warmup |
| `watchtower` | `containrrr/watchtower` | Auto-update container (optional) |

## 🚀 Cài đặt nhanh

### 1. Clone và cấu hình

```bash
git clone <repo-url> ai-cli-proxy
cd ai-cli-proxy

# Tạo file .env
cp .env.example .env

# Sửa .env với API key của bạn
nano .env
```

### 2. Khởi động

```bash
# Chạy API + Scheduler
docker compose up -d cli-proxy-api ofelia

# Chạy với auto-update
docker compose --profile autoupdate up -d
```

### 3. Kiểm tra

```bash
docker compose ps
docker logs -f cli-proxy-api
```

## ⚙️ Environment Variables

| Variable | Default | Mô tả |
|----------|---------|-------|
| `PORT` | `8317` | Port của API |
| `TZ` | `Asia/Ho_Chi_Minh` | Timezone |
| `UPDATE_INTERVAL` | `3600` | Khoảng thời gian check update (giây) |
| `TRIGGER_API_KEY` | `sk-change-this-api-key` | API key cho model warmup |

## 🔧 Quản lý

```bash
# Khởi động
docker compose up -d

# Dừng
docker compose down

# Restart
docker compose restart

# Xem logs
docker logs -f cli-proxy-api
docker logs -f ofelia

# Xem trạng thái
docker compose ps
```

## 🌐 Endpoints

| URL | Mô tả |
|-----|-------|
| `http://IP:8317/v1` | API Endpoint (OpenAI compatible) |
| `http://IP:8317` | Management Panel |

## ⏰ Model Warmup (Ofelia Scheduler)

Tự động gọi API để warmup models vào **7h sáng mỗi ngày** (theo timezone).

### Models được trigger

| Model | Số lần gọi |
|-------|------------|
| `gemini-claude-sonnet-4-5` | 4 |
| `gemini-3-flash-preview` | 4 |

### Cấu hình schedule

Sửa `ofelia.ini`:

```ini
[job-local "warmup-sonnet"]
schedule = 0 7 * * *    # Cron: phút giờ ngày tháng thứ
command = wget ...
```

Sau đó restart:

```bash
docker compose restart ofelia
```

### Test trigger thủ công

```bash
# Kiểm tra env var
docker exec ofelia printenv TRIGGER_API_KEY

# Test API call
docker exec ofelia sh -c 'wget -q -O- \
  --header="Authorization: Bearer $TRIGGER_API_KEY" \
  --header="Content-Type: application/json" \
  --post-data='"'"'{"model":"gemini-claude-sonnet-4-5","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'"'"' \
  https://your-domain.com/v1/chat/completions'
```

## 🔄 Auto-Update (Watchtower)

Tự động update container `cli-proxy-api` khi có image mới.

```bash
# Bật auto-update
docker compose --profile autoupdate up -d

# Tắt auto-update
docker compose stop watchtower
```

## 📝 Config Files

### config.yaml

Cấu hình chính của CLIProxyAPI:
- `api-keys`: API keys để truy cập
- `model-mappings`: Map model names
- `remote-management`: Management panel settings

```bash
# Sửa config
nano config.yaml

# Restart để apply
docker compose restart cli-proxy-api
```

### ofelia.ini

Cấu hình cron jobs cho model warmup. Xem [Ofelia documentation](https://github.com/mcuadros/ofelia) để biết thêm.

## 🔐 Bảo mật

⚠️ **Quan trọng:**

1. Đổi `api-keys` trong `config.yaml`
2. Đổi `remote-management.secret-key` trong `config.yaml`
3. Đổi `TRIGGER_API_KEY` trong `.env`
4. Không commit file `.env` lên git

## 🐛 Troubleshooting

### API trả về 401 Unauthorized

```bash
# Kiểm tra API key
docker exec ofelia printenv TRIGGER_API_KEY

# So sánh với config.yaml
grep api-keys config.yaml
```

### Ofelia không chạy jobs

```bash
# Xem logs
docker logs ofelia

# Kiểm tra config
docker exec ofelia cat /etc/ofelia/config.ini
```

### Container không start

```bash
# Xem logs chi tiết
docker compose logs cli-proxy-api

# Kiểm tra health
docker inspect cli-proxy-api | grep -A 10 Health
```

## 📋 Thông tin mặc định

| Item | Value |
|------|-------|
| Port | `8317` |
| API Key | `sk-change-this-api-key` |
| Timezone | `Asia/Ho_Chi_Minh` |
| Warmup Schedule | `0 7 * * *` (7h sáng) |
| Auto-update Interval | `3600s` (1 giờ) |
