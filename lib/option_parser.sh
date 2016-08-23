#!/bin/bash
# Exit on error or variable unset
set -o errexit -o nounset

# Variables
OUTPUT_DIR=""
CONTAINER_DIR=""
DISTRIBUTION=""
KERNELSOURCES=""
DEFAULT_HOSTNAME=""
ROOT_PASSWORD=""
SUFFIX=""
# CONSTANTES
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage.img
# Image size in mega byte
IMAGE_SIZE_MB=4000
# Compose the final container name
CONTAINER_NAME=${DISTRIBUTION}_armhf${SUFFIX}


# Test ob getopt existiert
getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:c:d:svfhk:
LONG=output:,container_dir:,distribution:,simulate,verbose,force,help,kernel_source:

PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
		-o|--output_dir)
			OUTPUT_DIR="$2"
			shift 2 # past argument
			;;
		-c|--container_dir)
			CONTAINER_DIR="$2"
			shift 2 # past argument
			;;
		-d|--distribution)
			DISTRIBUTION="$2"
			shift 2 # past argument
			;;
		-f|--force)
			FORCE=true
			shift # past argument
			;;
		-h|--help)
			show_help
			shift # past argument
			;;
		-k|--kernelsources)
			KERNELSOURCES="$2"
			shift 2 # past argument
			;;
		-s|--simulate)
			SIMULATE=true
			shift # past argument
			;;
		-v|--verbose)
			VERBOSE=true
			shift # past argument
			;;
		--)
			shift
			break
			;;
	esac
done

# VARIABLES
# DEFAULT VALUES
# If output dir is not given as parameter, use the current dir.
[ x"${OUTPUT_DIR}" = x ] && OUTPUT_DIR="`pwd`"
# TODO: replace hard coded CONTAINER_DIR paths in the scripts
# If container_dir is not set, we use the systemd-nspawn default path
[ x"${CONTAINER_DIR}" = x ] && CONTAINER_DIR="/var/lib/container"
# If distribution is not given as parameter we use debian sid.
[ x"${DISTRIBUTION}" = x ] && DISTRIBUTION="sid"
# Kernel Sources path
[ x"${KERNELSOURCES}" = x ] && KERNELSOURCES="/usr/src/linux"
# Default hostname
[ x"${DEFAULT_HOSTNAME}" = x ] && DEFAULT_HOSTNAME="xmz-mod-touch"
# Root Password
[ x"${ROOT_PASSWORD}" = x ] && ROOT_PASSWORD="930440"
