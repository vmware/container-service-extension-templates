#!/usr/bin/env bash

set -e

docker_ce_version=5:20.10.7~3-0~ubuntu-xenial

echo "upgrading packages to: docker-ce=$docker_ce_version"
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages docker-ce=$docker_ce_version
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
