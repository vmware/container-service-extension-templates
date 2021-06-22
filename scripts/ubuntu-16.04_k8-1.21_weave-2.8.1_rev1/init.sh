#!/usr/bin/env bash
set -e

sed -i -e 's/^PasswordAuthentication yes/PasswordAuthentication no/' -e 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

apt remove -y cloud-init
dpkg-reconfigure openssh-server
sync
sync
