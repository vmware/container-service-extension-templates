#!/usr/bin/env bash
set -e
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
kubeadm init \
  --image-repository=projects.registry.vmware.com/tkg \
  --ignore-preflight-errors=ImagePull \
  --pod-network-cidr={pod_network_cidr} \
  --service-cidr={service_cidr} \
  --kubernetes-version=1.20.4-vmware.1 \
  > /root/kubeadm-init.out
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

export kubever=$(kubectl version --client | base64 | tr -d '\n')
kubectl apply -f /root/antrea_0.11.3.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
