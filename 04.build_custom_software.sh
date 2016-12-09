#!/bin/bash
# In diesem Script sind alle Tasks zusammengefsst die den eigenen Software Stack bilden.
#
# Exit on error or variable unset
set -o errexit -o nounset

# Variablen

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.2.0"-$(git rev-parse --short HEAD)


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"
# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:

# Funktionen
checkout_meta_repo() {
  debug "Git Meta Repo auschecken ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"git clone https://github.com/Kliemann-Service-GmbH/xMZ-Mod-Touch-Software.git\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"cd xMZ-Mod-Touch-Software && git submodule init\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"cd xMZ-Mod-Touch-Software && git submodule update\""
}

# FIXME: Failed in Qemu Umgebung
build_xmz_server() {
  debug "Git Meta Repo auschecken ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"source .cargo/env && cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-Server && cargo build --release\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-Server && cp -v ./target/release/xmz-server-bin /usr/bin/xmz-server\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-Server && cp -rv ./target/release/build/libmodbus-sys-*/out/lib/* /usr/lib/\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-Server && cat <<EOF >/etc/systemd/system/xmz-mod-touch-server.service
#
# xMZ-Mod-Touch-Server systemd unit file
#
[Unit]
Description=\\\"Server Process der 'xMZ-Mod-Touch'-Platform\\\"
After=multi-user.target

[Service]
ExecStart=/usr/bin/xmz-server &

[Install]
Alias=xmz-server.service
WantedBy=multi-user.target
EOF\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"systemctl enable xmz-mod-touch-server.service\""
}

install_vim() {
  debug "Install vim ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"apt-get install -y vim-scripts\""
}



# Main part of the script
checkout_meta_repo

#build_xmz_server

install_vim

_GENERIC_create_btrfs_snapshot
