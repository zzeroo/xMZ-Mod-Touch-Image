#!/bin/bash
#
# This script prepare the system for the stage scripts
EXAMPLE="./`basename $0` -s -o /var/lib/container/"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.5
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=${DISTRO}_image_systemd-nspawn_based.img
# Image size in mega byte
IMAGE_SIZE_MB=3000
# Linux distibution
DISTRO=wheezy

# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh


# all scripts and programs can properly executed while bootstraping,
add_qemu() {
  debug "Add qemu support ..."
  run "sudo mkdir ${OUTPUT_DIR}/${DISTRO}_armhf/usr/bin"
  run "sudo cp /usr/bin/qemu-arm-static ${OUTPUT_DIR}/${DISTRO}_armhf/usr/bin"
}

create_baseimage() {
  debug "Create baseimage with debootstrap ..."
  run "sudo debootstrap --arch=armhf ${DISTRO} ${OUTPUT_DIR}/${DISTRO}_armhf/"
}

# Qemu support has to be created BEFORE the debootstrap process, so that
run_systemd_nspawn() {
  debug ""
  run "# passwd # Setzen des Passworts für Benutzer root"
  run "# apt-get install locales dbus # dbus ist notwendig"
  run "# dpkg-reconfigure locales"
  run "# hostnamectl set-hostname xmz_mod_touch01"
  run "# timedatectl set-timezone Europe/Berlin"
  run "sudo systemd-nspawn -D ${OUTPUT_DIR}/${DISTRO}_armhf/"
}


# Main part of the script

# Option parser
source ./lib/option_parser.sh


add_qemu

create_baseimage

run_systemd_nspawn




