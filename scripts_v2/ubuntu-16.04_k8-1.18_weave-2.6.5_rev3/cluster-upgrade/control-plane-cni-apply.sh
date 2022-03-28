#!/usr/bin/env bash

set -e

export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O /root/weave_v2-6-5.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.6.5"
kubectl apply -f /root/weave_v2-6-5.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
