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


# This function creates an image,
# if the image file not exists, or it exists and the --force parameter was given
create_image(){
	debug "Create image ..."
	if [[ -z "${OUTPUT_DIR}/${IMAGE_NAME}" ]] || [[ -f "${OUTPUT_DIR}/${IMAGE_NAME}" && x"$FORCE" = "xtrue" ]]; then
		run "dd if=/dev/zero of=\"${OUTPUT_DIR}/${IMAGE_NAME}\" bs=1024 count=$[$IMAGE_SIZE_MB*1024]"
	else
		echo "Error: The file ${OUTPUT_DIR}/${IMAGE_NAME} already exist!"
		echo "Overwrite with -f parameter."
		exit 1
	fi
}

# Create a loop device
create_loop_device(){
	debug "Create loop device ..."
	run "sudo losetup /dev/loop10 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}

# Create the partition layout
create_partitions(){
	debug "Create partitions on /dev/loop10 ..."
	run "sudo fdisk /dev/loop10 <<-EOF
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
	debug "Create loop devices with offset ..."
	run "sudo losetup --offset $[2048 * 512]  /dev/loop11 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
	run "sudo losetup --offset $[43008 * 512] /dev/loop12 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}
# Make the file systems
make_filesystems(){
	debug "Make files systems on the loop devices ..."
	run "sudo mkfs.vfat /dev/loop11 || exit 1"
	run "sudo mkfs.ext4 /dev/loop12 || exit 1"
}




# Main part of the script

# include option parser
source ./lib/option_parser.sh


create_image

create_loop_device

create_partitions

create_loop_device_with_offset

make_filesystems













