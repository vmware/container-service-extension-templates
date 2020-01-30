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

echo 'upgrading the system'
tdnf update tdnf -y
# tdnf should be improved to handle this better. refer to jira PHO-548
tdnf update --security --exclude "open-vm-tools,xerces-c,procps-ng"

echo 'installing kubernetes'
tdnf install -yq wget kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2

echo 'install docker'
tdnf install -yq wget docker-18.06.2-3.ph2
systemctl enable docker
systemctl start docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

echo 'installing required software for NFS'
tdnf -y install nfs-utils
systemctl stop nfs-server.service
systemctl disable nfs-server.service

# /etc/machine-id must be empty so that new machine-id gets assigned on boot (in our case boot is vApp deployment)
echo -n > /etc/machine-id
sync
sync
echo 'customization completed'
