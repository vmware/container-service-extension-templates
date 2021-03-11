#!/usr/bin/env bash

set -e

export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O /root/weave_v2-5-2.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.5.2"
kubectl apply -f /root/weave_v2-5-2.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
