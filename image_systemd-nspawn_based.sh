#!/bin/bash
#
# This script prepare the system for the stage scripts

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=sid_image_systemd-nspawn_based.img
# Image size in mega byte
IMAGE_SIZE_MB=3000


# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh







# Main part of the script

# Option parser
source ./lib/option_parser.sh







