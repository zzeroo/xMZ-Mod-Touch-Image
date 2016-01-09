#!/bin/bash
#
# This script prepare the system for the stage scripts

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=custom-image.img
# Image size in mega byte
IMAGE_SIZE_MB=3000


source ./lib/functions.sh

# Show help, how is the programm called
show_help(){
	echo
	echo -e "Usage: `basename $0`\t[-o|--output_dir] [-f|--force] [-v|--verbose] [-h|--help]"
	echo
	echo_b "Arguments:"
	echo "-o, --output_dir\tWere should the output files created."
	echo "-f, --force\tOverride existing files, DANGER!"
	echo "-v, --verbose\tShow witch command was called."
	echo "-h, --help\tShow this output."
	echo
	echo "Script version: ${SCRIPTVERSION}"
	exit 1
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














