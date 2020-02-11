#!/usr/bin/env bash

set -e

echo 'upgrading packages to: kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2'
tdnf install -yq kubernetes-1.14.6-3.ph2 kubernetes-kubeadm-1.14.6-3.ph2

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done

echo 'upgrading kubeadm in worker node'
kubeadm upgrade node config --kubelet-version v1.14.6

systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
