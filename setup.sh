#!/usr/bin/env bash
# ==============================================================================
# qBittorrent-nox Multi-Profile Setup & Cloudflare Routing Installer
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
echo "    qBittorrent-nox Multi-Profile & Cloudflare Setup Installer       "
echo "======================================================================"
echo -e "${RESET}"

# Check for root / sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Note: Running as non-root. Sudo prompts will be used for systemd installations.${RESET}"
fi

# 1. Dependency Checks
echo -e "\n${BOLD}Step 1: Checking Dependencies...${RESET}"

if command -v qbittorrent-nox >/dev/null 2>&1; then
    echo -e "  [${GREEN}✓${RESET}] qbittorrent-nox is installed."
else
    echo -e "  [${YELLOW}!${RESET}] qbittorrent-nox is NOT installed."
    read -p "Would you like to install qbittorrent-nox now? (y/n): " INSTALL_QB
    if [[ "$INSTALL_QB" =~ ^[Yy]$ ]]; then
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y qbittorrent-nox
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y qbittorrent-nox
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm qbittorrent-nox
        else
            echo -e "  [${RED}✗${RESET}] Automatic package manager installation not supported. Please install qbittorrent-nox manually."
            exit 1
        fi
    else
        echo -e "  [${RED}✗${RESET}] qbittorrent-nox is required to proceed. Exiting."
        exit 1
    fi
fi

# 2. Configure Profile 1
echo -e "\n${BOLD}Step 2: Profile 1 Configuration${RESET}"
read -p "Enter username for Profile 1 [default: user1]: " USER1_NAME
USER1_NAME=${USER1_NAME:-user1}

read -p "Enter Web UI Port for Profile 1 [default: 8080]: " USER1_PORT
USER1_PORT=${USER1_PORT:-8080}

read -p "Enter Download Path for Profile 1 [default: $HOME/Downloads/$USER1_NAME]: " USER1_DIR
USER1_DIR=${USER1_DIR:-$HOME/Downloads/$USER1_NAME}

# 3. Configure Profile 2
echo -e "\n${BOLD}Step 3: Profile 2 Configuration${RESET}"
read -p "Enter username for Profile 2 [default: user2]: " USER2_NAME
USER2_NAME=${USER2_NAME:-user2}

read -p "Enter Web UI Port for Profile 2 [default: 8081]: " USER2_PORT
USER2_PORT=${USER2_PORT:-8081}

read -p "Enter Download Path for Profile 2 [default: $HOME/Downloads/$USER2_NAME]: " USER2_DIR
USER2_DIR=${USER2_DIR:-$HOME/Downloads/$USER2_NAME}

# Create Directories
CONF_DIR1="$HOME/.config/qBittorrent-$USER1_NAME"
CONF_DIR2="$HOME/.config/qBittorrent-$USER2_NAME"

echo -e "\n${BOLD}Creating Directories...${RESET}"
mkdir -p "$CONF_DIR1/qBittorrent"
mkdir -p "$CONF_DIR2/qBittorrent"
mkdir -p "$USER1_DIR"
mkdir -p "$USER2_DIR"

# Generate qBittorrent.conf for Profile 1
cat <<EOF > "$CONF_DIR1/qBittorrent/qBittorrent.conf"
[Preferences]
Downloads\SavePath=$USER1_DIR
WebUI\Enabled=true
WebUI\Port=$USER1_PORT
WebUI\UseUPnP=false
BitTorrent\Session\Port=6881
EOF

# Generate qBittorrent.conf for Profile 2
cat <<EOF > "$CONF_DIR2/qBittorrent/qBittorrent.conf"
[Preferences]
Downloads\SavePath=$USER2_DIR
WebUI\Enabled=true
WebUI\Port=$USER2_PORT
WebUI\UseUPnP=false
BitTorrent\Session\Port=6882
EOF

echo -e "  [${GREEN}✓${RESET}] Created config for $USER1_NAME at $CONF_DIR1"
echo -e "  [${GREEN}✓${RESET}] Created config for $USER2_NAME at $CONF_DIR2"

# 4. Systemd Setup
echo -e "\n${BOLD}Step 4: Setting up Systemd Services...${RESET}"

SERVICE_PATH1="/etc/systemd/system/qbittorrent-$USER1_NAME.service"
SERVICE_PATH2="/etc/systemd/system/qbittorrent-$USER2_NAME.service"

sudo bash -c "cat <<EOF > $SERVICE_PATH1
[Unit]
Description=qBittorrent-nox ($USER1_NAME)
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/qbittorrent-nox --profile=$CONF_DIR1 --webui-port=$USER1_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

sudo bash -c "cat <<EOF > $SERVICE_PATH2
[Unit]
Description=qBittorrent-nox ($USER2_NAME)
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/qbittorrent-nox --profile=$CONF_DIR2 --webui-port=$USER2_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

echo -e "  [${GREEN}✓${RESET}] Created systemd service qbittorrent-$USER1_NAME.service"
echo -e "  [${GREEN}✓${RESET}] Created systemd service qbittorrent-$USER2_NAME.service"

sudo systemctl daemon-reload
sudo systemctl enable --now "qbittorrent-$USER1_NAME"
sudo systemctl enable --now "qbittorrent-$USER2_NAME"

echo -e "  [${GREEN}✓${RESET}] Enabled and started both services!"

# 5. Cloudflare Tunnel / Worker Guidance
echo -e "\n${BOLD}Step 5: Cloudflare Setup Configuration${RESET}"
read -p "Enter your Cloudflare Domain name (e.g. yourdomain.com) [optional]: " CF_DOMAIN

if [ -n "$CF_DOMAIN" ]; then
    cat <<EOF > cloudflared-ingress-config.yml
# Cloudflare Tunnel Configuration Template
tunnel: YOUR_TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: $USER1_NAME-qb.$CF_DOMAIN
    service: http://localhost:$USER1_PORT
  - hostname: $USER2_NAME-qb.$CF_DOMAIN
    service: http://localhost:$USER2_PORT
  - service: http_status:404
EOF
    echo -e "  [${GREEN}✓${RESET}] Generated 'cloudflared-ingress-config.yml' for $CF_DOMAIN"
fi

echo -e "\n${GREEN}${BOLD}======================================================================${RESET}"
echo -e "${GREEN}${BOLD}                Installation Complete!                                ${RESET}"
echo -e "${GREEN}${BOLD}======================================================================${RESET}"
echo -e "Profile 1 ($USER1_NAME): ${CYAN}http://localhost:$USER1_PORT${RESET} (Default User: admin / Pass: check terminal logs)"
echo -e "Profile 2 ($USER2_NAME): ${CYAN}http://localhost:$USER2_PORT${RESET} (Default User: admin / Pass: check terminal logs)"
echo ""
echo -e "To view service logs:"
echo -e "  ${YELLOW}sudo journalctl -u qbittorrent-$USER1_NAME -n 20${RESET}"
echo -e "  ${YELLOW}sudo journalctl -u qbittorrent-$USER2_NAME -n 20${RESET}"
echo ""
