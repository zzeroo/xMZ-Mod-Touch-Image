#!/bin/bash
#
# This script creates a basic image file.

# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.0.1
EXAMPLE="./`basename $0` -o /mnt/ramdisk -s"

# generic functions
# echo_b(), and debug()
source ./lib/generic_functions.sh



# Create a loop device
create_loop_device(){
	debug "Create loop device ..."
	run "sudo losetup /dev/loop10 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}

# Create loop devices with offset
create_loop_device_with_offset(){
	debug "Create loop devices with offset ..."
	run "sudo losetup --offset $[2048 * 512]  /dev/loop11 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
	run "sudo losetup --offset $[43008 * 512] /dev/loop12 \"${OUTPUT_DIR}/${IMAGE_NAME}\" || exit 1"
}


mount_image_partition_2(){
  debug "Mount image partition 2 ..."
  mnt=/tmp/disk
  run "export mnt=/tmp/disk"
  run "[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}"
  run "sudo mount /dev/loop12 ${mnt}"
}

copy_in_basic_filesystem(){
  debug "Copy in basic filesystem ..."
  run "sudo rsync -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-production/* /tmp/disk"
}



cleanup_mount(){
  debug "Umount ${mnt} ..."
  run "sudo umount ${mnt}"
}


cleanup_loop_devices(){
	debug "Destroy loop devices ..."
	run "sudo losetup -d /dev/loop{10,11,12}"
}


# Main part of the script

# include option parser
source ./lib/option_parser.sh

# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage-image.img
# Image size in mega byte
IMAGE_SIZE_MB=3000



create_loop_device

create_loop_device_with_offset

mount_image_partition_2

copy_in_basic_filesystem

cleanup_mount

cleanup_loop_devices










