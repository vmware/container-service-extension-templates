#!/usr/bin/env bash

set -e

cat << EOF > /etc/systemd/system/iptables-ports.service
[Unit]
After=iptables.service
Requires=iptables.service
[Service]
Type=oneshot
ExecStartPre=/usr/sbin/iptables -P INPUT ACCEPT
ExecStartPre=/usr/sbin/iptables -P OUTPUT ACCEPT
ExecStart=/usr/sbin/iptables -P FORWARD ACCEPT
TimeoutSec=0
RemainAfterExit=yes
[Install]
WantedBy=iptables.service
EOF

chmod 0644 /etc/systemd/system/iptables-ports.service
systemctl enable iptables-ports.service
systemctl start iptables-ports.service

# update repo info (needed for docker update)
tdnf makecache -q
tdnf update tdnf -y

echo 'installing kubernetes'
tdnf install -yq wget kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2

echo 'installing docker'
tdnf install -yq docker-18.06.2-6.ph2
systemctl enable docker
systemctl start docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

echo 'installing NFS software'
tdnf -y install nfs-utils
systemctl stop nfs-server.service
systemctl disable nfs-server.service

echo 'upgrading security packages'
tdnf update tdnf -y
# this update needs to be the last step due to required reboot after kernel update (https://bbs.archlinux.org/viewtopic.php?id=203966)
# tdnf should be improved to handle dependent package exclusion better. refer to jira PHO-548
tdnf update --security --exclude "open-vm-tools,xerces-c,procps-ng,docker" -y

# /etc/machine-id must be empty so that new machine-id gets assigned on boot (in our case boot is vApp deployment)
echo -n > /etc/machine-id
sync
sync
echo 'customization completed'
