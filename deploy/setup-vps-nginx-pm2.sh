#!/usr/bin/env bash
#
# One-shot VPS setup: nginx (reverse proxy) + Certbot (HTTPS) + PM2 running the Node.js API and Next.js web.
# Target: Ubuntu 22.04/24.04 or Debian 12. Run as root. Safe to re-run.
#
# Usage:
#   sudo WEB_DOMAIN=app.example.com API_DOMAIN=api.example.com \
#        EMAIL=you@example.com REPO=git@github.com:TwinPeta/FOCUS-Discipleship-App.git \
#        bash setup-vps-nginx-pm2.sh
#
# Optional env vars (defaults in brackets):
#   BRANCH [main]   APP_USER [deploy]   APP_DIR [/srv/app]   API_PORT [4000]   WEB_PORT [3000]
#   API_DIR [api]   WEB_DIR [web]       NODE_MAJOR [20]      SSH_PORT [22]
#   SWAP_GB [0]     SKIP_WEB [0] (1 = API only)              SKIP_SSL [0] (1 = HTTP only, e.g. DNS not ready)
#
# DNS A/AAAA records for both domains must point at this server before issuing certificates.

set -euo pipefail

WEB_DOMAIN="${WEB_DOMAIN:-}"; API_DOMAIN="${API_DOMAIN:-}"; EMAIL="${EMAIL:-}"; REPO="${REPO:-}"
BRANCH="${BRANCH:-main}"; APP_USER="${APP_USER:-deploy}"; APP_DIR="${APP_DIR:-/srv/app}"
API_PORT="${API_PORT:-4000}"; WEB_PORT="${WEB_PORT:-3000}"; NODE_MAJOR="${NODE_MAJOR:-20}"
API_DIR="${API_DIR:-api}"; WEB_DIR="${WEB_DIR:-web}"; SSH_PORT="${SSH_PORT:-22}"
SWAP_GB="${SWAP_GB:-0}"; SKIP_WEB="${SKIP_WEB:-0}"; SKIP_SSL="${SKIP_SSL:-0}"
ENV_DIR="/etc/focus-app"
ECOSYSTEM="$ENV_DIR/ecosystem.config.js"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo)."
[[ -n "$API_DOMAIN" && -n "$EMAIL" && -n "$REPO" ]] || die "Set API_DOMAIN, EMAIL and REPO. See header."
[[ "$SKIP_WEB" == "1" || -n "$WEB_DOMAIN" ]] || die "WEB_DOMAIN is required unless SKIP_WEB=1."
command -v apt-get >/dev/null || die "Only apt-based systems (Ubuntu/Debian) are supported."
export DEBIAN_FRONTEND=noninteractive

# ───────────── packages ─────────────
log "Installing base packages, nginx, certbot"
apt-get update -y
apt-get install -y curl ca-certificates gnupg git ufw fail2ban unattended-upgrades build-essential openssl \
  nginx certbot python3-certbot-nginx

if [[ "$SWAP_GB" != "0" && ! -f /swapfile ]]; then
  log "Creating ${SWAP_GB}G swap"
  fallocate -l "${SWAP_GB}G" /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

if ! command -v node >/dev/null || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt "$NODE_MAJOR" ]]; then
  log "Installing Node.js ${NODE_MAJOR}.x"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y nodejs
fi
echo "node $(node -v), npm $(npm -v)"

command -v pm2 >/dev/null || { log "Installing PM2"; npm install -g pm2; }

# ───────────── user, dirs, repo ─────────────
log "Creating user '${APP_USER}' and cloning repo"
id "$APP_USER" &>/dev/null || adduser --disabled-password --gecos "" "$APP_USER"
mkdir -p "$APP_DIR" "$ENV_DIR"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chmod 750 "$ENV_DIR"; chgrp "$APP_USER" "$ENV_DIR"

if [[ -f /root/.ssh/authorized_keys && ! -f /home/$APP_USER/.ssh/authorized_keys ]]; then
  install -d -m 700 -o "$APP_USER" -g "$APP_USER" /home/$APP_USER/.ssh
  install -m 600 -o "$APP_USER" -g "$APP_USER" /root/.ssh/authorized_keys /home/$APP_USER/.ssh/authorized_keys
fi

if [[ ! -d "$APP_DIR/.git" ]]; then
  sudo -u "$APP_USER" -H git clone --branch "$BRANCH" "$REPO" "$APP_DIR" \
    || die "Clone failed. For a private repo, add ~$APP_USER/.ssh/id_ed25519.pub as a GitHub deploy key (or use an https URL with a token), then re-run."
fi

# ───────────── env files (created once, never overwritten) ─────────────
if [[ ! -f "$ENV_DIR/api.env" ]]; then
  log "Writing $ENV_DIR/api.env"
  SCHEME=$([[ "$SKIP_SSL" == "1" ]] && echo http || echo https)
  cat > "$ENV_DIR/api.env" <<EOF
NODE_ENV=production
PORT=${API_PORT}
BASE_URL=${SCHEME}://${API_DOMAIN}
CORS_ORIGINS=${SCHEME}://${WEB_DOMAIN:-$API_DOMAIN}
JWT_SECRET=$(openssl rand -hex 48)
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL_DAYS=30
# --- Fill these in, then restart the API ---
# PostgreSQL via Prisma, e.g. postgresql://user:pass@host:5432/focus?sslmode=require&connection_limit=10
# (without it the API falls back to memory and loses data on restart). After setting it run: npm run db:deploy
DATABASE_URL=
# First system admin (created on boot if none exists; remove the password afterwards)
ADMIN_EMAIL=
ADMIN_PASSWORD=
# Cloudflare R2 media storage
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=
R2_PUBLIC_URL=
# Resend email (MAIL_FROM's domain must be verified in Resend)
RESEND_API_KEY=
MAIL_FROM="FCU Student Community <no-reply@${API_DOMAIN}>"
BACKOFFICE_URL=https://${ADMIN_DOMAIN:-$API_DOMAIN}
EOF
fi
if [[ "$SKIP_WEB" != "1" && ! -f "$ENV_DIR/web.env" ]]; then
  log "Writing $ENV_DIR/web.env"
  SCHEME=$([[ "$SKIP_SSL" == "1" ]] && echo http || echo https)
  cat > "$ENV_DIR/web.env" <<EOF
NODE_ENV=production
PORT=${WEB_PORT}
HOSTNAME=127.0.0.1
NEXT_PUBLIC_API_URL=${SCHEME}://${API_DOMAIN}/v1
EOF
fi
chown root:"$APP_USER" "$ENV_DIR"/*.env; chmod 640 "$ENV_DIR"/*.env

# ───────────── PM2 ecosystem (reads the env files above) ─────────────
log "Writing $ECOSYSTEM"
cat > "$ECOSYSTEM" <<EOF
const fs = require('fs');
const load = (f) => Object.fromEntries(
  fs.readFileSync(f, 'utf8').split('\n')
    .filter((l) => l.trim() && !l.trim().startsWith('#') && l.includes('='))
    .map((l) => { const i = l.indexOf('='); return [l.slice(0, i).trim(), l.slice(i + 1).trim()]; })
);

module.exports = {
  apps: [
    {
      name: 'focus-api',
      cwd: '${APP_DIR}/${API_DIR}',
      script: 'src/server.js',
      env: load('${ENV_DIR}/api.env'),
      max_memory_restart: '400M',
      // The API keeps WebSocket + in-process state, so run a single instance (not cluster mode)
      instances: 1,
      exec_mode: 'fork',
    },
$( [[ "$SKIP_WEB" == "1" ]] || cat <<WEB
    {
      name: 'focus-web',
      cwd: '${APP_DIR}/${WEB_DIR}',
      script: 'npm',
      args: 'run start',
      env: load('${ENV_DIR}/web.env'),
      max_memory_restart: '600M',
    },
WEB
)
  ],
};
EOF
chown root:"$APP_USER" "$ECOSYSTEM"; chmod 640 "$ECOSYSTEM"

# ───────────── deploy helper ─────────────
log "Installing /usr/local/bin/focus-deploy"
cat > /usr/local/bin/focus-deploy <<EOF
#!/usr/bin/env bash
# Pull latest code, install, build, (re)start under PM2. Usage: sudo focus-deploy [branch]
set -euo pipefail
BRANCH="\${1:-${BRANCH}}"
run() { sudo -u ${APP_USER} -H bash -lc "\$*"; }

run "cd ${APP_DIR} && git fetch --all --prune && git checkout \$BRANCH && git reset --hard origin/\$BRANCH"
run "cd ${APP_DIR}/${API_DIR} && npm ci --omit=dev"
# Apply database migrations (Prisma) when DATABASE_URL is configured
run "cd ${APP_DIR}/${API_DIR} && set -a && . ${ENV_DIR}/api.env && set +a && { [ -z \"\$DATABASE_URL\" ] || npm run db:deploy; }"
if [[ "${SKIP_WEB}" != "1" && -d ${APP_DIR}/${WEB_DIR} ]]; then
  run "cd ${APP_DIR}/${WEB_DIR} && npm ci && npm run build"
fi
# startOrReload = start if new, graceful reload if running; --update-env re-reads the env files
run "pm2 startOrReload ${ECOSYSTEM} --update-env && pm2 save"
echo "Deployed \$BRANCH"; run "pm2 status"
EOF
chmod +x /usr/local/bin/focus-deploy

# ───────────── nginx ─────────────
log "Configuring nginx"
cat > /etc/nginx/conf.d/focus-upgrade-map.conf <<'EOF'
map $http_upgrade $connection_upgrade { default upgrade; '' close; }
EOF

cat > /etc/nginx/sites-available/focus-api <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${API_DOMAIN};

    client_max_body_size 25m;   # media uploads

    location / {
        proxy_pass http://127.0.0.1:${API_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        # WebSocket (/v1/realtime)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_read_timeout 3600s;
    }
}
EOF
ln -sf /etc/nginx/sites-available/focus-api /etc/nginx/sites-enabled/focus-api

if [[ "$SKIP_WEB" != "1" ]]; then
  cat > /etc/nginx/sites-available/focus-web <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${WEB_DOMAIN};

    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;

    location / {
        proxy_pass http://127.0.0.1:${WEB_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
    }
}
EOF
  ln -sf /etc/nginx/sites-available/focus-web /etc/nginx/sites-enabled/focus-web
fi
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx && systemctl reload nginx

# ───────────── firewall ─────────────
log "Configuring firewall and fail2ban"
ufw allow "${SSH_PORT}/tcp"; ufw allow 'Nginx Full'
ufw --force enable
systemctl enable --now fail2ban
dpkg-reconfigure -f noninteractive unattended-upgrades || true

# ───────────── PM2 on boot ─────────────
log "Enabling PM2 startup on boot"
env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" >/dev/null

# ───────────── first deploy ─────────────
log "Running first deploy"
/usr/local/bin/focus-deploy "$BRANCH" || echo "First deploy had errors (e.g. web/ not built yet). Fix, then run: sudo focus-deploy"

# ───────────── HTTPS ─────────────
if [[ "$SKIP_SSL" != "1" ]]; then
  log "Issuing Let's Encrypt certificates"
  DOMAINS=(-d "$API_DOMAIN"); [[ "$SKIP_WEB" == "1" ]] || DOMAINS+=(-d "$WEB_DOMAIN")
  certbot --nginx "${DOMAINS[@]}" --non-interactive --agree-tos -m "$EMAIL" --redirect \
    || echo "Certbot failed (check DNS points here). Retry: sudo certbot --nginx ${DOMAINS[*]}"
  # certbot installs a systemd timer for auto-renewal
fi

cat <<EOF

────────────────────────────────────────────
Done.
  API:  https://${API_DOMAIN}/v1/health   (docs: https://${API_DOMAIN}/docs)
  Web:  https://${WEB_DOMAIN:-n/a}

  • Redeploy:        sudo focus-deploy [branch]
  • Process status:  sudo -u ${APP_USER} pm2 status | pm2 logs focus-api
  • Edit config:     ${ENV_DIR}/api.env, ${ENV_DIR}/web.env  → sudo focus-deploy
  • nginx logs:      /var/log/nginx/{access,error}.log
────────────────────────────────────────────
EOF
