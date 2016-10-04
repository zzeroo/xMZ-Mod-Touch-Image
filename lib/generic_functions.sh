#!/bin/bash
# Exit on error or variable unset
set -o errexit -o nounset
# Variablen
SIMULATE=""
VERBOSE=""

# Functions and logic
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
echo_b(){ echo -e ${bold}$1${normal}; }

# This function is called in show_help() function and prints and example string,
# if a example string is given.
# The examples can be defined on each script on top with the EXAMPLE="" env var.
example() {
  if [[ ! "x${EXAMPLE}" = "x" ]]; then
    echo_b "Example:"
    echo -e "\t$1"
    echo
  fi
}
SHORT=a:o:c:d:svfhi:k:
LONG=arch:output:,container_dir:,distribution:,simulate,verbose,force,help,image_name:,kernel_source:

# Show help, how is the programm called
show_help(){
	echo
  echo_b "Usage:"
	echo -e "\t`basename $0`\t[ARGUMENTS]"
	echo
	echo_b "Arguments:"
  echo -e "\t-a, --arch\tArchitektur (default: armhf)"
  echo -e "\t-o, --output_dir\tWo soll das Image gespeichert werden (default: current working dir)"
  echo -e "\t-c, --container_dir\tSpeicherort des systemd-nspawn Containers (default: /var/lib/container/)"
  echo -e "\t-d, --distribution\tDebian Distribution benutzt von debootstrap (default: sid)"
  echo -e "\t-s, --simulate\t\tPrint each command, but don't execute it"
  echo -e "\t-v, --verbose\t\tShow which commands are called"
  echo -e "\t-f, --force\t\tOverride existing files, DANGER!"
  echo -e "\t-h, --help\t\tShow this output"
  echo -e "\t-i, --image_name\tName des zu erstellenden Images 'xmz-\${DISTRIBUTION}-baseimage.img' (default: development)"
  echo -e "\t-k, --kernelsources\tWere should the output files created (default: /usr/src)"
	echo
  example "${EXAMPLE}"
	echo "Script version: ${SCRIPTVERSION}"
	exit 1
}

# Debug
debug() {
  # Only print if we not in sumulate mode
  if [[ x"${SIMULATE}" == "xtrue" ]]; then
    echo "# $1"
  else
    echo_b "$1"
  fi
}

# Error print error message and exit script
error() {
  echo "$1"
  exit 1
}

# Simulate, debug and call the command given as the only one parameter
# If the verbose var is set (via environent or parameter -v, --verbose)
# the command is echoed before calling
run() {
  if [[ x"${SIMULATE}" == "xtrue" ]]; then
		echo "$1"
  elif [[ x"${VERBOSE}" == "xtrue" && ! x"${SIMULATE}" == "xtrue" ]]; then
		echo ">> $1"
		eval "$1"
		# in verbose mode each command follows an empty line
		echo
	else
		eval "$1" &>/dev/null
	fi
}

_GENERIC_create_btrfs_snapshot() {
	debug "Erzeuge ein btrfs Snapshot von ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} nach ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}-`basename -s.sh $0`..."
  run "[ -d ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}-`basename -s.sh $0` ] && sudo mv ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}-`basename -s.sh $0` ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}-`basename -s.sh $0`-`date +%F-%T-%N` ||:"
  run "sudo btrfs subvolume snapshot ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}-`basename -s.sh $0`"
}

_GENERIC_create_image_copy() {
	debug "Erzeuge eine Kopie des Images ${OUTPUT_DIR}/${IMAGE_NAME} nach ${OUTPUT_DIR}/${IMAGE_NAME}-`basename -s.sh $0`..."
	run "cp ${OUTPUT_DIR}/${IMAGE_NAME} ${OUTPUT_DIR}/${IMAGE_NAME}-`basename -s.sh $0`"
}
