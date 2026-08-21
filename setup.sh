#!/usr/bin/env bash
# ==============================================================================
# qBittorrent-nox Multi-Profile & Cloudflare Worker Auto-Sync Installer
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "======================================================================"
echo "    qBittorrent-nox Multi-Profile & Cloudflare Worker Installer      "
echo "======================================================================"
echo -e "${RESET}"

# Helper function to hash password via Python 3 (qBittorrent PBKDF2 SHA-512)
hash_password() {
    python3 -c "
import os, base64, hashlib, sys
pw = sys.argv[1]
salt = os.urandom(16)
key = hashlib.pbkdf2_hmac('sha512', pw.encode('utf-8'), salt, 100000)
salt_b64 = base64.b64encode(salt).decode('utf-8')
key_b64 = base64.b64encode(key).decode('utf-8')
print(f'@ByteArray({salt_b64}:{key_b64})')
" "$1"
}

# 1. Dependency Checks
echo -e "\n${BOLD}Step 1: Checking Dependencies...${RESET}"

if command -v qbittorrent-nox >/dev/null 2>&1; then
    echo -e "  [${GREEN}✓${RESET}] qbittorrent-nox is installed."
else
    echo -e "  [${RED}✗${RESET}] qbittorrent-nox is required. Please install it first."
    exit 1
fi

if command -v cloudflared >/dev/null 2>&1; then
    echo -e "  [${GREEN}✓${RESET}] cloudflared is installed."
else
    echo -e "  [${YELLOW}!${RESET}] cloudflared not found in standard PATH. Please ensure cloudflared is available."
fi

# 2. Cloudflare Worker Credentials
echo -e "\n${BOLD}Step 2: Cloudflare Worker Sync Configuration${RESET}"
read -p "Enter your Cloudflare Worker URL (e.g. https://your-worker.workers.dev): " WORKER_URL
read -s -p "Enter your Worker SECRET_KEY: " SECRET_KEY
echo ""

# 3. Configure Profile 1 (Private)
echo -e "\n${BOLD}Step 3: Profile 1 Configuration (Private Profile)${RESET}"
read -p "Enter name for Profile 1 [default: Private]: " USER1_NAME
USER1_NAME=${USER1_NAME:-Private}

read -s -p "Enter Web UI password for Profile 1 ($USER1_NAME): " USER1_PASS
echo ""
if [ -z "$USER1_PASS" ]; then
    USER1_PASS=$(openssl rand -base64 12)
    echo -e "Generated Password for $USER1_NAME: ${CYAN}$USER1_PASS${RESET}"
fi

read -p "Enter Web UI Port for Profile 1 ($USER1_NAME) [default: 8080]: " USER1_PORT
USER1_PORT=${USER1_PORT:-8080}

read -p "Enter Download Path for Profile 1 ($USER1_NAME) [default: $HOME/Downloads/$USER1_NAME]: " USER1_DIR
USER1_DIR=${USER1_DIR:-$HOME/Downloads/$USER1_NAME}

USER1_HASH=$(hash_password "$USER1_PASS")

# 4. Configure Profile 2 (Public)
echo -e "\n${BOLD}Step 4: Profile 2 Configuration (Public Profile)${RESET}"
read -p "Enter name for Profile 2 [default: Public]: " USER2_NAME
USER2_NAME=${USER2_NAME:-Public}

read -s -p "Enter Web UI password for Profile 2 ($USER2_NAME): " USER2_PASS
echo ""
if [ -z "$USER2_PASS" ]; then
    USER2_PASS=$(openssl rand -base64 12)
    echo -e "Generated Password for $USER2_NAME: ${CYAN}$USER2_PASS${RESET}"
fi

read -p "Enter Web UI Port for Profile 2 ($USER2_NAME) [default: 8090]: " USER2_PORT
USER2_PORT=${USER2_PORT:-8090}

read -p "Enter Download Path for Profile 2 ($USER2_NAME) [default: $HOME/Downloads/$USER2_NAME]: " USER2_DIR
USER2_DIR=${USER2_DIR:-$HOME/Downloads/$USER2_NAME}

USER2_HASH=$(hash_password "$USER2_PASS")

# Create Directories
CONF_DIR1="$HOME/.config/qBittorrent-$USER1_NAME"
CONF_DIR2="$HOME/.config/qBittorrent-$USER2_NAME"

mkdir -p "$CONF_DIR1/qBittorrent"
mkdir -p "$CONF_DIR2/qBittorrent"
mkdir -p "$USER1_DIR"
mkdir -p "$USER2_DIR"

# Write qBittorrent.conf for Profile 1
cat <<EOF > "$CONF_DIR1/qBittorrent/qBittorrent.conf"
[Preferences]
Downloads\SavePath=$USER1_DIR
WebUI\Enabled=true
WebUI\Username=$USER1_NAME
WebUI\Password_PBKDF2="$USER1_HASH"
WebUI\Port=$USER1_PORT
WebUI\UseUPnP=false
BitTorrent\Session\Port=6881
EOF

# Write qBittorrent.conf for Profile 2
cat <<EOF > "$CONF_DIR2/qBittorrent/qBittorrent.conf"
[Preferences]
Downloads\SavePath=$USER2_DIR
WebUI\Enabled=true
WebUI\Username=$USER2_NAME
WebUI\Password_PBKDF2="$USER2_HASH"
WebUI\Port=$USER2_PORT
WebUI\UseUPnP=false
BitTorrent\Session\Port=6882
EOF

# Create Baked-in Systemd Runner Scripts
cat <<EOF > "$CONF_DIR1/run_service.sh"
#!/usr/bin/env bash
/usr/bin/qbittorrent-nox --profile="$CONF_DIR1" --webui-port=$USER1_PORT &
QB_PID=\$!

rm -f "$CONF_DIR1/tunnel.log"
cloudflared tunnel --url "http://localhost:$USER1_PORT" > "$CONF_DIR1/tunnel.log" 2>&1 &
CF_PID=\$!

for i in {1..20}; do
    if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" >/dev/null 2>&1; then
        TUNNEL_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" | head -n 1)
        curl -s "${WORKER_URL}/set?secret=${SECRET_KEY}&user=$(echo $USER1_NAME | tr '[:upper:]' '[:lower:]')&url=\${TUNNEL_URL}" >/dev/null
        break
    fi
    sleep 1
done

wait \$QB_PID \$CF_PID
EOF

cat <<EOF > "$CONF_DIR2/run_service.sh"
#!/usr/bin/env bash
/usr/bin/qbittorrent-nox --profile="$CONF_DIR2" --webui-port=$USER2_PORT &
QB_PID=\$!

rm -f "$CONF_DIR2/tunnel.log"
cloudflared tunnel --url "http://localhost:$USER2_PORT" > "$CONF_DIR2/tunnel.log" 2>&1 &
CF_PID=\$!

for i in {1..20}; do
    if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" >/dev/null 2>&1; then
        TUNNEL_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" | head -n 1)
        curl -s "${WORKER_URL}/set?secret=${SECRET_KEY}&user=$(echo $USER2_NAME | tr '[:upper:]' '[:lower:]')&url=\${TUNNEL_URL}" >/dev/null
        break
    fi
    sleep 1
done

wait \$QB_PID \$CF_PID
EOF

chmod +x "$CONF_DIR1/run_service.sh"
chmod +x "$CONF_DIR2/run_service.sh"

# 5. Systemd Setup
echo -e "\n${BOLD}Step 5: Registering Systemd Services...${RESET}"

SERVICE_PATH1="/etc/systemd/system/qbittorrent-$USER1_NAME.service"
SERVICE_PATH2="/etc/systemd/system/qbittorrent-$USER2_NAME.service"

sudo bash -c "cat <<EOF > $SERVICE_PATH1
[Unit]
Description=qBittorrent-nox ($USER1_NAME) with Cloudflare Worker Auto-Sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$CONF_DIR1/run_service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

sudo bash -c "cat <<EOF > $SERVICE_PATH2
[Unit]
Description=qBittorrent-nox ($USER2_NAME) with Cloudflare Worker Auto-Sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$CONF_DIR2/run_service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable --now "qbittorrent-$USER1_NAME"
sudo systemctl enable --now "qbittorrent-$USER2_NAME"

echo -e "\n${GREEN}${BOLD}======================================================================${RESET}"
echo -e "${GREEN}${BOLD}                Installation Complete!                                ${RESET}"
echo -e "${GREEN}${BOLD}======================================================================${RESET}"
echo -e "Permanent Worker URLs:"
echo -e "  🔒 $(echo $USER1_NAME): ${CYAN}${WORKER_URL}/$(echo $USER1_NAME | tr '[:upper:]' '[:lower:]')${RESET}"
echo -e "  🌐 $(echo $USER2_NAME): ${CYAN}${WORKER_URL}/$(echo $USER2_NAME | tr '[:upper:]' '[:lower:]')${RESET}"
echo ""
