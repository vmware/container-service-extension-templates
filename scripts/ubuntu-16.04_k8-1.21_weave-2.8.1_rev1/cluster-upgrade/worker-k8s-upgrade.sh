#!/usr/bin/env bash

set -e

kubernetes_tools_version=1.21.2-00
kubernetes_cni_version=0.8.7-00

echo "upgrading packages to: kubeadm=$kubernetes_tools_version"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubeadm=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version
echo "upgrading kubeadm in worker node"
kubeadm upgrade node

echo "upgrading packages to: kubelet=$kubernetes_tools_version kubectl=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubelet=$kubernetes_tools_version kubectl=$kubernetes_tools_version kubernetes-cni=$kubernetes_cni_version
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
