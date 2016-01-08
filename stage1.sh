#!/bin/bash
#
# This script creates a basic image file.

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=custom-image.img
# Image size in mega byte
IMAGE_SIZE_MB=3000


# Functions and logic
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
function echo_b { echo -e ${bold}$1${normal}; }

function show_help {
echo
echo -e "`basename $0`\t\t[-o|--output_dir]"
echo
echo_b "Arguments:"
echo "-o | --output_dir\tWere should the output files created."
echo
echo "Script version: ${SCRIPTVERSION}"
}

# This function creates an image
function create_image {
if [[ -z "${OUTPUT_DIR}/${IMAGE_NAME}" ]] || [[ -f "${OUTPUT_DIR}/${IMAGE_NAME}" && x"$force" = "xtrue" ]]; then
  dd if=/dev/zero of="${OUTPUT_DIR}/${IMAGE_NAME}" bs=1024 count=$[$IMAGE_SIZE_MB*1024]
else
  echo "The file ${OUTPUT_DIR}/${IMAGE_NAME} already exist!"
  echo "Overwrite with -f parameter."
fi
}

# Create a loop device
function create_loop_device {
sudo losetup /dev/loop10 "${OUTPUT_DIR}/${IMAGE_NAME}"
}



# Main part of the script

# Option parser
getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:fhv
LONG=output:,force,help,verbose

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
		-v|--verbose)
			verbose=true
			shift # past argument
			;;
		-f|--force)
			force=true
			shift # past argument
			;;
		-h|--help)
			show_help
			shift # past argument
			;;
		--)
			shift
			break
			;;
	esac
done

# Parameter setup
# If output dir is not given as parameter, use the current dir .
[ x"${OUTPUT_DIR}" = x ] && OUTPUT_DIR="."


create_image

exit 666
create_loop_device




















