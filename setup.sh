#!/usr/bin/env bash
# ==============================================================================
# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood + TinyURL API)
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
echo "    qBittorrent-nox Multi-Profile AIO Installer (TinyURL Auto-Update)  "
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

# 1. Dynamic Binary Path Detection & Dependency Checks
echo -e "\n${BOLD}Step 1: Checking Dependencies & Environment...${RESET}"

BASH_BIN=$(command -v bash || echo "/usr/bin/bash")

if command -v qbittorrent-nox >/dev/null 2>&1; then
    QBT_BIN=$(command -v qbittorrent-nox)
    echo -e "  [${GREEN}✓${RESET}] qbittorrent-nox found at $QBT_BIN"
else
    echo -e "  [${RED}✗${RESET}] qbittorrent-nox is required. Please install it first."
    exit 1
fi

if command -v cloudflared >/dev/null 2>&1; then
    CF_BIN=$(command -v cloudflared)
    echo -e "  [${GREEN}✓${RESET}] cloudflared found at $CF_BIN"
else
    echo -e "  [${RED}✗${RESET}] cloudflared is required for Quick Tunnels. Please install cloudflared first."
    exit 1
fi

if command -v npm >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
    echo -e "  [${GREEN}✓${RESET}] Node.js / npm / npx is available for Flood UI."
else
    echo -e "  [${YELLOW}!${RESET}] Node.js / npx not found. Flood UI requires npx."
fi

# 2. TinyURL API Credentials (Auto-detects ~/.tinyurl_env)
echo -e "\n${BOLD}Step 2: TinyURL API Configuration${RESET}"

ENV_FILE="$HOME/.tinyurl_env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

TINYURL_TOKEN=${TINYURL_API_TOKEN:-${TINYURL_TOKEN:-""}}

if [ -n "$TINYURL_TOKEN" ]; then
    echo -e "  [${GREEN}✓${RESET}] Loaded TinyURL API Token from $ENV_FILE"
else
    read -s -p "Enter your TinyURL API Token: " TINYURL_TOKEN
    echo ""
fi

# 3. Configure Profile 1 (Private Profile - VueTorrent)
echo -e "\n${BOLD}Step 3: Profile 1 Configuration (Private - VueTorrent UI)${RESET}"
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

# 4. Configure Profile 2 (Public Profile - Flood)
echo -e "\n${BOLD}Step 4: Profile 2 Configuration (Public - Flood UI)${RESET}"
read -p "Enter name for Profile 2 [default: Public]: " USER2_NAME
USER2_NAME=${USER2_NAME:-Public}

read -s -p "Enter Web UI password for Profile 2 ($USER2_NAME): " USER2_PASS
echo ""
if [ -z "$USER2_PASS" ]; then
    USER2_PASS=$(openssl rand -base64 12)
    echo -e "Generated Password for $USER2_NAME: ${CYAN}$USER2_PASS${RESET}"
fi

read -p "Enter qBittorrent API Port for Profile 2 ($USER2_NAME) [default: 8090]: " USER2_PORT
USER2_PORT=${USER2_PORT:-8090}

read -p "Enter Flood Web UI Port for Profile 2 ($USER2_NAME) [default: 3000]: " FLOOD_PORT
FLOOD_PORT=${FLOOD_PORT:-3000}

read -p "Enter Download Path for Profile 2 ($USER2_NAME) [default: $HOME/Downloads/$USER2_NAME]: " USER2_DIR
USER2_DIR=${USER2_DIR:-$HOME/Downloads/$USER2_NAME}

USER2_HASH=$(hash_password "$USER2_PASS")

CONF_DIR1="$HOME/.config/qBittorrent-$USER1_NAME"
CONF_DIR2="$HOME/.config/qBittorrent-$USER2_NAME"

# 5. Targeted Cleanup of Specified Profiles
echo -e "\n${BOLD}Step 5: Trashing Old Files for Selected Profiles...${RESET}"

# Stop processes targeted by profile paths / ports
pkill -9 -f "qbittorrent-nox --profile=$CONF_DIR1" >/dev/null 2>&1 || true
pkill -9 -f "qbittorrent-nox --profile=$CONF_DIR2" >/dev/null 2>&1 || true
pkill -9 -f "cloudflared tunnel --url http://localhost:$USER1_PORT" >/dev/null 2>&1 || true
pkill -9 -f "cloudflared tunnel --url http://localhost:$FLOOD_PORT" >/dev/null 2>&1 || true
pkill -9 -f "flood --port $FLOOD_PORT" >/dev/null 2>&1 || true

# Remove old config directories for selected profiles only
rm -rf "$CONF_DIR1" "$CONF_DIR2"
rm -rf "$HOME/.cache/qBittorrent-$USER1_NAME" "$HOME/.cache/qBittorrent-$USER2_NAME"
rm -rf "$HOME/.local/share/qBittorrent-$USER1_NAME" "$HOME/.local/share/qBittorrent-$USER2_NAME"

# Remove systemd services for selected profiles using pkexec
pkexec rm -f "/etc/systemd/system/qbittorrent-$USER1_NAME.service" "/etc/systemd/system/qbittorrent-$USER2_NAME.service" >/dev/null 2>&1 || true
echo -e "  [${GREEN}✓${RESET}] Old configuration folders for $USER1_NAME & $USER2_NAME trashed."

# Create Fresh Profile Directories
mkdir -p "$CONF_DIR1/qBittorrent"
mkdir -p "$CONF_DIR2/qBittorrent"
mkdir -p "$USER1_DIR"
mkdir -p "$USER2_DIR"

# Download VueTorrent for Profile 1
echo -e "\n${BOLD}Downloading & Installing VueTorrent Web UI...${RESET}"
mkdir -p "$CONF_DIR1/vuetorrent"
if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    curl -sL "https://github.com/VueTorrent/VueTorrent/releases/latest/download/vuetorrent.zip" -o "$CONF_DIR1/vuetorrent.zip"
    unzip -q -o "$CONF_DIR1/vuetorrent.zip" -d "$CONF_DIR1/"
    rm -f "$CONF_DIR1/vuetorrent.zip"
    echo -e "  [${GREEN}✓${RESET}] VueTorrent installed to $CONF_DIR1/vuetorrent"
else
    echo -e "  [${YELLOW}!${RESET}] Could not auto-download VueTorrent (requires curl & unzip)."
fi

# Write qBittorrent.conf for Profile 1 (Private with VueTorrent)
cat <<EOF > "$CONF_DIR1/qBittorrent/qBittorrent.conf"
[Preferences]
Downloads\SavePath=$USER1_DIR
WebUI\Enabled=true
WebUI\Username=$USER1_NAME
WebUI\Password_PBKDF2="$USER1_HASH"
WebUI\Port=$USER1_PORT
WebUI\UseUPnP=false
WebUI\AlternativeUIEnabled=true
WebUI\RootFolder=$CONF_DIR1/vuetorrent
BitTorrent\Session\Port=6881
EOF

# Write qBittorrent.conf for Profile 2 (Public for Flood)
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

# Create Baked-in Systemd Runner Script for Profile 1 (Private)
cat <<EOF > "$CONF_DIR1/run_service.sh"
#!/usr/bin/env bash

# Load TinyURL token dynamically from ~/.tinyurl_env at runtime (prevents token hardcoding)
if [ -f "\$HOME/.tinyurl_env" ]; then
    source "\$HOME/.tinyurl_env"
fi
TOKEN="\${TINYURL_API_TOKEN:-\${TINYURL_TOKEN}}"

# Start qBittorrent-nox in background
"$QBT_BIN" --profile="$CONF_DIR1" --webui-port=$USER1_PORT &
QB_PID=\$!

# Start cloudflared Quick Tunnel on VueTorrent Port
rm -f "$CONF_DIR1/tunnel.log"
"$CF_BIN" tunnel --url "http://localhost:$USER1_PORT" > "$CONF_DIR1/tunnel.log" 2>&1 &
CF_PID=\$!

# Initial Sync / Update to TinyURL API
for i in {1..20}; do
    if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" >/dev/null 2>&1; then
        TUNNEL_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" | head -n 1)
        
        ALIAS_FILE="$CONF_DIR1/tinyurl_alias.txt"
        LOG_FILE="$CONF_DIR1/tinyurl_api.log"
        
        if [ ! -f "\$ALIAS_FILE" ]; then
            RESP=\$(curl -s -X POST "https://api.tinyurl.com/create" \
                 -H "Authorization: Bearer \${TOKEN}" \
                 -H "Content-Type: application/json" \
                 -d "{\"url\":\"https://github.com\"}")
            echo "\$RESP" > "\$LOG_FILE"
            NEW_ALIAS=\$(echo "\$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('alias', ''))" 2>/dev/null)
            if [ -n "\$NEW_ALIAS" ]; then
                echo "\$NEW_ALIAS" > "\$ALIAS_FILE"
            fi
        fi

        if [ -f "\$ALIAS_FILE" ]; then
            SAVED_ALIAS=\$(cat "\$ALIAS_FILE")
            curl -s -X PATCH "https://api.tinyurl.com/update" \
                 -H "Authorization: Bearer \${TOKEN}" \
                 -H "Content-Type: application/json" \
                 -d "{\"domain\":\"tinyurl.com\",\"alias\":\"\${SAVED_ALIAS}\",\"url\":\"\${TUNNEL_URL}\"}" > "\$LOG_FILE" 2>&1
        fi
        break
    fi
    sleep 1
done

# Periodic Health Check Loop (Re-updates TinyURL target every 5 minutes)
(
    while kill -0 \$CF_PID 2>/dev/null; do
        sleep 300
        if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" >/dev/null 2>&1; then
            CURR_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR1/tunnel.log" | head -n 1)
            ALIAS_FILE="$CONF_DIR1/tinyurl_alias.txt"
            if [ -f "\$ALIAS_FILE" ]; then
                SAVED_ALIAS=\$(cat "\$ALIAS_FILE")
                curl -s -X PATCH "https://api.tinyurl.com/update" \
                     -H "Authorization: Bearer \${TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d "{\"domain\":\"tinyurl.com\",\"alias\":\"\${SAVED_ALIAS}\",\"url\":\"\${CURR_URL}\"}" > "$CONF_DIR1/tinyurl_api.log" 2>&1
            fi
        fi
    done
) &

wait \$QB_PID \$CF_PID
EOF

# Create Baked-in Systemd Runner Script for Profile 2 (Public)
cat <<EOF > "$CONF_DIR2/run_service.sh"
#!/usr/bin/env bash

# Load TinyURL token dynamically from ~/.tinyurl_env at runtime (prevents token hardcoding)
if [ -f "\$HOME/.tinyurl_env" ]; then
    source "\$HOME/.tinyurl_env"
fi
TOKEN="\${TINYURL_API_TOKEN:-\${TINYURL_TOKEN}}"

# Start qBittorrent-nox in background
"$QBT_BIN" --profile="$CONF_DIR2" --webui-port=$USER2_PORT &
QB_PID=\$!

sleep 2

# Start Flood Web UI Server
npx --yes flood --port $FLOOD_PORT --qbittorrent-url "http://localhost:$USER2_PORT" --qbittorrent-user "$USER2_NAME" --qbittorrent-pass "$USER2_PASS" > "$CONF_DIR2/flood.log" 2>&1 &
FLOOD_PID=\$!

# Start cloudflared Quick Tunnel pointing to Flood Web UI Port
rm -f "$CONF_DIR2/tunnel.log"
"$CF_BIN" tunnel --url "http://localhost:$FLOOD_PORT" > "$CONF_DIR2/tunnel.log" 2>&1 &
CF_PID=\$!

# Initial Sync / Update to TinyURL API
for i in {1..20}; do
    if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" >/dev/null 2>&1; then
        TUNNEL_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" | head -n 1)
        
        ALIAS_FILE="$CONF_DIR2/tinyurl_alias.txt"
        LOG_FILE="$CONF_DIR2/tinyurl_api.log"
        
        if [ ! -f "\$ALIAS_FILE" ]; then
            RESP=\$(curl -s -X POST "https://api.tinyurl.com/create" \
                 -H "Authorization: Bearer \${TOKEN}" \
                 -H "Content-Type: application/json" \
                 -d "{\"url\":\"https://github.com\"}")
            echo "\$RESP" > "\$LOG_FILE"
            NEW_ALIAS=\$(echo "\$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('alias', ''))" 2>/dev/null)
            if [ -n "\$NEW_ALIAS" ]; then
                echo "\$NEW_ALIAS" > "\$ALIAS_FILE"
            fi
        fi

        if [ -f "\$ALIAS_FILE" ]; then
            SAVED_ALIAS=\$(cat "\$ALIAS_FILE")
            curl -s -X PATCH "https://api.tinyurl.com/update" \
                 -H "Authorization: Bearer \${TOKEN}" \
                 -H "Content-Type: application/json" \
                 -d "{\"domain\":\"tinyurl.com\",\"alias\":\"\${SAVED_ALIAS}\",\"url\":\"\${TUNNEL_URL}\"}" > "\$LOG_FILE" 2>&1
        fi
        break
    fi
    sleep 1
done

# Periodic Health Check Loop (Re-updates TinyURL target every 5 minutes)
(
    while kill -0 \$CF_PID 2>/dev/null; do
        sleep 300
        if grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" >/dev/null 2>&1; then
            CURR_URL=\$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" "$CONF_DIR2/tunnel.log" | head -n 1)
            ALIAS_FILE="$CONF_DIR2/tinyurl_alias.txt"
            if [ -f "\$ALIAS_FILE" ]; then
                SAVED_ALIAS=\$(cat "\$ALIAS_FILE")
                curl -s -X PATCH "https://api.tinyurl.com/update" \
                     -H "Authorization: Bearer \${TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d "{\"domain\":\"tinyurl.com\",\"alias\":\"\${SAVED_ALIAS}\",\"url\":\"\${CURR_URL}\"}" > "$CONF_DIR2/tinyurl_api.log" 2>&1
            fi
        fi
    done
) &

wait \$QB_PID \$FLOOD_PID \$CF_PID
EOF

chmod +x "$CONF_DIR1/run_service.sh"
chmod +x "$CONF_DIR2/run_service.sh"

# 6. Systemd Unit Registration via pkexec
echo -e "\n${BOLD}Step 6: Registering Systemd Services...${RESET}"

SERVICE_PATH1="/etc/systemd/system/qbittorrent-$USER1_NAME.service"
SERVICE_PATH2="/etc/systemd/system/qbittorrent-$USER2_NAME.service"

pkexec bash -c "cat <<EOF > $SERVICE_PATH1
[Unit]
Description=qBittorrent-nox ($USER1_NAME - VueTorrent) with TinyURL Auto-Update
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$BASH_BIN $CONF_DIR1/run_service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

pkexec bash -c "cat <<EOF > $SERVICE_PATH2
[Unit]
Description=qBittorrent-nox ($USER2_NAME - Flood UI) with TinyURL Auto-Update
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
ExecStart=$BASH_BIN $CONF_DIR2/run_service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

pkexec systemctl daemon-reload
pkexec systemctl enable --now "qbittorrent-$USER1_NAME"
pkexec systemctl enable --now "qbittorrent-$USER2_NAME"

echo -e "\n${BOLD}Waiting for TinyURL links to generate...${RESET}"
for i in {1..12}; do
    if [ -f "$CONF_DIR1/tinyurl_alias.txt" ] && [ -f "$CONF_DIR2/tinyurl_alias.txt" ]; then
        break
    fi
    sleep 1
done

ALIAS1=$(cat "$CONF_DIR1/tinyurl_alias.txt" 2>/dev/null || echo "generating...")
ALIAS2=$(cat "$CONF_DIR2/tinyurl_alias.txt" 2>/dev/null || echo "generating...")

echo -e "\n${GREEN}${BOLD}======================================================================${RESET}"
echo -e "${GREEN}${BOLD}                Installation Complete!                                ${RESET}"
echo -e "${GREEN}${BOLD}======================================================================${RESET}"
echo -e "Your Static TinyURL Redirect Links:"
if [ "$ALIAS1" != "generating..." ]; then
    echo -e "  🔒 $USER1_NAME (VueTorrent): ${CYAN}https://tinyurl.com/${ALIAS1}${RESET}"
else
    echo -e "  🔒 $USER1_NAME (VueTorrent): ${YELLOW}Generating in background (check ~/.config/qBittorrent-$USER1_NAME/tinyurl_alias.txt)${RESET}"
fi

if [ "$ALIAS2" != "generating..." ]; then
    echo -e "  🌐 $USER2_NAME (Flood UI):   ${CYAN}https://tinyurl.com/${ALIAS2}${RESET}"
else
    echo -e "  🌐 $USER2_NAME (Flood UI):   ${YELLOW}Generating in background (check ~/.config/qBittorrent-$USER2_NAME/tinyurl_alias.txt)${RESET}"
fi
echo ""
