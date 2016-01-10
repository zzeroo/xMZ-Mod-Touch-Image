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


# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh



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

# Write bootloader
write_bootloader(){
	debug "sudo dd if=/dev/zero of=/dev/loop10 bs=1k count=1023 seek=1"
	debug "sudo dd if=u-boot-sunxi/u-boot-sunxi-with-spl.bin of=/dev/loop10 bs=1024 seek=8"
}




# Main part of the script

# Option parser
source ./lib/option_parser.sh

create_image

create_loop_device

create_partitions

create_loop_device_with_offset

make_filesystems

exit
write_bootloader












