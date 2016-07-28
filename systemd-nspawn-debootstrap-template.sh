#!/bin/bash

set -e

export DEBIAN_VERSION=stretch
export ARCH=armhf
export SUFFIX=template
export PATHNAME=${DEBIAN_VERSION}_${ARCH}-${SUFFIX}

sudo btrfs subvolume create /var/lib/container/${PATHNAME}
sudo mkdir -p /var/lib/container/${PATHNAME}/usr/bin
sudo cp /usr/bin/qemu-arm-static /var/lib/container/${PATHNAME}/usr/bin
sudo debootstrap --arch=${ARCH} ${DEBIAN_VERSION} /var/lib/container/${PATHNAME} http://ftp.uk.debian.org/debian/
