#!/bin/bash

# Add ZeroTier GPG key
curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier

# Add ZeroTier repository
cat << 'EOF' | sudo tee /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=http://download.zerotier.com/redhat/fc/$releasever
enabled=1
gpgcheck=1
EOF

# Install ZeroTier
rpm-ostree install zerotier-one

# Apply changes live without requering reboot
sudo rpm-ostree ex apply-live

# Enable and start ZeroTier service
sudo systemctl enable --now zerotier-one.service
