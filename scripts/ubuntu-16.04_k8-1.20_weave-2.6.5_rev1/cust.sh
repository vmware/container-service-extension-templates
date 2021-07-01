#!/usr/bin/env bash

set -e

# disable ipv6 to avoid possible connection errors
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sudo sysctl -p

echo 'nameserver 8.8.8.8' >> /etc/resolvconf/resolv.conf.d/tail
resolvconf -u

systemctl restart networking.service
while [ `systemctl is-active networking` != 'active' ]; do echo 'waiting for network'; sleep 5; done

growpart /dev/sda 1 || :
resize2fs /dev/sda1 || :

# redundancy: https://github.com/vmware/container-service-extension/issues/432
systemctl restart networking.service
while [ `systemctl is-active networking` != 'active' ]; do echo 'waiting for network'; sleep 5; done

echo 'installing kubernetes'
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
<<<<<<< HEAD
apt-get -q install -y docker-ce=5:19.03.15~3-0~ubuntu-xenial
apt-get -q install -y kubelet=1.20.6-00 kubeadm=1.20.6-00 kubectl=1.20.6-00 kubernetes-cni=0.8.7-00

=======
<<<<<<< HEAD:scripts_v2/ubuntu-16.04_k8-1.16_weave-2.6.0_rev3/cust.sh
apt-get -q install -y docker-ce=5:18.09.7~3-0~ubuntu-xenial
apt-get -q install -y kubelet=1.16.13-00 kubeadm=1.16.13-00 kubectl=1.16.13-00 kubernetes-cni=0.8.6-00

=======
apt-get -q install -y docker-ce=5:19.03.15~3-0~ubuntu-xenial
apt-get -q install -y kubelet=1.20.6-00 kubeadm=1.20.6-00 kubectl=1.20.6-00 kubernetes-cni=0.8.7-00
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88:scripts/ubuntu-16.04_k8-1.20_weave-2.6.5_rev1/cust.sh
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

echo 'installing required software for NFS'
apt-get -q install -y nfs-common nfs-kernel-server
systemctl stop nfs-kernel-server.service
systemctl disable nfs-kernel-server.service

# prevent updates to software that CSE depends on
apt-mark hold open-vm-tools
apt-mark hold docker-ce
apt-mark hold kubelet
apt-mark hold kubeadm
apt-mark hold kubectl
apt-mark hold kubernetes-cni
apt-mark hold nfs-common
apt-mark hold nfs-kernel-server

echo 'upgrading the system'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

<<<<<<< HEAD
# Download weave.yml to /root/weave_v2-6-5.yml
=======
<<<<<<< HEAD:scripts_v2/ubuntu-16.04_k8-1.16_weave-2.6.0_rev3/cust.sh
# Download weave.yml to /root/weave_v2-6-0.yml
=======
# Download weave.yml to /root/weave_v2-6-5.yml
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88:scripts/ubuntu-16.04_k8-1.20_weave-2.6.5_rev1/cust.sh
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88
export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O /root/weave_v2-6-5.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.6.5"

# /etc/machine-id must be empty so that new machine-id gets assigned on boot (in our case boot is vApp deployment)
# https://jaylacroix.com/fixing-ubuntu-18-04-virtual-machines-that-fight-over-the-same-ip-address/
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id || :
ln -fs /etc/machine-id /var/lib/dbus/machine-id || : # dbus/machine-id is symlink pointing to /etc/machine-id

sync
sync
echo 'customization completed'
