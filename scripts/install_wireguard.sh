#!/bin/bash
# =============================================================
# install_wireguard.sh
# Installs WireGuard on Ubuntu 20.04+ server
# Usage: sudo bash scripts/install_wireguard.sh
# =============================================================

set -e  # Exit immediately on error

# ── Colors for output ─────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ── Check root ────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root. Use: sudo bash $0"
fi

# ── Check Ubuntu ──────────────────────────────────────────────
if ! grep -qi ubuntu /etc/os-release; then
  warn "This script is designed for Ubuntu. Proceeding anyway..."
fi

log "Starting WireGuard installation..."

# ── Step 1: Update packages ───────────────────────────────────
log "Updating package list..."
apt-get update -qq

# ── Step 2: Install WireGuard ─────────────────────────────────
log "Installing WireGuard..."
apt-get install -y wireguard wireguard-tools

# ── Step 3: Enable IP forwarding ──────────────────────────────
log "Enabling IP forwarding..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p > /dev/null

# ── Step 4: Create WireGuard config directory ─────────────────
log "Setting up /etc/wireguard directory..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# ── Step 5: Verify installation ───────────────────────────────
if command -v wg &> /dev/null; then
  WG_VERSION=$(wg --version 2>&1 | head -n1)
  log "WireGuard installed successfully: $WG_VERSION"
else
  error "WireGuard installation failed!"
fi

# ── Step 6: Enable WireGuard service at boot ──────────────────
log "Enabling wg-quick@wg0 service at boot..."
systemctl enable wg-quick@wg0 2>/dev/null || warn "Service not enabled (config not yet deployed)"

echo ""
log "✅ WireGuard installation complete!"
echo -e "   Next step: run ${YELLOW}bash scripts/deploy_vpn.sh${NC} to configure and start the VPN."
