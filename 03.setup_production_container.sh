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

setup_dotfiles(){
  debug "Setup dotfiles ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -qq -y vim zsh tmux git curl"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d .dotfiles ]] && git clone https://github.com/zzeroo/.dotfiles.git || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/.dotfiles && ./install.sh\""
}




# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"

# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage-image.img


prepare_production_container

setup_dotfiles


