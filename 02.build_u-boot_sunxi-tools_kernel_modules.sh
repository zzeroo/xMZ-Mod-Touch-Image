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
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"echo \\\"deb http://httpredir.debian.org/debian sid main non-free\\\" > /etc/apt/sources.list\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"apt-get update && apt-get upgrade -y\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"apt-get install -y build-essential pkg-config git wget fakeroot zlib1g-dev libncurses5-dev u-boot-tools\""
}


build_uboot(){
  debug "Build U-Boot, boot loader ..."
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "# git://git.denx.de/u-boot.git"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"apt-get install -y device-tree-compiler\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d u-boot ]] && git clone git://git.denx.de/u-boot.git\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot && git pull\""
    run "sudo cp share/Bananapro_defconfig ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/u-boot/configs/Bananapro_defconfig"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot && make Bananapro_defconfig\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot && make -j$(nproc)\""
  else
    run "# https://github.com/LeMaker/u-boot-sunxi"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d u-boot-sunxi ]] && git clone https://github.com/LeMaker/u-boot-sunxi.git --depth=1 || true\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && git pull\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make BananaPro_config\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make -j$(nproc)\""
  fi
}

build_sunxi_tools(){
  if [ z${DISTRIBUTION} = "zjessie" ]; then
    debug "Build sunxi tools a.k.a. sun4i ..."
    run "# https://github.com/LeMaker/sunxi-tools"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d sunxi-tools  ]] && git clone https://github.com/LeMaker/sunxi-tools.git || true\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && git pull\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && make -j$(nproc)\""
  fi
}

# TODO: Include cutom logo:
#   # copy in a logo (png, 80x80 px)
#   cd share
#   pngtopnm logo_linux.png | ppmquant -fs 223| pnmtoplainpnm > logo_linux_clut224.ppm
#   sudo cp logo_linux_clut224.ppm ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/linux-sunxi/drivers/video/logo/
fetch_kernel() {
  debug "Fetch linux kernel ..."
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "# https://github.com/linux-sunxi/linux-sunxi"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d linux-sunxi ]] && git clone https://github.com/linux-sunxi/linux-sunxi.git || true\""
  else
    run "# https://github.com/LeMaker/linux-sunxi"
    run "# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d linux-sunxi ]] && git clone https://github.com/LeMaker/linux-sunxi.git --depth=1 -b experimental/sunxi-3.10 || true\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d linux-sunxi ]] && git clone https://github.com/LeMaker/linux-sunxi.git --depth=1 || true\""
  fi
  # Update the git repo if the dir was present, and the kernel was not fresh checked out.
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && git pull\""
}

config_kernel(){
  debug "Configure linux kernel ..."
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && git checkout sunxi-next\""
    run "sudo cp share/.config ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/linux-sunxi/.config"
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make oldconfig\""
  else
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make sun7i_defconfig\""
  fi
}

build_kernel(){
  run "Build linux kernel ..."
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make -j$(nproc) zImage dtbs modules\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make INSTALL_MOD_PATH=output modules_install\""
  else
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make -j$(nproc) uImage modules\""
    run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make INSTALL_MOD_PATH=output modules_install\""
  fi
}



# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"



install_dependencies

build_uboot

build_sunxi_tools

fetch_kernel

config_kernel

build_kernel

