#!/usr/bin/env bash
set -e

kubernetes_version=v1.21.2
weave_version=2.8.1

versioned_weave_file="/root/weave_v$(echo {weave_version} | sed -r 's/\./\-/g').yml"

while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
kubeadm init --kubernetes-version=$kubernetes_version > /root/kubeadm-init.out
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

export kubever=$(kubectl version --client | base64 | tr -d '\n')
kubectl apply -f $versioned_weave_file
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
