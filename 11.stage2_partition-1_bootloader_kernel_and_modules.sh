#!/bin/bash
#
# This script creates a basic image file.

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.4.1"-$(git rev-parse --short HEAD)


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

# Write bootloader
write_bootloader(){
  debug "Write bootloader ..."
	run "sudo dd if=/dev/zero of=/dev/loop10 bs=1k count=1023 seek=1"
  run "sudo dd if=${KERNELSOURCES}/../u-boot/u-boot-sunxi-with-spl.bin of=/dev/loop10 bs=1024 seek=8"
}

create_boot_script(){
  debug "Create u-boot boot script boot.cmd ..."

  export mnt=/mnt/disk
  run "export mnt=/mnt/disk"
  # Check if dir is present, if not create
  run "[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}" ||:
  # Check if dir is already mounted, fail if so
  run "mountpoint ${mnt} >/dev/null && error \"${mnt} ist schon gemounted\"" ||:
  run "sudo mount /dev/loop11 ${mnt}"
  run "cat <<-'EOF' |sudo tee ${mnt}/boot.cmd
    # apt-get install u-boot-tools
		# mkimage -C none -A arm -T script -d boot.cmd boot.scr
    bootdelay=0
    setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10 vt.global_cursor_default=0 quiet splash
    load mmc 0:1 0x41000000 u-boot-splashscreen.bmp
    setenv splashimage 41000000
    load mmc 0:1 0x43000000 \${fdtfile} || load mmc 0:1 0x43000000 boot/\${fdtfile}
    load mmc 0:1 0x42000000 zImage || load mmc 0:1 0x42000000 boot/zImage
    bootz 0x42000000 - 0x43000000
EOF"
  run "sudo mkimage -C none -A arm -T script -d ${mnt}/boot.cmd ${mnt}/boot.scr"
}

uboot_splash(){
  debug "Copy in the splash image ..."
  run "sudo cp share/u-boot-splashscreen.bmp ${mnt}"
}

copy_in_kernel(){
  debug "Copy in kernel (partition1) ..."
  run "sudo cp ${KERNELSOURCES}/arch/arm/boot/zImage ${mnt}/"
  run "sudo cp ${KERNELSOURCES}/arch/arm/boot/dts/sun7i-a20-bananapro.dtb ${mnt}/"
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
source "$(dirname $0)/lib/option_parser.sh" ||:



create_loop_device

create_loop_device_with_offset

write_bootloader

create_boot_script

uboot_splash

copy_in_kernel

cleanup_mount

cleanup_loop_devices

_GENERIC_create_image_copy
