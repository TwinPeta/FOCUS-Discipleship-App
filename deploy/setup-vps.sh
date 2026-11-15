#!/usr/bin/env bash
#
# One-shot VPS setup: Caddy (auto-HTTPS) + Node.js API + Next.js web, run as systemd services.
# Target: Ubuntu 22.04/24.04 or Debian 12. Run as root (or with sudo). Safe to re-run.
#
# Usage:
#   sudo WEB_DOMAIN=app.example.com API_DOMAIN=api.example.com \
#        EMAIL=you@example.com REPO=git@github.com:TwinPeta/FOCUS-Discipleship-App.git \
#        bash setup-vps.sh
#
# Optional env vars (defaults in brackets):
#   BRANCH [main]          APP_USER [deploy]       APP_DIR [/srv/app]
#   API_PORT [4000]        WEB_PORT [3000]         NODE_MAJOR [20]
#   API_DIR [api]          WEB_DIR [web]           (folders inside the repo)
#   SSH_PORT [22]          SWAP_GB [0]  (set e.g. 2 on small VPS to avoid OOM during next build)
#   SKIP_WEB [0]           set 1 to deploy only the API (e.g. web/ isn't ready yet)
#
# DNS: point A/AAAA records for WEB_DOMAIN and API_DOMAIN at this server BEFORE running,
# otherwise Caddy cannot obtain certificates.

set -euo pipefail

# ───────────── config ─────────────
WEB_DOMAIN="${WEB_DOMAIN:-}"
API_DOMAIN="${API_DOMAIN:-}"
EMAIL="${EMAIL:-}"
REPO="${REPO:-}"
BRANCH="${BRANCH:-main}"
APP_USER="${APP_USER:-deploy}"
APP_DIR="${APP_DIR:-/srv/app}"
API_PORT="${API_PORT:-4000}"
WEB_PORT="${WEB_PORT:-3000}"
NODE_MAJOR="${NODE_MAJOR:-20}"
API_DIR="${API_DIR:-api}"
WEB_DIR="${WEB_DIR:-web}"
SSH_PORT="${SSH_PORT:-22}"
SWAP_GB="${SWAP_GB:-0}"
SKIP_WEB="${SKIP_WEB:-0}"
ENV_DIR="/etc/focus-app"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo)."
[[ -n "$API_DOMAIN" && -n "$EMAIL" && -n "$REPO" ]] || die "Set API_DOMAIN, EMAIL and REPO (and WEB_DOMAIN unless SKIP_WEB=1). See header."
[[ "$SKIP_WEB" == "1" || -n "$WEB_DOMAIN" ]] || die "WEB_DOMAIN is required unless SKIP_WEB=1."
command -v apt-get >/dev/null || die "Only apt-based systems (Ubuntu/Debian) are supported."
export DEBIAN_FRONTEND=noninteractive

# ───────────── base packages ─────────────
log "Installing base packages"
apt-get update -y
apt-get install -y curl ca-certificates gnupg git ufw fail2ban unattended-upgrades \
  debian-keyring debian-archive-keyring apt-transport-https build-essential openssl

# ───────────── optional swap ─────────────
if [[ "$SWAP_GB" != "0" && ! -f /swapfile ]]; then
  log "Creating ${SWAP_GB}G swap"
  fallocate -l "${SWAP_GB}G" /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ───────────── Node.js ─────────────
if ! command -v node >/dev/null || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt "$NODE_MAJOR" ]]; then
  log "Installing Node.js ${NODE_MAJOR}.x"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y nodejs
fi
NODE_BIN="$(command -v node)"
echo "node $(node -v), npm $(npm -v)"

# ───────────── Caddy (official repo) ─────────────
if ! command -v caddy >/dev/null; then
  log "Installing Caddy"
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -y
  apt-get install -y caddy
fi

# ───────────── app user & directories ─────────────
log "Creating user '${APP_USER}' and directories"
id "$APP_USER" &>/dev/null || adduser --disabled-password --gecos "" "$APP_USER"
mkdir -p "$APP_DIR" "$ENV_DIR" /var/log/caddy
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chown caddy:caddy /var/log/caddy 2>/dev/null || true
chmod 750 "$ENV_DIR"; chgrp "$APP_USER" "$ENV_DIR"

# Give the deploy user your SSH key so you can log in as them (skips if root has none)
if [[ -f /root/.ssh/authorized_keys && ! -f /home/$APP_USER/.ssh/authorized_keys ]]; then
  install -d -m 700 -o "$APP_USER" -g "$APP_USER" /home/$APP_USER/.ssh
  install -m 600 -o "$APP_USER" -g "$APP_USER" /root/.ssh/authorized_keys /home/$APP_USER/.ssh/authorized_keys
fi

# ───────────── clone repo ─────────────
if [[ ! -d "$APP_DIR/.git" ]]; then
  log "Cloning $REPO"
  # Private repo over SSH? Add a deploy key for $APP_USER first (ssh-keygen -t ed25519) and add it to GitHub.
  sudo -u "$APP_USER" -H git clone --branch "$BRANCH" "$REPO" "$APP_DIR" \
    || die "Clone failed. For a private repo, add ~$APP_USER/.ssh/id_ed25519.pub as a GitHub deploy key (or use an https URL with a token), then re-run."
fi

# ───────────── environment files (created once, never overwritten) ─────────────
if [[ ! -f "$ENV_DIR/api.env" ]]; then
  log "Writing $ENV_DIR/api.env"
  CORS="https://${WEB_DOMAIN:-$API_DOMAIN}"
  cat > "$ENV_DIR/api.env" <<EOF
NODE_ENV=production
PORT=${API_PORT}
BASE_URL=https://${API_DOMAIN}
CORS_ORIGINS=${CORS}
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
  cat > "$ENV_DIR/web.env" <<EOF
NODE_ENV=production
PORT=${WEB_PORT}
HOSTNAME=127.0.0.1
NEXT_PUBLIC_API_URL=https://${API_DOMAIN}/v1
EOF
fi
chown root:"$APP_USER" "$ENV_DIR"/*.env; chmod 640 "$ENV_DIR"/*.env

# ───────────── systemd services ─────────────
log "Installing systemd services"
write_unit() { # name, description, workdir, envfile, execstart
  cat > "/etc/systemd/system/$1.service" <<EOF
[Unit]
Description=$2
After=network.target

[Service]
User=${APP_USER}
WorkingDirectory=$3
EnvironmentFile=$4
ExecStart=$5
Restart=always
RestartSec=3
# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=${APP_DIR}

[Install]
WantedBy=multi-user.target
EOF
}
write_unit focus-api "FOCUS/FCU Node.js API" "$APP_DIR/$API_DIR" "$ENV_DIR/api.env" "$NODE_BIN src/server.js"
[[ "$SKIP_WEB" == "1" ]] || \
  write_unit focus-web "FOCUS/FCU Next.js web" "$APP_DIR/$WEB_DIR" "$ENV_DIR/web.env" "$(command -v npm) run start"
systemctl daemon-reload

# ───────────── deploy helper (run later for every release) ─────────────
log "Installing /usr/local/bin/focus-deploy"
cat > /usr/local/bin/focus-deploy <<EOF
#!/usr/bin/env bash
# Pull latest code, install, build, restart. Usage: sudo focus-deploy [branch]
set -euo pipefail
BRANCH="\${1:-${BRANCH}}"
run() { sudo -u ${APP_USER} -H bash -lc "\$*"; }

run "cd ${APP_DIR} && git fetch --all --prune && git checkout \$BRANCH && git reset --hard origin/\$BRANCH"
run "cd ${APP_DIR}/${API_DIR} && npm ci --omit=dev"
# Apply database migrations (Prisma) when DATABASE_URL is configured
run "cd ${APP_DIR}/${API_DIR} && set -a && . ${ENV_DIR}/api.env && set +a && { [ -z \"\$DATABASE_URL\" ] || npm run db:deploy; }"
systemctl restart focus-api
if [[ "${SKIP_WEB}" != "1" && -d ${APP_DIR}/${WEB_DIR} ]]; then
  run "cd ${APP_DIR}/${WEB_DIR} && npm ci && npm run build"
  systemctl restart focus-web
fi
systemctl is-active focus-api
echo "Deployed \$BRANCH"
EOF
chmod +x /usr/local/bin/focus-deploy

# ───────────── Caddy config ─────────────
log "Configuring Caddy"
{
  echo "{"
  echo "	email ${EMAIL}"
  echo "}"
  echo
  cat <<EOF
(common) {
	encode zstd gzip
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options nosniff
		-Server
	}
}

${API_DOMAIN} {
	import common
	log {
		output file /var/log/caddy/api.log
	}
	# Plain HTTP + WebSocket (/v1/realtime) are both proxied transparently
	reverse_proxy 127.0.0.1:${API_PORT} {
		health_uri /v1/health
		health_interval 30s
	}
}
EOF
  if [[ "$SKIP_WEB" != "1" ]]; then
    cat <<EOF

${WEB_DOMAIN} {
	import common
	log {
		output file /var/log/caddy/web.log
	}
	reverse_proxy 127.0.0.1:${WEB_PORT}
}

www.${WEB_DOMAIN} {
	redir https://${WEB_DOMAIN}{uri} permanent
}
EOF
  fi
} > /etc/caddy/Caddyfile
caddy fmt --overwrite /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile
chown -R caddy:caddy /var/log/caddy 2>/dev/null || true
systemctl enable caddy && systemctl restart caddy

# ───────────── firewall & hardening ─────────────
log "Configuring firewall (ufw) and fail2ban"
ufw allow "${SSH_PORT}/tcp"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp   # HTTP/3
ufw --force enable
systemctl enable --now fail2ban
dpkg-reconfigure -f noninteractive unattended-upgrades || true

# ───────────── first deploy ─────────────
log "Running first deploy"
systemctl enable focus-api
[[ "$SKIP_WEB" == "1" ]] || systemctl enable focus-web
if /usr/local/bin/focus-deploy "$BRANCH"; then
  :
else
  echo "First deploy had errors (e.g. web/ not built yet). Fix, then run: sudo focus-deploy"
fi

cat <<EOF

────────────────────────────────────────────
Done.
  API:  https://${API_DOMAIN}/v1/health     (docs: https://${API_DOMAIN}/docs)
  Web:  https://${WEB_DOMAIN:-n/a}

Next steps
  • Redeploy any time:      sudo focus-deploy [branch]
  • API logs:               journalctl -u focus-api -f
  • Web logs:               journalctl -u focus-web -f
  • Caddy logs:             journalctl -u caddy -f   (and /var/log/caddy/*.log)
  • Edit config:            ${ENV_DIR}/api.env, ${ENV_DIR}/web.env  → sudo systemctl restart focus-api focus-web
  • Optional: disable SSH password login & root login in /etc/ssh/sshd_config once your key works for '${APP_USER}'.
────────────────────────────────────────────
EOF
