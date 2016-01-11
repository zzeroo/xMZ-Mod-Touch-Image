#!/bin/bash
#
# This script prepare the system for the stage scripts

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=custom-image.img
# Image size in mega byte
IMAGE_SIZE_MB=3000


# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh



apt_update(){
  debug "Update apt repository on developer system ..."
  run "sudo apt-get update && sudo apt-get upgrade"
}

install_qemu(){
  debug "Install qemu and dependencies ..."
  run "sudo apt-get install -y build-essential u-boot-tools binutils-arm-linux-gnueabihf gcc-5-arm-linux-gnueabihf-base g++-5-arm-linux-gnueabihf"
}

install_dependencies(){
  debug "Install dependencies on developer system ..."
  run "sudo apt-get install -y gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf libusb-1.0-0 libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
  run "sudo apt-get install pkg-config"
}

build_bsp(){
  debug "Board Support Package ..."
  run "# https://github.com/LeMaker/lemaker-bsp"
	run "cd ${OUTPUT_DIR}"
	run "git clone https://github.com/LeMaker/lemaker-bsp.git"
	run "cd lemaker-bsp"
	run "./configure BananaPro"
	run "make"
}

build_uboot(){
  debug "Build U-Boot, boot loader ..."
  run "# https://github.com/LeMaker/u-boot-sunxi"
	run "cd ${OUTPUT_DIR}"
	run "git clone https://github.com/LeMaker/u-boot-sunxi.git"
  run "cd u-boot-sunxi"
  run "make CROSS_COMPILE=arm-linux-gnueabihf- BananaPro_config"
  run "make CROSS_COMPILE=arm-linux-gnueabihf-"
}

build_sunxi_tools(){
  debug "Build sunxi tools a.k.a. sun4i ..."
  run "# https://github.com/LeMaker/sunxi-tools"
	run "cd ${OUTPUT_DIR}"
  run "git clone https://github.com/LeMaker/sunxi-tools.git"
  run "cd sunxi-tools"
  run "make"
}

build_sunxi_boards(){
  debug "Build sys_config files for different sunxi boards ..."
  run "# https://github.com/LeMaker/sunxi-boards"
	run "cd ${OUTPUT_DIR}"
  run "git clone https://github.com/LeMaker/sunxi-boards.git"

}

get_fex_configuration(){
  debug "Fetch fex_configuration files (fex and bin) ..."
  run "# https://github.com/LeMaker/fex_configuration"
	run "cd ${OUTPUT_DIR}"
  run "git clone https://github.com/LeMaker/fex_configuration.git"
}

build_linux_kernel(){
  debug "Fetch and build the linux kernel ..."
  run "# https://github.com/LeMaker/linux-sunxi"
	run "cd ${OUTPUT_DIR}"
  run "# Kernel checkout"
  run "git clone https://github.com/LeMaker/linux-sunxi.git"
  run "# default configuration"
  run "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sun7i_defconfig"
  run "# start menuconfig for manual configuration"
  run "# FIXME: Include custom config"
  run "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig"
  run "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules"
  run "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install"
}





# Main part of the script

# Option parser
source ./lib/option_parser.sh




apt_update

install_dependencies

install_qemu

# Option 1 BSP
# build_bsp

# Option 2
build_uboot

build_sunxi_tools

build_sunxi_boards

get_fex_configuration

build_linux_kernel










