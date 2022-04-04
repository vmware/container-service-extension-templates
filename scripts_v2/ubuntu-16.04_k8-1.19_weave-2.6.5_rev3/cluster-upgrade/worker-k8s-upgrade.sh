#!/usr/bin/env bash

set -e

echo 'upgrading packages to: kubeadm=1.19.3-00'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubeadm=1.19.3-00 kubernetes-cni=0.8.7-00
echo 'upgrading kubeadm in worker node'
kubeadm upgrade node

echo 'upgrading packages to: kubelet=1.19.3-00 kubectl=1.19.3-00 kubernetes-cni=0.8.7-00'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages kubelet=1.19.3-00 kubectl=1.19.3-00 kubernetes-cni=0.8.7-00
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
