#!/bin/bash
#
# This script creates a systemd-nspawn container.
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.2.0


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"

prepare_system() {
	debug "Bereite system vor ..."
	run "sudo apt-get install -y debootstrap"
}

add_qemu() {
  debug "Add qemu support ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/usr/bin"
  if [[ -f /usr/bin/qemu-arm-static ]] || [[ -f /usr/bin/qemu-arm ]]; then
    run "sudo bash -c \"cp /usr/bin/qemu-arm* ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/usr/bin/qemu-arm-static\""
  else
    print_quemu_setup
    # If we're not on simulate mode exit here.
    [[ ! x"${SIMULATE}" = "xtrue" ]] && exit
  fi
}

print_quemu_setup() {
  debug "Print qemu setup ..."
  run "# Error: qemu, static linked missing!"
  run "# Install via apt:"
  run "# sudo apt-get install -y qemu-user-static binfmt-support"
  run "#"
	run "# Or build from source (PREFERED):"
  run "# apt-get install build-essential pkg-config zlib1g-dev libglib2.0-dev autoconf libtool binfmt-support"
  run "# git clone git://git.qemu-project.org/qemu.git"
  run "# cd qemu"
	run "# git submodule update --init pixman"
  run "# mkdir build"
  run "# cd build"
  run "# ../configure --static --target-list=\"x86_64-linux-user arm-linux-user armeb-linux-user\"  --prefix=/usr"
  run "# make -j$(nproc)"
  run "# sudo make install"
}

debootstrap_container(){
  debug "Bootstrapping ${DISTRIBUTION} to ${CONTAINER_DIR} ..."
	run "# sudo debootstrap --variant=minbase --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/"
	run "sudo debootstrap --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/"
}

set_passwd_in_container(){
  debug "Set root password in container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo -e \\\"930440Hk\n930440Hk\\\" | passwd\""
}


enable_search_history() {
  debug "Enable search history with 'page up' and 'page down' ..."
  #run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production /bin/bash -c \"\""
  run "cat <<-EOF | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/.inputrc
# alternate mappings for \"page up\" and \"page down\" to search the history
\"\e[5~\": history-search-backward
\"\e[6~\": history-search-forward
EOF"
}

# TODO: Needed?
configure_bashrc() {
  debug "configure bashrc (some alias and color) ..."
  #run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production /bin/bash -c \"\""
  run "cat <<-EOF | sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/.bashrc
export LS_OPTIONS='--color=auto'
eval \"`dircolors`\"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
EOF"
}


# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"

prepare_system

add_qemu

debootstrap_container

set_passwd_in_container

enable_search_history

# configure_bashrc
