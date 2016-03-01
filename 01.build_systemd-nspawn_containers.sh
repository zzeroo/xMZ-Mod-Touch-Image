#!/bin/bash
#
# This script creates a systemd-nspawn template and derive 2 containers from
# it. One "development"-container and one "production"-container.
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.9


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"

prepare_system() {
	debug "Bereite system vor ..."
	run "sudo apt-get install -y debootstrap"
}

add_qemu() {
  debug "Add qemu support ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin"
  if [[ -f /usr/bin/qemu-arm-static ]]; then
    run "sudo cp /usr/bin/qemu-arm-static ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/usr/bin/qemu-arm-static"
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
  run "# Or build from source:"
  run "# apt-get install build-essential pkg-config zlib1g-dev libglib2.0-dev autoconf libtool"
  run "# git submodule update --init pixman"
  run "# git clone git://git.qemu-project.org/qemu.git"
  run "# cd qemu"
  run "# mkdir build"
  run "# cd build"
  run "# ../configure --static --target-list=\"x86_64-linux-user arm-linux-user armeb-linux-user\"  --prefix=/usr"
  run "# make -j$(nproc)"
  run "# sudo make install"
}

debootstrap_template_container(){
  debug "Bootstrapping ${DISTRIBUTION} to ${CONTAINER_DIR} ..."
  run "# sudo debootstrap --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/"
  run "sudo debootstrap --variant=minbase --arch=armhf ${DISTRIBUTION} ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template/"
}

# This function prepares the
prepare_template_container(){
  debug "Prepare template container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template /bin/bash -c \"apt-get install -y sudo vim git\""
}

derive_development_container(){
  debug "Create development container ..."
  run "sudo systemd-nspawn --template ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development true"
}

derive_production_container(){
  debug "Create production container ..."
  run "sudo systemd-nspawn --template ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-template -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production true"
}

set_passwd_in_development_container(){
  debug "Set root password in development container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"echo -e \\\"930440Hk\n930440Hk\\\" | passwd\""
}

set_passwd_in_production_container(){
  debug "Set root password in production container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production /bin/bash -c \"echo -e \\\"930440Hk\n930440Hk\\\" | passwd\""
}

# TODO: Only in development container, should we use it in template or not?
enable_search_history() {
  debug "Enable search history with 'page up' and 'page down' ..."
  #run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production /bin/bash -c \"\""
  run "cat <<-EOF | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/.inputrc
# alternate mappings for \"page up\" and \"page down\" to search the history
\"\e[5~\": history-search-backward
\"\e[6~\": history-search-forward
EOF"
}

# TODO: Only in development container, should we use it in template or not?
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

debootstrap_template_container

prepare_template_container

derive_development_container
derive_production_container

set_passwd_in_development_container
set_passwd_in_production_container

