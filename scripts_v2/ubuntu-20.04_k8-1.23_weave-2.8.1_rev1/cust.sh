#!/usr/bin/env bash

set -e

# disable ipv6 to avoid possible connection errors
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sudo sysctl -p

# setup resolvconf for ubuntu 20
sudo echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
apt update
apt install resolvconf
systemctl restart resolvconf.service
while [ `systemctl is-active resolvconf` != 'active' ]; do echo 'waiting for resolvconf'; sleep 5; done
echo 'nameserver 8.8.8.8' >> /etc/resolvconf/resolv.conf.d/head
resolvconf -u

#systemctl restart networking.service
systemctl restart systemd-networkd.service
while [ `systemctl is-active systemd-networkd` != 'active' ]; do echo 'waiting for network'; sleep 5; done

growpart /dev/sda 1 || :
resize2fs /dev/sda1 || :

# redundancy: https://github.com/vmware/container-service-extension/issues/432
systemctl restart systemd-networkd.service
while [ `systemctl is-active systemd-networkd` != 'active' ]; do echo 'waiting for network'; sleep 5; done

echo 'installing kubernetes'

docker_ce_version=5:20.10.12~3-0~ubuntu-focal
containerd_version=1.4.12-1
kubernetes_tools_version=1.23.3-00
kubernetes_cni_version=0.8.7-00
weave_version=2.8.1
versioned_weave_file="/root/weave_v$(echo $weave_version | sed -r 's/\./\-/g').yml"
export DEBIAN_FRONTEND=noninteractive

apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -q install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -q install -y docker-ce=$docker_ce_version docker-ce-cli=$docker_ce_version containerd.io=$containerd_version
apt-get -q install -y kubelet=$kubernetes_tools_version kubeadm=$kubernetes_tools_version kubectl=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version

# https://github.com/kubernetes/kubeadm/issues/1893
# this is required if using dockershim as the cri-socket; we're switching to use containerd
# cat <<EOF > /etc/docker/daemon.json
# {
#     "exec-opts": ["native.cgroupdriver=systemd"]
# }
# EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

# use containerd as CRI runtime
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Use systemd cgroup driver
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
sed '/containerd.runtimes.runc.options/a \            SystemdCgroup = true' /etc/containerd/config.toml > /etc/containerd/config.toml
systemctl restart containerd
while [ `systemctl is-active containerd` != 'active' ]; do echo 'waiting for containerd'; sleep 5; done

# Kubeadm uses default CRI, which is dockershim currently
# Change default CRI endpoint to containerd (recommended by crictl)
# crictl config --set runtime-endpoint=/run/containerd/containerd.sock

echo 'installing required software for NFS'
apt-get -q install -y nfs-common nfs-kernel-server
systemctl stop nfs-kernel-server.service
systemctl disable nfs-kernel-server.service

# prevent updates to software that CSE depends on
apt-mark hold open-vm-tools
apt-mark hold docker
apt-mark hold docker-ce
apt-mark hold docker-ce-cli
apt-mark hold containerd.io
apt-mark hold kubelet
apt-mark hold kubeadm
apt-mark hold kubectl
apt-mark hold kubernetes-cni
apt-mark hold nfs-common
apt-mark hold nfs-kernel-server
apt-mark hold shim-signed

echo 'upgrading the system'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

# Download weave.yml to /root/weave_v2-8-1.yml
export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O $versioned_weave_file "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=$weave_version"

# /etc/machine-id must be empty so that new machine-id gets assigned on boot (in our case boot is vApp deployment)
# https://jaylacroix.com/fixing-ubuntu-18-04-virtual-machines-that-fight-over-the-same-ip-address/
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id || :
ln -fs /etc/machine-id /var/lib/dbus/machine-id || : # dbus/machine-id is symlink pointing to /etc/machine-id

sync
sync
echo 'customization completed'
