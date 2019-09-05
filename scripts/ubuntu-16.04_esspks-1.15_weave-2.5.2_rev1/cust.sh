#!/usr/bin/env bash

# exit script if any command has exit code != 0
set -e

# set up basic networking
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'nameserver 8.8.8.8' >> /etc/resolvconf/resolv.conf.d/tail
resolvconf -u
systemctl restart networking.service
while [ `systemctl is-active networking` != 'active' ]; do echo 'waiting for network'; sleep 5; done

# if first commands fail, '|| :' ensures that the exit code is 0
growpart /dev/sda 1 || :
resize2fs /dev/sda1 || :

echo 'installing docker'
export DEBIAN_FRONTEND=noninteractive
apt-get -q update
apt-get -q install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -q update
apt-get -q install -y docker-ce=5:18.09.7~3-0~ubuntu-xenial
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

# download Essential-PKS Kubernetes components and install them
wget https://downloads.heptio.com/essential-pks/523a448aa3e9a0ef93ff892dceefee0a/vmware-kubernetes-v1.15.3%2Bvmware.1.tar.gz
tar xvzf vmware-kubernetes-v1.15.3+vmware.1.tar.gz
dpkg -i vmware-kubernetes-v1.15.3+vmware.1/debs/*.deb || :
sudo apt-get -f install -y

# set up local container image repository
docker run -d -p 5000:5000 --restart=always --name registry registry:2

docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/kube-proxy-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/kube-controller-manager-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/kube-apiserver-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/kube-scheduler-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/pause-3.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/cloud-controller-manager-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/kubernetes-v1.15.3+vmware.1/images/e2e-test-v1.15.3_vmware.1.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/etcd-v3.3.10+vmware.4/images/etcd-v3.3.10_vmware.4.tar.gz
docker load < ./vmware-kubernetes-v1.15.3+vmware.1/coredns-v1.3.1+vmware.4/images/coredns-v1.3.1_vmware.4.tar.gz

docker tag vmware/kube-proxy:v1.15.3_vmware.1 localhost:5000/kube-proxy:v1.15.3
docker tag vmware/kube-apiserver:v1.15.3_vmware.1 localhost:5000/kube-apiserver:v1.15.3
docker tag vmware/kube-controller-manager:v1.15.3_vmware.1 localhost:5000/kube-controller-manager:v1.15.3
docker tag vmware/kube-scheduler:v1.15.3_vmware.1 localhost:5000/kube-scheduler:v1.15.3
docker tag vmware/coredns:v1.3.1_vmware.4  localhost:5000/coredns:1.3.1
docker tag vmware/etcd:v3.3.10_vmware.4 localhost:5000/etcd:3.3.10
docker tag vmware/pause:3.1 localhost:5000/pause:3.1
docker tag vmware/cloud-controller-manager:v1.15.3_vmware.1 localhost:5000/cloud-controller-manager:v1.15.3
docker tag vmware/e2e-test:v1.15.3_vmware.1 localhost:5000/e2e-test:v1.15.3

docker push localhost:5000/pause:3.1
docker push localhost:5000/e2e-test:v1.15.3
docker push localhost:5000/kube-scheduler:v1.15.3
docker push localhost:5000/kube-proxy:v1.15.3
docker push localhost:5000/kube-controller-manager:v1.15.3
docker push localhost:5000/cloud-controller-manager:v1.15.3
docker push localhost:5000/kube-apiserver:v1.15.3
docker push localhost:5000/coredns:1.3.1
docker push localhost:5000/etcd:3.3.10

# download weave.yml
export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O weave.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.5.2"

# install weave net https://www.weave.works/docs/net/latest/install/installing-weave/
curl -L git.io/weave -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave

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
apt-get update
apt-get -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

echo 'deleting downloaded files'
rm -rf vmware-kubernetes-v1.15.3+vmware.1 || :
rm vmware-kubernetes-v1.15.3+vmware.1.tar.gz || :

# /etc/machine-id must be empty so that new machine-id gets assigned on boot (in our case boot is vApp deployment)
# https://jaylacroix.com/fixing-ubuntu-18-04-virtual-machines-that-fight-over-the-same-ip-address/
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id || :
ln -fs /etc/machine-id /var/lib/dbus/machine-id || : # dbus/machine-id is symlink pointing to /etc/machine-id

sync
sync
echo 'customization completed'
