#!/bin/bash
#
# This script creates a systemd-nspawn template.
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1


# include generic functions (echo_b(), and debug() and so on)
source ./lib/generic_functions.sh


add_qemu() {
  debug "Add qemu support ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin"
  if [[ -f /usr/bin/qemu-arm ]]; then
    run "sudo cp /usr/bin/qemu-arm ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin/qemu-arm-static"
  else
    print_quemu_setup
    # If we're not on simulate mode exit here.
    [[ ! x"${SIMULATE}" = "xtrue" ]] && exit
  fi
}

print_quemu_setup() {
  debug "Print qemu setup ..."
  run "# Error: qemu, static linked missing!"
  run "# These commands are needed to setup qemu on the developer maschine."
  run "# apt-get install build-essential pkg-config zlib1g-dev libglib2.0-dev autoconf libtool"
  run "# git submodule update --init pixman"
  run "# git clone git://git.qemu-project.org/qemu.git"
  run "# cd qemu"
  run "# mkdir build"
  run "# cd build"
  run "# ../configure --static --target-list=\"x86_64-linux-user arm-linux-user armeb-linux-user\"  --prefix=/usr"
  run "# make -j9"
  run "# sudo make install"
}

debootstrap_container(){
  debug "Bootstrapping ${DISTRIBUTION} to ${CONTAINER_DIR} ..."
  run "sudo debootstrap --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/"
}

create_development_container(){
  debug "Create development container ..."
  run "sudo systemd-nspawn --template ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development true"
}

create_production_container(){
  debug "Create production container ..."
  run "sudo systemd-nspawn --template ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production true"
}

set_passwd_in_development_container(){
  debug "Set root password in development container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development bash -c \"echo -e \\\"930440Hk\n930440Hk\\\" | passwd\""
}

set_passwd_in_production_container(){
  debug "Set root password in production container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production bash -c \"echo -e \\\"930440Hk\n930440Hk\\\" | passwd\""
}

# Main part of the script

# include option parser
source ./lib/option_parser.sh


add_qemu

debootstrap_container

create_development_container
create_production_container

set_passwd_in_development_container
set_passwd_in_production_container









