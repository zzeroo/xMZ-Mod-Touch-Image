#!/bin/bash
# TEMPLATE BESCHREIBUNG
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
funktion1() {
  debug "Beschreibung ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"\""
}


# Main part of the script
funktion1

_GENERIC_create_btrfs_snapshot
