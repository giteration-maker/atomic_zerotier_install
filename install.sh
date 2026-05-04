#!/usr/bin/env bash
set -euo pipefail

read -rp "Enter ZeroTier network ID: " NETWORK_ID
read -rp "Enable LAN gaming compatibility fixes? (y/n): " ENABLE_GAMING_FIX
ENABLE_GAMING_FIX=$(echo "$ENABLE_GAMING_FIX" | tr '[:upper:]' '[:lower:]')

sudo tee /etc/yum.repos.d/zerotier.repo >/dev/null <<'EOF'
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

if ! sudo zerotier-cli status &>/dev/null; then
  echo "Error: ZeroTier daemon did not start in time."
  exit 1
fi

while true; do
  if sudo zerotier-cli join "$NETWORK_ID"; then
    echo "Joined network $NETWORK_ID successfully"
    break
  else
    echo "Error: Failed to join network $NETWORK_ID"
    read -rp "Enter ZeroTier network ID: " NETWORK_ID
  fi
done

echo "Go to ZeroTier Central (https://my.zerotier.com/) and authorize this device."

if [[ "$ENABLE_GAMING_FIX" == "y" ]]; then
  echo "Waiting for ZeroTier interface..."
  ZTIFACE=""
  for i in {1..40}; do
    ZTIFACE=$(ip -o link show | awk -F': ' '/zt/{print $2}' | head -n1 || true)
    if [[ -n "$ZTIFACE" ]]; then
      break
    fi
    sleep 3
  done

  if [[ -z "$ZTIFACE" ]]; then
    echo "Warning: ZeroTier interface not detected. Authorize the device at https://my.zerotier.com"
    echo "Then run manually:"
    echo "  sudo ip route add 255.255.255.255 dev <ztXXXXXX>"
    echo "  sudo ip route add 224.0.0.0/4 dev <ztXXXXXX>"
    exit 0
  fi

  echo "Applying LAN gaming compatibility routes on $ZTIFACE..."
  sudo ip route add 255.255.255.255 dev "$ZTIFACE" 2>/dev/null || true
  sudo ip route add 224.0.0.0/4 dev "$ZTIFACE" 2>/dev/null || true
fi

echo "Done."
