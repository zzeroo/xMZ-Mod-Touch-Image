#!/bin/bash
# Neuer Versuch für ein Chroot/ Image für die 'xMZ-Mod-Touch'-Plattform

# Exit on error or variable unset
set -o errexit -o nounset

# Beispiel
EXAMPLE="./`basename $0` -s"

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.0

# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"

# Funktionen

# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:





echo PING
