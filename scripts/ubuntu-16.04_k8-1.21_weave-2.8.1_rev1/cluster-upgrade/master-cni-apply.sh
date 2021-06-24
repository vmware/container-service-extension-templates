#!/usr/bin/env bash

set -e

weave_version=2.8.1
versioned_weave_file="/root/weave_v$(echo {weave_version} | sed -r 's/\./\-/g').yml"

export kubever=$(kubectl version --client | base64 | tr -d '\n')
wget --no-verbose -O $versioned_weave_file "https://cloud.weave.works/k8s/net?k8s-version=$kubever&v=$weave_version"
kubectl apply -f $versioned_weave_file
systemctl restart kubelet
while [ `systemctl is-active kubelet` != 'active' ]; do echo 'waiting for kubelet'; sleep 5; done
