#!/bin/bash
#
# This script creates a basic image file.

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.5.1"-$(git rev-parse --short HEAD)


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"

# This function creates an image,
# if the image file not exists, or it exists and the --force parameter was given
create_image(){
	debug "Create image ..."
	if [[ x"$SIMULATE" = "xtrue" ]] || [[ ! -f "${OUTPUT_DIR}/${IMAGE_NAME}" ]] || [[ -f "${OUTPUT_DIR}/${IMAGE_NAME}" && x"$FORCE" = "xtrue" ]]; then
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
	run "sudo losetup /dev/loop10 \"${OUTPUT_DIR}/${IMAGE_NAME}\""
}

# Create the partition layout with fdisk
create_partitions_fdisk(){
	debug "Create partitions on /dev/loop10 ..."
	run "sudo fdisk /dev/loop10 <<-'EOF'
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
# Create the partition layout with gdisk
# FIXME: Not working, partitions are corrupt on filesystem creation
create_partitions_gdisk(){
	debug "Create partitions on /dev/loop10 ..."
	run "sudo gdisk /dev/loop10 <<-'EOF'
	n
	1

	+20M
	0700
	n
	2




	w
	y
EOF"
}
# Create the partition layout with parted
create_partitions_parted(){
	debug "Create partitions on /dev/loop10 ..."
	run "sudo parted --script -a optimal /dev/loop10 \
	mklabel msdos \
	mkpart primary fat32 2048s 43007s \
	mkpart primary btrfs 43008s 100%"
}

# Create the partition
# This is a helper function. It checks for the presens of gdisk, if gdisk is not
# found on the system, a fallback to fdisk is used.
create_partitions(){
	[ -f "/sbin/gdisk" ] && create_partitions_parted || create_partitions_fdisk
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
	run "sudo mkfs.btrfs /dev/loop12 || exit 1"
	#run "sudo mkfs.ext4 /dev/loop12 || exit 1"
}

cleanup_loop_devices(){
	debug "Destroy loop devices ..."
	run "sudo losetup -d /dev/loop{10,11,12}"
}


# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:


create_image

create_loop_device

create_partitions

create_loop_device_with_offset

make_filesystems

cleanup_loop_devices

_GENERIC_create_image_copy
