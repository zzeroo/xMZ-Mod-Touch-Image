#!/bin/bash
# Dieses Script erzeugt ein Basis nspawn Container mit qemu-arm Unterstützung.
# Am Ende dieses Scripts wird ein btrfs Snapshot dieses Containers erzeugt.
#
# Exit on error or variable unset
set -o errexit -o nounset

EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.5.0"-$(git rev-parse --short HEAD)

# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"
# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:


prepare_container(){
	debug "Erzeuge btrfs subvolumen, davon kann dann ein Snapshot erzeugt werden ..."
	run "sudo [ -d ${CONTAINER_DIR} ] || sudo mkdir -p ${CONTAINER_DIR}"
	run "sudo btrfs subvolume create ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}"
}

prepare_system() {
	debug "Bereite Development System vor ..."
	run "sudo apt-get install -y debootstrap"
}

# FIXME use an if for qemu-arm-static and an elseif for qemu-arm
add_qemu() {
  debug "Richte qemu Support ein..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/usr/bin"
  if [[ -f /usr/bin/qemu-arm-static ]] || [[ -f /usr/bin/qemu-arm ]]; then
    run "sudo bash -c \"cp /usr/bin/qemu-arm-static ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/usr/bin/qemu-arm-static\""
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
  debug "Dbootstrapping ${DISTRIBUTION} to ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} ..."
	run "# sudo debootstrap --variant=minbase --arch=${ARCH} ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/"
	run "sudo debootstrap --arch=${ARCH} ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/"
}

set_passwd_in_container(){
  debug "Root Password in Template Container setzen ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"echo -e \\\"${ROOT_PASSWORD}\n${ROOT_PASSWORD}\\\" | passwd\""
}



# Main part of the script
prepare_container

prepare_system

add_qemu

debootstrap_container

set_passwd_in_container

_GENERIC_create_btrfs_snapshot
