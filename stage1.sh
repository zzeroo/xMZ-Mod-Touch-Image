#!/bin/bash
#
# This script creates a basic image file.

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.2
# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=custom-image.img
# Image size in mega byte
IMAGE_SIZE_MB=3000


# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh



# Show help, how is the programm called
show_help(){
	echo
	echo -e "Usage: `basename $0`\t[-o|--output_dir] [-f|--force] [-v|--verbose] [-h|--help]"
	echo
	echo "Arguments:"
	echo -e "-o, --output_dir\tWere should the output files created."
	echo -e "-f, --force\t\tOverride existing files, DANGER!"
	echo -e "-v, --verbose\t\tShow witch command was called."
	echo -e "-h, --help\t\tShow this output."
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
	debug "sudo losetup /dev/loop10 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}

# Create the partition layout
create_partitions(){
	echo_b "Create partitions on /dev/loop10 ..."
	debug "sudo fdisk /dev/loop10 <<-EOF
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
	EOF"
}
# Create loop devices with offset
create_loop_device_with_offset(){
	echo_b "Create loop devices with offset ..."
	debug "sudo losetup --offset $[2048 * 512]  /dev/loop11 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
	debug "sudo losetup --offset $[43008 * 512] /dev/loop12 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}
# Make the file systems
make_filesystems(){
	echo_b "Make files systems on the loop devices ..."
	debug "sudo mkfs.vfat /dev/loop11 || exit 1"
	debug "sudo mkfs.ext4 /dev/loop12 || exit 1"
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

create_loop_device_with_offset

make_filesystems













