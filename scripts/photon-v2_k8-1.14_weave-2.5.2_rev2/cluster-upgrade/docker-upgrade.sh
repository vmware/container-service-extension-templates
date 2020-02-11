#!/usr/bin/env bash

set -e

echo 'upgrading packages to: docker-18.06.2-3.ph2'
tdnf install -yq docker-18.06.2-3.ph2
systemctl enable docker
systemctl start docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
