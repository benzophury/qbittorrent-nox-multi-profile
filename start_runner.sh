#!/usr/bin/env bash
# ==============================================================================
# Streamix-style Quick Tunnel & Cloudflare Worker Auto-Sync Runner
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

WORKER_URL=${WORKER_URL:-""}
SECRET_KEY=${SECRET_KEY:-""}

if [ -z "$WORKER_URL" ]; then
    echo -e "${CYAN}${BOLD}Streamix Quick Tunnel Sync Setup${RESET}"
    read -p "Enter your Cloudflare Worker URL (e.g. https://your-worker.workers.dev): " WORKER_URL
fi

if [ -z "$SECRET_KEY" ]; then
    read -s -p "Enter your Worker SECRET_KEY: " SECRET_KEY
    echo ""
fi

# Clean up existing logs
rm -f /tmp/cf_private.log /tmp/cf_public.log

echo -e "\n${BOLD}Starting Cloudflare Quick Tunnels...${RESET}"

# Launch Private Tunnel (Port 8080)
cloudflared tunnel --url http://localhost:8080 > /tmp/cf_private.log 2>&1 &
PID_PRIVATE=$!

# Launch Public Tunnel (Port 8090)
cloudflared tunnel --url http://localhost:8090 > /tmp/cf_public.log 2>&1 &
PID_PUBLIC=$!

echo -e "  [${CYAN}⏳${RESET}] Waiting for Quick Tunnel URLs to generate..."

URL_PRIVATE=""
URL_PUBLIC=""

# Poll logs for 15 seconds max
for i in {1..15}; do
    if [ -z "$URL_PRIVATE" ] && grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" /tmp/cf_private.log >/dev/null 2>&1; then
        URL_PRIVATE=$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" /tmp/cf_private.log | head -n 1)
    fi
    
    if [ -z "$URL_PUBLIC" ] && grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" /tmp/cf_public.log >/dev/null 2>&1; then
        URL_PUBLIC=$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" /tmp/cf_public.log | head -n 1)
    fi

    if [ -n "$URL_PRIVATE" ] && [ -n "$URL_PUBLIC" ]; then
        break
    fi
    sleep 1
done

if [ -n "$URL_PRIVATE" ]; then
    echo -e "  [${GREEN}✓${RESET}] Private Tunnel: ${CYAN}$URL_PRIVATE${RESET}"
    curl -s "${WORKER_URL}/set?secret=${SECRET_KEY}&user=private&url=${URL_PRIVATE}" >/dev/null
    echo -e "  [${GREEN}✓${RESET}] Synced Private Tunnel to Cloudflare Worker!"
else
    echo -e "  [${RED}✗${RESET}] Failed to obtain Private Quick Tunnel URL."
fi

if [ -n "$URL_PUBLIC" ]; then
    echo -e "  [${GREEN}✓${RESET}] Public Tunnel: ${CYAN}$URL_PUBLIC${RESET}"
    curl -s "${WORKER_URL}/set?secret=${SECRET_KEY}&user=public&url=${URL_PUBLIC}" >/dev/null
    echo -e "  [${GREEN}✓${RESET}] Synced Public Tunnel to Cloudflare Worker!"
else
    echo -e "  [${RED}✗${RESET}] Failed to obtain Public Quick Tunnel URL."
fi

echo -e "\n${GREEN}${BOLD}======================================================================${RESET}"
echo -e "Permanent Worker URLs:"
echo -e "  🔒 Private: ${CYAN}${WORKER_URL}/private${RESET}"
echo -e "  🌐 Public:  ${CYAN}${WORKER_URL}/public${RESET}"
echo -e "${GREEN}${BOLD}======================================================================${RESET}\n"

# Keep script running to maintain tunnels
wait $PID_PRIVATE $PID_PUBLIC
