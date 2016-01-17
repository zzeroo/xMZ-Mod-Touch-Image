#!/bin/bash
#
# This script must be called into the systemd-nspawn production container

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.9


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"


# TODO: Think about packages like build-essential, can they installed in the template container?
prepare_production_container(){
  debug "Prepare production container ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production apt-get install -y intltool autoconf build-essential libmodbus5 libgee2 libgtk-3-0"
}

extract_xmz_gui(){
  debug "Copy in the xMZ-Mod-Touch-GUI ..."
  run "sudo tar xfJ xmz-0.4.2.tar.xz -C ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production/root/"
}




# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"

# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage-image.img


prepare_production_container

extract_xmz_gui

