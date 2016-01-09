#!/bin/bash

# Functions and logic
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
echo_b(){ echo -e ${bold}$1${normal}; }

# Debug and call
# If the verbose var is set (via environent or parameter -v, --verbose)
# the command is echoed before calling
debug() {
	if [[ x"${verbose}" == "xtrue" ]]; then
		echo ">> $1"
		eval "$1"
		# in verbose mode each command follows an empty line
		echo
	else
		eval "$1" &>/dev/null
	fi
}

