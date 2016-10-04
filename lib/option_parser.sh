#!/bin/bash
# Exit on error or variable unset
set -o errexit -o nounset

# Variablen
ARCH=""
OUTPUT_DIR=""
CONTAINER_DIR=""
DISTRIBUTION=""
FORCE=""
KERNELSOURCES=""
DEFAULT_HOSTNAME=""
ROOT_PASSWORD=""
SUFFIX=""

# CONSTANTES
# Image size in mega byte
IMAGE_SIZE_MB=4000


# Test ob getopt existiert
getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=a:o:c:d:svfhi:k:
LONG=arch:output:,container_dir:,distribution:,simulate,verbose,force,help,image_name:,kernel_source:

PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
		-a|--arch)
			ARCH="$2"
			shift 2
			;;
		-o|--output_dir)
			OUTPUT_DIR="$2"
			shift 2
			;;
		-c|--container_dir)
			CONTAINER_DIR="$2"
			shift 2
			;;
		-d|--distribution)
			DISTRIBUTION="$2"
			shift 2
			;;
		-f|--force)
			FORCE=true
			shift
			;;
		-h|--help)
			show_help
			shift
			;;
		-i|--image_name)
			IMAGE_NAME="$2"
			shift 2
			;;
		-k|--kernelsources)
			KERNELSOURCES="$2"
			shift 2
			;;
		-s|--simulate)
			SIMULATE=true
			shift
			;;
		-v|--verbose)
			VERBOSE=true
			shift
			;;
		--)
			shift
			break
			;;
	esac
done

# VARIABLES
# DEFAULT VALUES
## Die Default Werte werden nach folgendem Muster gesetzt:
## If '[' der Buchstabe 'x' + der $NAME_DER_VAR == 'x' dann ist die Variable nicht
## gesetzt, leer. Also setze mit dem Wert=....
[ x"${ARCH}" = x ] && ARCH="armhf"
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
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
[ x"${IMAGE_NAME}" = x ] && IMAGE_NAME="xmz-${DISTRIBUTION}-baseimage.img"
# Compose the final container name
CONTAINER_NAME=${DISTRIBUTION}_armhf${SUFFIX}
