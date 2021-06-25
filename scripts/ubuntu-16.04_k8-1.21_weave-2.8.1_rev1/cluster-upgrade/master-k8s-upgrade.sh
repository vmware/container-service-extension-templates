#!/usr/bin/env bash

set -e

kubernetes_version=v1.21.2
kubernetes_tools_version=1.21.2-00
kubernetes_cni_version=0.8.7-00

echo "upgrading packages to: kubeadm=$kubernetes_tools_version"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubeadm=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version

echo "upgrading kubeadm to $kubernetes_version"
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
# sometimes master will be in 'NotReady' state for a short period
# api server needs to answer 'OK' to `/healthz`
# https://github.com/kubernetes/kubeadm/issues/539
# upgrade needs to go through various checks
# master readiness check is not sufficient: while [ `kubectl get nodes | awk '/master/ {print $2}'` != 'Ready,SchedulingDisabled' ]; do echo 'waiting for master to be ready'; sleep 5; done
sleep 120
kubeadm upgrade apply $kubernetes_version -y

echo "upgrading packages to: kubelet=$kubernetes_tools_version kubectl=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubelet=$kubernetes_tools_version kubectl=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version --allow-unauthenticated

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
