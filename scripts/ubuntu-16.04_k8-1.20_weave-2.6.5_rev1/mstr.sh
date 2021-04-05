#!/usr/bin/env bash
set -e
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
kubeadm init --kubernetes-version=v1.20.5 > /root/kubeadm-init.out
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O /root/weave.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.6.5"
kubectl apply -f /root/weave.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
