#!/bin/bash
#
# This script fetches the sunxi tools and linux kernel and build them when
# needed. It should be used in a systemd-nspawn container with an up to date
# debian wheezy image.
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.7


# include generic functions (echo_b(), and debug() and so on)
source ./lib/generic_functions.sh


# Check for sudo
check_sudo(){
  if [[ x`which sudo` = "x" ]]; then
    debug "Error: sudo is not present. Trying to install it, hopefully we are root here"
    run "apt-get update && apt-get install -y sudo"
  fi
}

install_dependencies(){
  debug "Install dependencies for tools and kernel ..."
  run "sudo apt-get install -y build-essential u-boot-tools"
  run "sudo apt-get install -y libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
  run "sudo apt-get install -y pkg-config"
}

# # OPTION1: all files in so named Board Support Package (BSP), NOT USED!
# build_bsp(){
#   debug "Board Support Package ..."
#   run "# https://github.com/LeMaker/lemaker-bsp"
# 	run "cd ${OUTPUT_DIR}"
# 	run "git clone https://github.com/LeMaker/lemaker-bsp.git"
# 	run "cd lemaker-bsp"
# 	run "./configure BananaPro"
# 	run "make"
# }

# OPTION2: All following function are Option2, manual packege selection
build_uboot(){
  debug "Build U-Boot, boot loader ..."
  run "# https://github.com/LeMaker/u-boot-sunxi"
	run "cd ${OUTPUT_DIR}"
	run "[[ ! -d u-boot-sunxi ]] && git clone https://github.com/LeMaker/u-boot-sunxi.git"
  run "cd u-boot-sunxi"
  run "git pull"
  run "make BananaPro_config"
  run "make"
}

build_sunxi_tools(){
  debug "Build sunxi tools a.k.a. sun4i ..."
  run "# https://github.com/LeMaker/sunxi-tools"
	run "cd ${OUTPUT_DIR}"
  run "[[ ! -d sunxi-tools ]] && git clone https://github.com/LeMaker/sunxi-tools.git"
  run "cd sunxi-tools"
  run "git pull"
  run "make"
}

build_sunxi_boards(){
  debug "Build sys_config files for different sunxi boards ..."
  run "# https://github.com/LeMaker/sunxi-boards"
	run "cd ${OUTPUT_DIR}"
  run "[[ ! -d sunxi-boards ]] && git clone https://github.com/LeMaker/sunxi-boards.git"

}

get_fex_configuration(){
  debug "Fetch fex_configuration files (fex and bin) ..."
  run "# https://github.com/LeMaker/fex_configuration"
	run "cd ${OUTPUT_DIR}"
  run "[[ ! -d fex_configuration ]] && git clone https://github.com/LeMaker/fex_configuration.git"
}

build_linux_kernel(){
  debug "Fetch and build the linux kernel ..."
  run "# https://github.com/LeMaker/linux-sunxi"
	run "cd ${OUTPUT_DIR}"
  run "# Kernel checkout"
  run "[[ ! -d linux-sunxi ]] && git clone https://github.com/LeMaker/linux-sunxi.git"
  run "cd linux-sunxi"
  run "git pull"
  run "# default configuration"
  run "make ARCH=arm sun7i_defconfig"
  run "# start menuconfig for manual configuration"
  run "# FIXME: Include custom config"
  run "# make ARCH=arm menuconfig"
  run "make ARCH=arm uImage modules"
  run "make ARCH=arm INSTALL_MOD_PATH=output modules_install"
}

# Make a distribution tarball with the generated files, kernel and modules
make_dist(){
  debug "Create a tarball with the generated files, kernel and modules ..."
	run "cd ${OUTPUT_DIR}"
  run "mkdir files-kernel-modules/"
  run "cp ./u-boot-sunxi/u-boot-sunxi-with-spl.bin files-kernel-modules/"
  run "cp ./linux-sunxi/arch/arm/boot/uImage files-kernel-modules/"
  run "cp ./fex_configuration/bin/banana_pro_7lcd.bin files-kernel-modules/"
  run "cp -r ./linux-sunxi/output/lib/modules/3.4* files-kernel-modules/"
  run "tar cfvz files-kernel-modules-${SCRIPTVERSION}.tgz files-kernel-modules/"
  run "rm -rf files-kernel-modules"
  run "# sudo cp /var/lib/container/${DISTRIBUTION}_armhf-development/root/files-kernel-modules-${SCRIPTVERSION}.tgz ."
}




# Main part of the script

# include option parser
source ./lib/option_parser.sh




check_sudo

install_dependencies

# Option 1 BSP
# build_bsp

# Option 2
build_uboot

build_sunxi_tools

build_sunxi_boards

get_fex_configuration

build_linux_kernel

make_dist








