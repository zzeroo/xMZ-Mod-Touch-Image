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
echo_b(){ echo -e ${bold}$1${normal}; }

log(){
	[[ x"${verbose}" = "xtrue" ]] && echo $1;
}

debug() {
	if [[ x"${verbose}" == "xtrue" ]]; then
		echo ">> $1"
		eval "$1"
	else
		eval "$1"
	fi
}

# Show help, how is the programm called
show_help(){
	echo
	echo -e "Usage: `basename $0`\t[-o|--output_dir] [-f|--force] [-v|--verbose] [-h|--help]"
	echo
	echo "Arguments:"
	echo "-o, --output_dir\tWere should the output files created."
	echo "-f, --force\tOverride existing files, DANGER!"
	echo "-v, --verbose\tShow witch command was called."
	echo "-h, --help\tShow this output."
	echo
	echo "Script version: ${SCRIPTVERSION}"
	exit 1
}

# This function creates an image,
# if the image file not exists, or it exists and the --force parameter was given
create_image(){
	echo_b "Create image ..."
	if [[ -z "${OUTPUT_DIR}/${IMAGE_NAME}" ]] || [[ -f "${OUTPUT_DIR}/${IMAGE_NAME}" && x"$force" = "xtrue" ]]; then
		debug "dd if=/dev/zero of=\"${OUTPUT_DIR}/${IMAGE_NAME}\" bs=1024 count=$[$IMAGE_SIZE_MB*1024]"
	else
		echo "Error: The file ${OUTPUT_DIR}/${IMAGE_NAME} already exist!"
		echo "Overwrite with -f parameter."
		exit 1
	fi
}

# Create a loop device
create_loop_device(){
	echo_b "Create loop device ..."
	debug "sudo losetup /dev/loop10 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || echo \"Error: Please check loop device /dev/loop10\"; exit 1"
}

# Create the partition layout
create_partitions(){
	sudo fdisk /dev/loop10 <<-EOF
	o
	n
	p
	1

	+20M
	n
	p
	2


	t
	1
	7
	w
	EOF
}
# Mount the partitions of the image
mount_partitions(){
	debug "sudo losetup --offset $[2048 * 512]  /dev/loop10p1 \"${OUTPUT_DIR}/${IMAGE_NAME}\""
	debug "sudo losetup --offset $[43008 * 512] /dev/loop10p2 \"${OUTPUT_DIR}/${IMAGE_NAME}\""
}
# Make the file systems
make_filesystems(){
	debug "sudo mkfs.vfat /dev/loop10p1"
	debug "sudo mkfs.ext4 /dev/loop10p2"
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

create_loop_device

create_partitions

mount_partitions
















