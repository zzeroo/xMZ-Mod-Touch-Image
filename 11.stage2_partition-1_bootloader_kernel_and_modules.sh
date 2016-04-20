#!/bin/bash
#
# This script creates a basic image file.

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.2.0


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
# TODO: jessie distribution hard coded
write_bootloader(){
  debug "Write bootloader ..."
	run "sudo dd if=/dev/zero of=/dev/loop10 bs=1k count=1023 seek=1"
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "sudo dd if=${KERNELSOURCES}/../u-boot/u-boot-sunxi-with-spl.bin of=/dev/loop10 bs=1024 seek=8"
  else
    run "sudo dd if=${CONTAINER_DIR}/jessie_armhf/root/u-boot-sunxi/u-boot-sunxi-with-spl.bin of=/dev/loop10 bs=1024 seek=8"
  fi
}

create_boot_script(){
  debug "Create boot script boot.cmd or uEnv.txt ..."

  export mnt=/mnt/disk
  run "export mnt=/mnt/disk"
  # Check if dir is present, if not create
  run "[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}"
  # Check if dir is already mounted, fail if so
  run "mountpoint ${mnt} >/dev/null && error \"${mnt} ist schon gemounted\""
  run "sudo mount /dev/loop11 ${mnt}"

  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "cat <<-'EOF' |sudo tee ${mnt}/boot.cmd
    # mkimage -C none -A arm -T script -d boot.cmd boot.scr
    bootdelay=-2
    setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10 vt.global_cursor_default=0 quiet splash
    load mmc 0:1 0x41000000 u-boot-splashscreen.bmp
    setenv splashimage 41000000
    load mmc 0:1 0x43000000 \${fdtfile} || load mmc 0:1 0x43000000 boot/\${fdtfile}
    load mmc 0:1 0x42000000 zImage || load mmc 0:1 0x42000000 boot/zImage
    bootz 0x42000000 - 0x43000000
EOF"
    run "sudo mkimage -C none -A arm -T script -d ${mnt}/boot.cmd ${mnt}/boot.scr"
  else
    run "cat <<-'EOF' |sudo tee ${mnt}/uEnv.txt
bootargs=console=ttyS0,115200 disp.screen0_output_mode=EDID:1024x768p50 hdmi.audio=EDID:0 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait consoleblank=0
aload_script=fatload mmc 0 0x43000000 script.bin;
aload_kernel=fatload mmc 0 0x48000000 uImage;bootm 0x48000000;
uenvcmd=run aload_script aload_kernel
EOF"
  fi
}

uboot_splash(){
  if [ z${DISTRIBUTION} = "zsid" ]; then
    debug "Copy in the splash image ..."
    run "sudo cp share/u-boot-splashscreen.bmp ${mnt}"
  fi
}

copy_in_kernel(){
  debug "Copy in kernel (partition1) ..."
  if [ z${DISTRIBUTION} = "zsid" ]; then
    run "sudo cp ${KERNELSOURCES}/arch/arm/boot/zImage ${mnt}/"
    run "sudo cp ${KERNELSOURCES}/arch/arm/boot/dts/sun7i-a20-bananapro.dtb ${mnt}/"
  else
    run "# sudo cp ${CONTAINER_DIR}/jessie_armhf/root/linux-sunxi/arch/arm/boot/uImage ${mnt}/"
  fi
}

copy_in_script_bin(){
  # Only need on jessie.
  if [ z${DISTRIBUTION} = "zjessie" ]; then
    debug "Copy in script.bin ..."
    run "sudo cp ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/fex_configuration/bin/banana_pro_7lcd.bin ${mnt}/script.bin"
  fi
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

# Name of the image, the file is located in script dir,
# or can given with the "output_dir" parameter
IMAGE_NAME=xmz-${DISTRIBUTION}-baseimage.img
# Image size in mega byte
IMAGE_SIZE_MB=3000



create_loop_device

create_loop_device_with_offset

write_bootloader

create_boot_script

uboot_splash

copy_in_kernel

copy_in_script_bin

cleanup_mount

cleanup_loop_devices
