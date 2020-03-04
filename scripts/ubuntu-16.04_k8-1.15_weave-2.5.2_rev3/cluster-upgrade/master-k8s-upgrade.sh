#!/usr/bin/env bash

set -e

echo 'upgrading packages to: kubelet=1.15.9-00 kubeadm=1.15.9-00 kubectl=1.15.9-00 kubernetes-cni=0.7.5-00'
apt-mark unhold kubeadm kubelet kubectl kubernetes-cni
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -q install -y kubelet=1.15.9-00 kubeadm=1.15.9-00 kubectl=1.15.9-00 kubernetes-cni=0.7.5-00
apt-mark hold kubeadm kubelet kubectl kubernetes-cni

echo 'upgrading kubeadm to v1.15.9'
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
# sometimes master will be in 'NotReady' state for a short period
# api server needs to answer 'OK' to `/healthz`
# https://github.com/kubernetes/kubeadm/issues/539
# upgrade needs to go through various checks
# master readiness check is not sufficient: while [ `kubectl get nodes | awk '/master/ {print $2}'` != 'Ready,SchedulingDisabled' ]; do echo 'waiting for master to be ready'; sleep 5; done
sleep 120
kubeadm upgrade apply v1.15.9 -y

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
