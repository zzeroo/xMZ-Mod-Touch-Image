#!/bin/bash
#
# This script must be called into the systemd-nspawn production container

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
EXAMPLE="./`basename $0` -o /root -s"

# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh


extract_xmz_gui(){
  debug "Copy in the xMZ-Mod-Touch-GUI ..."
  run "sudo tar xfJ xmz-0.4.2.tar.xz -C ${OUTPUT_DIR}/"
}




# Main part of the script

# include option parser
source ./lib/option_parser.sh

# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage-image.img


extract_xmz_gui








