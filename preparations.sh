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
  debug "sudo apt-get update && sudo apt-get upgrade"
}

install_qemu(){
  debug "sudo apt-get install -y build-essential u-boot-tools binutils-arm-linux-gnueabihf gcc-5-arm-linux-gnueabihf-base g++-5-arm-linux-gnueabihf"
}

install_dependencies(){
  debug "sudo apt-get install -y gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf libusb-1.0-0 libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
  debug "sudo apt-get install pkg-config"
}

build_bsp(){
	debug "cd ${OUTPUT_DIR}"
	debug "git clone https://github.com/LeMaker/lemaker-bsp.git"
	debug "cd lemaker-bsp.git"
	debug "./configure BananaPro"
	debug "make"
}

build_uboot(){
	debug "cd ${OUTPUT_DIR}"
	debug "git clone https://github.com/LeMaker/u-boot-sunxi.git"
  debug "cd u-boot-sunxi"
  debug "make CROSS_COMPILE=arm-linux-gnueabihf- BananaPro_config"
  debug "make CROSS_COMPILE=arm-linux-gnueabihf-"
}

build_sunxi_tools(){
	cd ${OUTPUT_DIR}
  git clone https://github.com/LeMaker/sunxi-tools.git
  cd sunxi-tools
  make
}

build_sunxi_boards(){
	cd ${OUTPUT_DIR}
  git clone https://github.com/LeMaker/sunxi-boards.git

}

get_fex_configuration(){
	cd ${OUTPUT_DIR}
  git clone https://github.com/LeMaker/fex_configuration.git
}

build_linux_kernel(){
	cd ${OUTPUT_DIR}
  # Kernel checkout
  git clone https://github.com/LeMaker/linux-sunxi.git
  # default configuration
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sun7i_defconfig
  # start menuconfig for manual configuration
  # FIXME: Include custom config
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
}





# Main part of the script

# Option parser
source ./lib/option_parser.sh




apt_update

install_dependencies

install_qemu

build_bsp
exit

build_uboot

build_sunxi_tools

build_sunxi_boards

get_fex_configuration

build_linux_kernel










