#!/usr/bin/env bash

set -e

echo 'upgrading packages to: kubeadm=1.20.6-00'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubeadm=1.20.6-00 kubernetes-cni=0.8.7-00

<<<<<<< HEAD:scripts_v2/ubuntu-16.04_k8-1.16_weave-2.6.0_rev3/cluster-upgrade/control-plane-k8s-upgrade.sh
echo 'upgrading kubeadm to v1.16.13'

=======
echo 'upgrading kubeadm to v1.20.6'
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88:scripts/ubuntu-16.04_k8-1.20_weave-2.6.5_rev1/cluster-upgrade/master-k8s-upgrade.sh
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
# sometimes master will be in 'NotReady' state for a short period
# api server needs to answer 'OK' to `/healthz`
# https://github.com/kubernetes/kubeadm/issues/539
# upgrade needs to go through various checks
# master readiness check is not sufficient: while [ `kubectl get nodes | awk '/master/ {print $2}'` != 'Ready,SchedulingDisabled' ]; do echo 'waiting for master to be ready'; sleep 5; done
sleep 120
<<<<<<< HEAD:scripts_v2/ubuntu-16.04_k8-1.16_weave-2.6.0_rev3/cluster-upgrade/control-plane-k8s-upgrade.sh

kubeadm upgrade apply v1.16.13 -y
=======
kubeadm upgrade apply v1.20.6 -y

echo 'upgrading packages to: kubelet=1.20.6-00 kubectl=1.20.6-00 kubernetes-cni=0.8.7-00'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubelet=1.20.6-00 kubectl=1.20.6-00 kubernetes-cni=0.8.7-00 --allow-unauthenticated
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88:scripts/ubuntu-16.04_k8-1.20_weave-2.6.5_rev1/cluster-upgrade/master-k8s-upgrade.sh

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
