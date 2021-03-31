#!/usr/bin/env bash

set -e

# 2/13/2020 Photon's highest docker version (validated by Kubernetes) is 18.09.9-2
# We cannot upgrade to 18.09.9-2 though because upgrading to that version kills all containers
# 18.06.2-6 is the latest safe upgrade to take
echo 'upgrading docker to: docker-18.06.2-6.ph2'
tdnf install -yq docker-18.06.2-6.ph2
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
