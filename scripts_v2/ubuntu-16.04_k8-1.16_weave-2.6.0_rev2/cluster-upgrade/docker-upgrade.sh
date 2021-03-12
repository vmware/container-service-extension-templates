#!/usr/bin/env bash

set -e

echo 'upgrading packages to: docker-ce=5:18.09.7~3-0~ubuntu-xenial'
apt-mark unhold docker-ce
apt-get -q update -o Acquire::Retries=3 -o Acquire::http::No-Cache=True -o Acquire::http::Timeout=30 -o Acquire::https::No-Cache=True -o Acquire::https::Timeout=30 -o Acquire::ftp::Timeout=30
apt-get -q install -y docker-ce=5:18.09.7~3-0~ubuntu-xenial
apt-mark hold docker-ce

systemctl restart docker
while [ `systemctl is-active docker` != 'active' ]; do echo 'waiting for docker'; sleep 5; done
