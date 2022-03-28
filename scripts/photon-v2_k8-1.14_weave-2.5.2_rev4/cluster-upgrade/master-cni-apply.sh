#!/usr/bin/env bash

set -e

export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O /root/weave.yml "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=2.5.2"
# Fix the weave image location
sed -i 's/ghcr.io\/weaveworks\/launcher/docker.io\/weaveworks/g' /root/weave.yml
kubectl apply -f /root/weave.yml
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
