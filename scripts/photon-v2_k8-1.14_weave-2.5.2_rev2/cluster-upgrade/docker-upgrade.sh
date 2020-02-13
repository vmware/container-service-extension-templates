#!/usr/bin/env bash

set -e

echo 'upgrading docker to: docker-18.09.9-2.ph2'
tdnf install -yq docker-18.09.9-2.ph2
systemctl enable docker
systemctl start docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
