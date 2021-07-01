#!/usr/bin/env bash
set -e
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
<<<<<<< HEAD

kubeadm init --kubernetes-version=v1.20.6 > /root/kubeadm-init.out

=======
kubeadm init --kubernetes-version=v1.20.6 > /root/kubeadm-init.out
>>>>>>> e1288f332fab5f500e044cf1a2c074848852cc88
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

export kubever=$(kubectl version --client | base64 | tr -d '\n')
kubectl apply -f /root/weave_v2-6-5.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
