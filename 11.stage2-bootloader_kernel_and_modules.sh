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

extract_kernel_and_tools(){
  debug "Copy in the kernel and tools tar ..."
  run "sudo tar xfz files-kernel-modules-*.tgz -C ${OUTPUT_DIR}/"
}

# Write bootloader
write_bootloader(){
  debug "Write bootloader ..."
	run "sudo dd if=/dev/zero of=/dev/loop10 bs=1k count=1023 seek=1"
	run "sudo dd if=${OUTPUT_DIR}/files-kernel-modules/u-boot-sunxi-with-spl.bin of=/dev/loop10 bs=1024 seek=8"
}

create_boot_script(){
  debug "Create boot script uEnv.txt ..."
  mnt=/tmp/disk
  run "export mnt=/tmp/disk"
  run "[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}"
  run "sudo mount /dev/loop11 ${mnt}"
  run "cat <<-'EOF' |sudo tee ${mnt}/uEnv.txt
  bootargs=console=ttyS0,115200 disp.screen0_output_mode=EDID:1024x768p50 hdmi.audio=EDID:0 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
  aload_script=fatload mmc 0 0x43000000 script.bin;
  aload_kernel=fatload mmc 0 0x48000000 uImage;bootm 0x48000000;
  uenvcmd=run aload_script aload_kernel
EOF"
}

copy_in_kernel(){
  debug "Copy in kernel (partition1) ..."
  run "sudo cp ${OUTPUT_DIR}/files-kernel-modules/uImage ${mnt}/"
}

copy_in_modules(){
  debug "Copy in kernel modules (partition2) ..."
  run "sudo mount /dev/loop11 ${mnt}"
  run "sudo mkdir -p ${mnt}/lib/modules"
  run "sudo cp -r ${OUTPUT_DIR}/files-kernel-modules/3.4.* ${mnt}/lib/modules/"
}

copy_in_script_bin(){
  debug "Copy in script.bin ..."
  run "sudo cp ${OUTPUT_DIR}/files-kernel-modules/banana_pro_7lcd.bin ${mnt}/script.bin"
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

extract_kernel_and_tools

write_bootloader

create_boot_script

copy_in_kernel

copy_in_script_bin

cleanup_mount

copy_in_modules

cleanup_mount

cleanup_loop_devices










