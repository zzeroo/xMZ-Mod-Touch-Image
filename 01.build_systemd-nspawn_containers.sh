#!/bin/bash
# Dieses Script erzeugt ein Basis nspawn Container mit qemu-arm Unterstützung.
# Am Ende dieses Scripts wird ein btrfs Snapshot dieses Containers erzeugt,
# in diesem Snapshot werden dann alle weiteren Änderungen vorgenommen.
# So ist es zum Möglich das schon bestehende Image Verzeichnis mit
# den Debian Tools `apt-get update && apt-get dist-upgrade` auf den neuesten
# Stand zu bingen, ohne immer wieder mit `debootstrap` von Vorn anzufangen.
#
# Exit on error or variable unset
set -o errexit -o nounset
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.3.0


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"



prepare_system() {
	debug "Bereite Development System vor ..."
	run "sudo apt-get install -y debootstrap"
}

# FIXME use an if for qemu-arm-static and an elseif for qemu-arm
add_qemu() {
  debug "Richte qemu Support ein..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin"
  if [[ -f /usr/bin/qemu-arm-static ]] || [[ -f /usr/bin/qemu-arm ]]; then
    run "sudo bash -c \"cp /usr/bin/qemu-arm-static ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin/qemu-arm-static\""
  else
    print_quemu_setup
    # If we're not on simulate mode exit here.
    [[ ! x"${SIMULATE}" = "xtrue" ]] && exit
  fi
}

# Hilfsfunktion die die Quemu Installation erklärt.
print_quemu_setup() {
  debug "Qemu Installation ausgeben ..."
  run "# Fehler: qemu, static linked nicht gefunden!"
  run "# Installiere via apt:"
  run "# sudo apt-get install -y qemu-user-static binfmt-support"
  run "#"
	run "# Oder builde aus den Quellen (EMPFOHLEN):"
  run "# apt-get install build-essential pkg-config zlib1g-dev libglib2.0-dev autoconf libtool binfmt-support"
  run "# git clone git://git.qemu-project.org/qemu.git"
  run "# cd qemu"
	run "# git submodule update --init pixman"
  run "# mkdir build"
  run "# cd build"
  run "# ../configure --static --target-list=\"x86_64-linux-user arm-linux-user armeb-linux-user\"  --prefix=/usr"
  run "# make -j$(nproc)"
  run "# sudo make install"
  run "# sudo cp /usr/bin/qemu-arm /usr/bin/qemu-arm-static"
}

debootstrap_container(){
  debug "Dbootstrapping ${DISTRIBUTION} to ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template ..."
	run "# sudo debootstrap --variant=minbase --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/"
	run "sudo debootstrap --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/"
}

set_passwd_in_container(){
  debug "Root Password in Template Container setzen ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template /bin/bash -c \"echo -e \\\"${ROOT_PASSWORD}\n${ROOT_PASSWORD}\\\" | passwd\""
}

create_btrfs_snapshot() {
	debug "Erzeuge ein btrfs Snapshot von ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template nach ${CONTAINER_DIR}/${DISTRIBUTION}_armhf..."
	run "sudo btrfs subvolume create ${CONTAINER_DIR}/${DISTRIBUTION}_armhf"
	run "sudo cp --reflink=always -aR ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/* ${CONTAINER_DIR}/${DISTRIBUTION}_armhf"
}


# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:

prepare_system

add_qemu

debootstrap_container

set_passwd_in_container

create_btrfs_snapshot
