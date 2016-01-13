#!/bin/bash
#
# This script prepare the system for the stage scripts
EXAMPLE="./`basename $0` -s -o /var/lib/container"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.5
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=${DISTRIBUTION}_image_systemd-nspawn_based.img
# Image size in mega byte
IMAGE_SIZE_MB=3000

# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh


# all scripts and programs can properly executed while bootstraping,
add_qemu() {
  debug "Add qemu support ..."
  run "sudo mkdir -p ${OUTPUT_DIR}/${DISTRIBUTION}_armhf/usr/bin"
  run "sudo cp /usr/bin/qemu-arm-static ${OUTPUT_DIR}/${DISTRIBUTION}_armhf/usr/bin/"
  run "sudo cp /usr/bin/qemu-arm ${OUTPUT_DIR}/${DISTRIBUTION}_armhf/usr/bin/"
}

create_baseimage() {
  debug "Create baseimage with debootstrap ..."
  run "sudo debootstrap --arch=armhf ${DISTRIBUTION} ${OUTPUT_DIR}/${DISTRIBUTION}_armhf/"
}

print_quemu_setup() {
  debug "Print qemu setup ..."
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

# Qemu support has to be created BEFORE the debootstrap process, so that
run_systemd_nspawn() {
  debug "Setup image via systemd-nspawn ...."
  run "# The next commands should called in systemd-nspawn session (last command, the one without # in front!)"
  run "# passwd # Setzen des Passworts für Benutzer root"
  run "# apt-get install locales dbus # dbus ist notwendig"
  run "# dpkg-reconfigure locales"
  run "# echo xmz_mod_touch01>/etc/hostname"
  run "sudo systemd-nspawn -D ${OUTPUT_DIR}/${DISTRIBUTION}_armhf/"
}


# Main part of the script

# Option parser
source ./lib/option_parser.sh


add_qemu

create_baseimage

run_systemd_nspawn




