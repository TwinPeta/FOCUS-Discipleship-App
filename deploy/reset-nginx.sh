#!/usr/bin/env bash
# Resets nginx on a Debian/Ubuntu VPS to a clean config, then (optionally) re-creates proxies for the API and back office.
#
#   sudo bash reset-nginx.sh                                   # clean reset only (default nginx page)
#   sudo API_DOMAIN=api.example.com ADMIN_DOMAIN=admin.example.com bash reset-nginx.sh
#
# Vars: API_DOMAIN  ADMIN_DOMAIN  WEB_DOMAIN   API_PORT [4000]   ADMIN_PORT [3000]   WEB_PORT [3001]
#       CERTBOT_EMAIL (set it to also request HTTPS certificates)
#
# SAFE BY DEFAULT: /etc/nginx is backed up to /root/nginx-backup-<timestamp>.tar.gz before anything is removed.
# Let's Encrypt certificates (/etc/letsencrypt) are NOT touched.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root: sudo bash $0"; exit 1; }

API_PORT="${API_PORT:-4000}"; ADMIN_PORT="${ADMIN_PORT:-3000}"; WEB_PORT="${WEB_PORT:-3001}"
API_DOMAIN="${API_DOMAIN:-}"; ADMIN_DOMAIN="${ADMIN_DOMAIN:-}"; WEB_DOMAIN="${WEB_DOMAIN:-}"
log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }

command -v nginx >/dev/null || { log "Installing nginx"; apt-get update -y && apt-get install -y nginx; }

log "Backing up current config"
BACKUP="/root/nginx-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP" -C / etc/nginx
echo "Saved $BACKUP"

log "Stopping anything else holding port 80/443 (Caddy/Apache), if present"
for svc in caddy apache2; do
  systemctl is-active --quiet "$svc" 2>/dev/null && { echo "Stopping $svc"; systemctl stop "$svc"; systemctl disable "$svc" || true; }
done

log "Removing site and conf.d configuration"
rm -f /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* /etc/nginx/conf.d/*

log "Restoring the stock nginx.conf"
# Prefer the package's pristine copy; fall back to a minimal known-good file.
if ! dpkg-query -W nginx-common >/dev/null 2>&1 || ! apt-get install -y --reinstall -o Dpkg::Options::="--force-confmiss" -o Dpkg::Options::="--force-confnew" nginx-common >/dev/null 2>&1; then
  cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events { worker_connections 768; }

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    server_tokens off;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
fi
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d

proxy_block() { # name domain port [websocket]
  local name="$1" domain="$2" port="$3" ws="${4:-}"
  cat > "/etc/nginx/sites-available/$name" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};

    client_max_body_size 200m;

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
$( [[ -n "$ws" ]] && printf '        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n' )
        proxy_read_timeout 60s;
    }
}
EOF
  ln -sf "/etc/nginx/sites-available/$name" "/etc/nginx/sites-enabled/$name"
}

CREATED=()
if [[ -n "$API_DOMAIN" ]];   then log "Proxy $API_DOMAIN -> 127.0.0.1:$API_PORT (API, websockets on)"; proxy_block focus-api "$API_DOMAIN" "$API_PORT" ws; CREATED+=("$API_DOMAIN"); fi
if [[ -n "$ADMIN_DOMAIN" ]]; then log "Proxy $ADMIN_DOMAIN -> 127.0.0.1:$ADMIN_PORT (back office)"; proxy_block focus-admin "$ADMIN_DOMAIN" "$ADMIN_PORT"; CREATED+=("$ADMIN_DOMAIN"); fi
if [[ -n "$WEB_DOMAIN" ]];   then log "Proxy $WEB_DOMAIN -> 127.0.0.1:$WEB_PORT (web app)"; proxy_block focus-web "$WEB_DOMAIN" "$WEB_PORT"; CREATED+=("$WEB_DOMAIN"); fi

if [[ ${#CREATED[@]} -eq 0 ]]; then
  # Keep the stock welcome page so nginx has something to serve
  [[ -f /etc/nginx/sites-available/default ]] || cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.nginx-debian.html;
    server_name _;
    location / { try_files $uri $uri/ =404; }
}
EOF
  ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
fi

log "Testing and restarting nginx"
nginx -t
systemctl enable nginx >/dev/null 2>&1 || true
systemctl restart nginx

if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 'Nginx Full' >/dev/null || true
fi

if [[ -n "${CERTBOT_EMAIL:-}" && ${#CREATED[@]} -gt 0 ]]; then
  log "Requesting HTTPS certificates"
  command -v certbot >/dev/null || apt-get install -y certbot python3-certbot-nginx
  args=(); for d in "${CREATED[@]}"; do args+=(-d "$d"); done
  certbot --nginx --non-interactive --agree-tos -m "$CERTBOT_EMAIL" --redirect "${args[@]}"
fi

log "Done"
ss -tlnp | grep -E ':(80|443)\b' || true
echo "Backup of the previous config: $BACKUP"
echo "Restore it with:  sudo tar -xzf $BACKUP -C / && sudo nginx -t && sudo systemctl reload nginx"
