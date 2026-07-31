#!/usr/bin/env bash
set -euo pipefail

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


