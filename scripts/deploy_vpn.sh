#!/bin/bash
# =============================================================
# deploy_vpn.sh
# Deploys WireGuard config and starts the VPN interface
# Called by GitHub Actions after SSH into the server
# Usage: sudo bash scripts/deploy_vpn.sh
# =============================================================

set -e

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✔]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ── Check root ────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "Must be run as root: sudo bash scripts/deploy_vpn.sh"
fi

# ── Variables (injected from environment / GitHub Secrets) ────
WG_PRIVATE_KEY="${WG_PRIVATE_KEY:-}"
VPN_SERVER_IP="${VPN_SERVER_IP:-10.0.0.1}"
VPN_PORT="${VPN_PORT:-51820}"
CONFIG_DEST="/etc/wireguard/wg0.conf"
INTERFACE="eth0"  # Change to your server's main interface (eth0, ens3, etc.)

# ── Validate required secrets ─────────────────────────────────
if [[ -z "$WG_PRIVATE_KEY" ]]; then
  error "WG_PRIVATE_KEY is not set. Add it as a GitHub Secret."
fi

log "Starting VPN deployment..."

# ── Step 1: Ensure WireGuard is installed ────────────────────
if ! command -v wg &> /dev/null; then
  warn "WireGuard not found. Running install script..."
  bash "$(dirname "$0")/install_wireguard.sh"
fi

# ── Step 2: Stop existing VPN interface (if running) ─────────
log "Stopping existing wg0 interface (if active)..."
if ip link show wg0 &> /dev/null; then
  wg-quick down wg0 2>/dev/null || true
  log "Previous wg0 interface stopped"
else
  log "No existing wg0 interface — fresh deploy"
fi

# ── Step 3: Write WireGuard configuration ────────────────────
log "Writing WireGuard config to $CONFIG_DEST..."

# Detect main network interface automatically
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
log "Detected network interface: $INTERFACE"

cat > "$CONFIG_DEST" << EOF
[Interface]
PrivateKey = ${WG_PRIVATE_KEY}
Address = ${VPN_SERVER_IP}/24
ListenPort = ${VPN_PORT}

PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; \\
           iptables -A FORWARD -o wg0 -j ACCEPT; \\
           iptables -t nat -A POSTROUTING -o ${INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; \\
           iptables -D FORWARD -o wg0 -j ACCEPT; \\
           iptables -t nat -D POSTROUTING -o ${INTERFACE} -j MASQUERADE
EOF

# ── Step 4: Secure the config file ───────────────────────────
log "Securing config file permissions..."
chmod 600 "$CONFIG_DEST"
chown root:root "$CONFIG_DEST"

# ── Step 5: Start WireGuard ───────────────────────────────────
log "Starting WireGuard (wg-quick up wg0)..."
wg-quick up wg0

# ── Step 6: Enable at boot ────────────────────────────────────
log "Enabling WireGuard to start on boot..."
systemctl enable wg-quick@wg0

# ── Step 7: Verify VPN is running ────────────────────────────
log "Verifying VPN interface..."
if ip link show wg0 | grep -q "UP"; then
  log "wg0 interface is UP ✅"
elif ip link show wg0 &> /dev/null; then
  warn "wg0 interface exists but may not be fully UP yet"
else
  error "wg0 interface not found after deployment!"
fi

# ── Step 8: Show VPN status ───────────────────────────────────
echo ""
echo "══════════════════════════════════════"
echo "         VPN Deployment Status        "
echo "══════════════════════════════════════"
wg show wg0 2>/dev/null || warn "Could not retrieve wg show output"
echo "══════════════════════════════════════"
echo ""

log "✅ WireGuard VPN deployed and running!"
echo -e "   Server IP in VPN: ${YELLOW}${VPN_SERVER_IP}${NC}"
echo -e "   Listening on UDP port: ${YELLOW}${VPN_PORT}${NC}"
echo -e "   Interface: ${YELLOW}${INTERFACE}${NC}"
