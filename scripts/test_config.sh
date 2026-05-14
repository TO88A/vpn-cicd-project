#!/bin/bash
# =============================================================
# test_config.sh
# Validates WireGuard configuration BEFORE deployment
# Runs in GitHub Actions CI step (no root needed)
# Usage: bash scripts/test_config.sh
# =============================================================

set -e

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✔ PASS]${NC} $1"; }
fail()   { echo -e "${RED}[✘ FAIL]${NC} $1"; FAILED=$((FAILED+1)); }
info()   { echo -e "${BLUE}[ℹ]${NC} $1"; }

FAILED=0
CONFIG_FILE="configs/wg0.conf.example"

echo ""
echo "══════════════════════════════════════════════"
echo "  WireGuard Configuration Validation Tests   "
echo "══════════════════════════════════════════════"
echo ""

# ── Test 1: Config file exists ────────────────────────────────
info "Test 1: Checking config file exists..."
if [[ -f "$CONFIG_FILE" ]]; then
  log "Config file found: $CONFIG_FILE"
else
  fail "Config file not found: $CONFIG_FILE"
fi

# ── Test 2: Required sections present ────────────────────────
info "Test 2: Checking [Interface] section..."
if grep -q "\[Interface\]" "$CONFIG_FILE"; then
  log "[Interface] section present"
else
  fail "[Interface] section missing"
fi

info "Test 3: Checking [Peer] section..."
if grep -q "\[Peer\]" "$CONFIG_FILE"; then
  log "[Peer] section present"
else
  fail "[Peer] section missing"
fi

# ── Test 3: Required fields ───────────────────────────────────
info "Test 4: Checking PrivateKey field..."
if grep -q "PrivateKey" "$CONFIG_FILE"; then
  log "PrivateKey field present"
else
  fail "PrivateKey field missing"
fi

info "Test 5: Checking ListenPort field..."
if grep -q "ListenPort" "$CONFIG_FILE"; then
  PORT=$(grep "ListenPort" "$CONFIG_FILE" | awk '{print $3}')
  if [[ "$PORT" =~ ^[0-9]+$ ]] && [[ "$PORT" -ge 1 ]] && [[ "$PORT" -le 65535 ]]; then
    log "ListenPort is valid: $PORT"
  else
    fail "ListenPort value invalid: $PORT"
  fi
else
  fail "ListenPort field missing"
fi

info "Test 6: Checking Address field (VPN subnet)..."
if grep -q "^Address" "$CONFIG_FILE"; then
  log "Address field present"
else
  fail "Address field missing"
fi

# ── Test 4: No real private keys committed ────────────────────
info "Test 7: Security check — no real keys in repo..."
# Real WireGuard base64 keys are exactly 44 chars
# We check for placeholder text instead
if grep -q "<WG_PRIVATE_KEY_FROM_SECRET>" "$CONFIG_FILE"; then
  log "Security OK — placeholder used, no real key committed"
else
  # Check if it looks like a real base64 key (44 chars)
  if grep -E "PrivateKey\s*=\s*[A-Za-z0-9+/]{43}=" "$CONFIG_FILE" > /dev/null 2>&1; then
    fail "⚠️  REAL PRIVATE KEY detected in config! Remove it before committing."
  else
    log "PrivateKey appears safe (injected via secret)"
  fi
fi

# ── Test 5: Scripts are executable / valid bash ───────────────
info "Test 8: Validating bash scripts syntax..."
SCRIPTS=(scripts/install_wireguard.sh scripts/test_config.sh scripts/deploy_vpn.sh)
for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" ]]; then
    if bash -n "$script" 2>/dev/null; then
      log "Syntax OK: $script"
    else
      fail "Syntax error in: $script"
    fi
  else
    fail "Script not found: $script"
  fi
done

# ── Test 6: GitHub Actions workflow exists ────────────────────
info "Test 9: Checking GitHub Actions workflow file..."
if [[ -f ".github/workflows/deploy-vpn.yml" ]]; then
  log "Workflow file found"
else
  fail "Workflow file missing: .github/workflows/deploy-vpn.yml"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}  ALL TESTS PASSED ✅  — Safe to deploy${NC}"
else
  echo -e "${RED}  $FAILED TEST(S) FAILED ❌  — Fix before deploy${NC}"
fi
echo "══════════════════════════════════════════════"
echo ""

exit $FAILED
