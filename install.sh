#!/bin/bash

curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier

cat << 'EOF' | sudo tee /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=http://download.zerotier.com/redhat/fc/$releasever
enabled=1
gpgcheck=1
EOF

rpm-ostree install zerotier-one
sudo rpm-ostree ex apply-live

sudo systemctl enable --now zerotier-one.service
