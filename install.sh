#!/usr/bin/env bash
set -euo pipefail

read -rp "Enter ZeroTier network ID: " NETWORK_ID

read -rp "Enable LAN gaming compatibility fixes? (y/n): " ENABLE_GAMING_FIX
ENABLE_GAMING_FIX=$(echo "$ENABLE_GAMING_FIX" | tr '[:upper:]' '[:lower:]')

sudo tee >/dev/null /etc/yum.repos.d/zerotier.repo <<'EOF'
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=https://download.zerotier.com/redhat/fc/$releasever
enabled=1
gpgcheck=1
gpgkey=https://download.zerotier.com/contact@zerotier.com.gpg
EOF

if ! rpm-ostree status | grep -q zerotier-one; then
  sudo rpm-ostree install zerotier-one  
else
  echo "ZeroTier already installed"
fi

sudo rpm-ostree apply-live

sudo systemctl enable --now zerotier-one.service

echo "Waiting for ZeroTier daemon..."
for i in {1..15}; do
  if sudo zerotier-cli status &>/dev/null; then
    break
  fi
  sleep 2
done

sudo zerotier-cli join "$NETWORK_ID"

echo "Waiting for ZeroTier interface (network must be authorized on ZeroTier Central)..."
ZTIFACE=""
for i in {1..15}; do
  ZTIFACE=$(ip -o link show | awk -F': ' '/zt/{print $2}' | head -n1 || true)
  if [[ -n "$ZTIFACE" ]]; then
    break
  fi
  sleep 2
done

echo "Interface detected: $ZTIFACE"

if [[ "$ENABLE_GAMING_FIX" == "y" ]]; then
  echo "Applying LAN gaming compatibility routes..."
  sudo ip route add 255.255.255.255 dev "$ZTIFACE" 2>/dev/null || true
  sudo ip route add 224.0.0.0/4 dev "$ZTIFACE" 2>/dev/null || true
fi

echo "Done."
