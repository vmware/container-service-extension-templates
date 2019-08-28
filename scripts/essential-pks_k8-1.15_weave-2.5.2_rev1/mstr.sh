#!/usr/bin/env bash

# exit script if any command has exit code != 0
set -e

while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

kubeadm init --image-repository "localhost:5000" --kubernetes-version "1.15.3" > /root/kubeadm-init.out
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config
kubectl apply -f /root/weave.yml
