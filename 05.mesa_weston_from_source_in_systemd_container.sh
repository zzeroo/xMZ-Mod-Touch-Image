#!/bin/bash
# Dieses Script bildet Mesa und und Weston im Systemd Container
#
# Exit on error or variable unset
set -o errexit -o nounset

# Variablen

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.1.0"-$(git rev-parse --short HEAD)


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"
# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:

# Funktionen
build_mesa_from_source(){
  debug "Builde mesa aus den Quellen ..."
  run "sudo cp ./lib/mesa-from-source-in-arm-environment.sh ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/mesa-from-source-in-arm-environment.sh"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"chmod +x ./mesa-from-source-in-arm-environment.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"./mesa-from-source-in-arm-environment.sh\""
}

build_weston_from_source(){
  debug "Builde weston aus den Quellen ..."
  run "sudo cp ./lib/weston-from-source-in-arm-environment.sh ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/weston-from-source-in-arm-environment.sh"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"chmod +x ./weston-from-source-in-arm-environment.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} --chdir=/root /bin/bash -c \"./weston-from-source-in-arm-environment.sh\""
}




# Main part of the script
build_mesa_from_source

build_weston_from_source

_GENERIC_create_btrfs_snapshot
