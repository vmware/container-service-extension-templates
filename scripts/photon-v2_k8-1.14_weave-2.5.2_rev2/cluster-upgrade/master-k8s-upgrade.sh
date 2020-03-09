#!/usr/bin/env bash

set -e

echo 'upgrading packages to: kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2'
tdnf install -yq kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done

echo 'upgrading kubeadm to v1.14.6'
# sometimes master will be in 'NotReady' state for a short period
# api server needs to answer 'OK' to `/healthz`
# https://github.com/kubernetes/kubeadm/issues/539
# upgrade needs to go through various checks
# master readiness check is not sufficient: while [ `kubectl get nodes | awk '/master/ {print $2}'` != 'Ready,SchedulingDisabled' ]; do echo 'waiting for master to be ready'; sleep 5; done
sleep 120
kubeadm upgrade apply v1.14.6 -y

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
