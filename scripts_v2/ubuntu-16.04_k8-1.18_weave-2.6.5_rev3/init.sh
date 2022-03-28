#!/usr/bin/env bash
set -ex

if [ "$1" == "postcustomization" ]
then
	TMPDIR=${TMPDIR:-'/tmp'}
	echo "Running postcustomization at $(date)" >> ${TMPDIR}/postcust_output.txt
	sed -i -e 's/^PasswordAuthentication yes/PasswordAuthentication no/' \
		-e 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

	apt remove -y cloud-init
	dpkg-reconfigure openssh-server

	\rm -f /.guest-customization-post-reboot-pending || true

	sync
	sync

fi

exit 0
