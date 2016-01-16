#!/bin/bash
#
# This script set up the systemd-nspawn development container
#
EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.7



# include generic functions (echo_b(), and debug() and so on)
source ./lib/generic_functions.sh
# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development
# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/ && /bin/bash ./configure --prefix=/usr\"

install_dependencies(){
  debug "Install dependencies for tools and kernel ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y build-essential pkg-config u-boot-tools libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
}

# # OPTION1: all files in so named Board Support Package (BSP), NOT USED!
# build_bsp(){
#   debug "Board Support Package ..."
#   run "# https://github.com/LeMaker/lemaker-bsp"
# 	run "cd ${OUTPUT_DIR}"
# 	run "git clone https://github.com/LeMaker/lemaker-bsp.git || exit"
# 	run "cd lemaker-bsp"
# 	run "./configure BananaPro"
# 	run "make"
# }

# OPTION2: All following function are Option2, manual packege selection
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

build_sunxi_boards(){
  debug "Fetch sunxi boards repo ..."
  run "# https://github.com/LeMaker/sunxi-boards"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d sunxi-boards ]] && git clone https://github.com/LeMaker/sunxi-boards.git || true\""
}

get_fex_configuration(){
  debug "Fetch fex_configuration files (fex and bin) ..."
  run "# https://github.com/LeMaker/fex_configuration"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d fex_configuration ]] && git clone https://github.com/LeMaker/fex_configuration.git || true\""
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

build_libmodbus(){
  debug "Fetch and build libmodbus ..."
  run "# https://github.com/stephane/libmodbus.git"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y autoconf git-core build-essential libtool"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d libmodbus ]] && git clone https://github.com/stephane/libmodbus.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && ./autogen.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && ./configure --prefix=/usr\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && make -j$(nproc)\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && make install\""
}

build_xmz(){
  debug "Fetch and build the xMZ-Mod-Touch GUI ..."
  run "# https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y intltool libgtk-3-dev gsettings-desktop-schemas-dev libgee-dev libsqlite3-dev libgirepository1.0-dev gnome-common valac"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d xMZ-Mod-Touch-GUI ]] && git clone https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && ./autogen.sh --prefix=/usr\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make # -j$(nproc) dosn't work!\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make dist\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make install\""
}


# Main part of the script

# include option parser
source ./lib/option_parser.sh


install_dependencies

# Option 1 BSP
# build_bsp

# Option 2
build_uboot

build_sunxi_tools

build_sunxi_boards

get_fex_configuration

build_linux_kernel

build_libmodbus

build_xmz









