#!/usr/bin/env bash

# exit script if any command has exit code != 0
set -e

while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done

kubeadm join --token {token} {ip}:6443 --discovery-token-unsafe-skip-ca-verification
