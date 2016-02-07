#!/bin/bash

#
# This script set up the systemd-nspawn development container
#
EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.9


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"



# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development
# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/ && /bin/bash ./configure --prefix=/usr\"

install_dependencies(){
  debug "Install dependencies for tools and kernel ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y build-essential pkg-config git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
}


build_uboot(){
  debug "Build U-Boot, boot loader ..."
  run "# https://github.com/LeMaker/u-boot-sunxi"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d u-boot-sunxi ]] && git clone https://github.com/LeMaker/u-boot-sunxi.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make BananaPro_config\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make -j$(nproc)\""
}

build_sunxi_tools(){
  debug "Build sunxi tools a.k.a. sun4i ..."
  run "# https://github.com/LeMaker/sunxi-tools"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d sunxi-tools  ]] && git clone https://github.com/LeMaker/sunxi-tools.git || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && make -j$(nproc)\""
}

build_linux_kernel(){
  debug "Fetch and build the linux kernel ..."
  run "# https://github.com/LeMaker/linux-sunxi"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d linux-sunxi ]] && git clone https://github.com/LeMaker/linux-sunxi.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make sun7i_defconfig\""
  run "# FIXME: Include custom config"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make -j$(nproc) uImage modules\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make INSTALL_MOD_PATH=output modules_install\""
}



# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"



install_dependencies

build_uboot

build_sunxi_tools

build_linux_kernel

