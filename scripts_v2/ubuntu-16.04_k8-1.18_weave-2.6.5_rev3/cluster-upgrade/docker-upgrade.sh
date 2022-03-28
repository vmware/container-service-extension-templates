#!/usr/bin/env bash

set -e

echo 'upgrading packages to: docker-ce=5:19.03.12~3-0~ubuntu-xenial'
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get install -y --allow-change-held-packages docker-ce=5:19.03.12~3-0~ubuntu-xenial
systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
