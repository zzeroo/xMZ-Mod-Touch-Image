#!/bin/bash
#
# This script creates a basic image file.

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.3.0


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"



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
  mnt=/mnt/disk
  run "export mnt=/mnt/disk"
  run "[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}"
  run "sudo mount /dev/loop12 ${mnt}"
}

copy_in_basic_filesystem(){
  debug "Copy in basic filesystem ..."
  run "sudo rsync -a --exclude '*root*' ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/* /mnt/disk"
  run "[ -d /mnt/disk/root  ] || sudo mkdir /mnt/disk/root/"
  run "# sudo bash -c \"cp -r ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.[^.]* /mnt/disk/root\"/"
  run "sudo bash -c \"cp -r ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/{weston.sh,.bashrc,.config,.cargo*,.multirust*,.inputrc,.ssh,.oh-my-zsh,.vim*,.zsh*,.zprofile} /mnt/disk/root\"/"
}

copy_in_modules(){
  debug "Copy in kernel modules (partition2) ..."
  run "sudo cp -r ${KERNELSOURCES}/output/lib ${mnt}/"
}

setup_fstab(){
  debug "Setup fstab ..."
  run "cat <<-EOF |sudo tee ${mnt}/etc/fstab
/dev/mmcblk0p2 / btrfs rw,relatime,ssd,noacl,space_cache,subvolid=5,subvol=/ 0 0
EOF"
}

disable_screenblank(){
  debug "disable screen blanking ..."
  run "echo -ne \"\033[9;0]\" | sudo tee ${mnt}/etc/issue"
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
source "$(dirname $0)/lib/option_parser.sh"




create_loop_device

create_loop_device_with_offset

mount_image_partition_2

copy_in_basic_filesystem

copy_in_modules

setup_fstab

disable_screenblank

cleanup_mount

cleanup_loop_devices
