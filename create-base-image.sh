#!/bin/bash
# Setup the build environment
# This script is heavy inspired by the one from: http://www.tomaz.me/2013/12/02/running-travis-ci-tests-on-arm.html
SCRIPTVERSION=0.4.1
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
function echo_b { echo ${bold}$1${normal}; }

MIRROR=http://ftp.debian.org/debian
VERSION=sid
CHROOT_ARCH=armhf

# Debian package dependencies for the host
HOST_DEPENDENCIES="debootstrap qemu-user-static binfmt-support"

# Debian package dependencies fot the chroot environment
GUEST_DEPENDENCIES="debian-archive-keyring build-essential git m4 python openssh-server"


function show_help {
echo
echo `basename $0` "[-o|--output_dir]"
echo
echo
echo_b Arguments:
echo "-o | --output_dir 		Path were the base image should created."
echo
echo_b "Script Version: ${SCRIPTVERSION}"
}

# This function set up a folder via the chroot tool.
# This is the first function called on a vanilla system.
# On finish the function touches a .chroot_is_done file to root /
# this file indicates that this function was running.
# TODO: Ensure /.chroot_is_done is only created on success!
function setup_arm_chroot {
# Host dependencies
echo_b "update apt (amd64) ..."
sudo apt-get -qq -y update
sudo apt-get install -qq -y ${HOST_DEPENDENCIES}
# Create chrooted environment
echo_b "create chroot dir ..."
sudo mkdir -pv ${CHROOT_DIR}
echo_b "debootstrap ..."
sudo debootstrap --foreign --no-check-gpg --include=fakeroot,build-essential \
	--arch=${CHROOT_ARCH} ${VERSION} ${CHROOT_DIR} ${MIRROR} >/dev/null
echo_b "copy qemu-arm-static files in image ..."
sudo cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/
echo_b "debootrap --second-stage ..."
sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage >/dev/null
# Install dependencies inside chroot
echo_b "configure apt (armhf) ..."
sudo chroot ${CHROOT_DIR} bash -c "echo \"deb ${MIRROR} ${VERSION} main contrib non-free\" >/etc/apt/sources.list"
echo_b "update apt (armhf) ..."
sudo chroot ${CHROOT_DIR} apt-get update -qq -y
sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install \
	-qq -y ${GUEST_DEPENDENCIES} >/dev/null
echo_b "Dir arm-chroot is ready ..."
# Indicate chroot environment has been set up
sudo touch ${CHROOT_DIR}/.chroot_is_done
}



function config_chroot {
echo_b "Configure chroot"
echo_b "Update apt ..."
sudo chroot ${CHROOT_DIR} bash -c "apt-get update -qq -y && apt-get dist-upgrade -qq -y"
echo_b "Install OpenSSH ..."
sudo chroot ${CHROOT_DIR} bash -c "/etc/init.d/ssh stop"

sudo chroot ${CHROOT_DIR} bash -c "echo "root:930440Hk"|chpasswd"
sudo chroot ${CHROOT_DIR} bash -c "echo xmz_mod > /etc/hostname"
sudo chroot ${CHROOT_DIR} bash -c "cat <<EOF >/etc/modules
ap6210
ft5x_ts
EOF"

sudo chroot ${CHROOT_DIR} bash -c "apt-get install -qq -y wpasupplicant net-tools wireless-tools isc-dhcp-client"
sudo chroot ${CHROOT_DIR} bash -c "cat <<EOF >/etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
ssid=\"KLS-GMBH\"
#psk=\"kliemann-service001\"
id_str=\"work\"
psk=934f6f4a332dfc60c236c6b0603d9cb6df363a35881d3c293f2144cc3fc52003
}

network={
ssid=\"Southhost\"
id_str=\"home\"
#psk=\"asrael666\"
psk=1fb43eea04aa313297fac210ac83e85935590b03566de26ad46c3d379fd15c04
}
EOF"

echo_b "Configure network ..."
sudo chroot ${CHROOT_DIR} bash -c "cat <<EOF >/etc/network/interfaces
# /etc/network/interfaces
auto lo
iface lo inet loopback

allow-hotplug wlan0
auto wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
EOF"

#     echo_b "Enable autologin tty via systemd ..."
#     sudo chroot ${CHROOT_DIR} bash -c "mkdir -pv /etc/systemd/system/getty@tty1.service.d/"
#     sudo chroot ${CHROOT_DIR} bash -c "cat <<EOF >/etc/systemd/system/getty@tty1.service.d/autologin.conf
#   [Service]
#   ExecStart=
#   ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
#   EOF"

sudo chroot ${CHROOT_DIR} bash -c "apt-get install -qq -y zsh"
sudo chroot ${CHROOT_DIR} bash -c "chsh -s /bin/zsh"

sudo chroot ${CHROOT_DIR} bash -c "[ ! -d /root/.ssh ] && mkdir -pv /root/.ssh"
sudo chroot ${CHROOT_DIR} bash -c "cat <<EOF > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3Igwfs5fS9EPXDyHohTW72z4WfCu44nGl40j9wxqs/yn5Nc2csTILYJCRcZPB+I0qly+YlohCnQvd1/It2JWp8n2kGK1TS6Vy3C0IEWXSsvb4ZX5xFX699r9rlELOWOZyxHMeRByQ4pk2C+O0QiiUlJhYxdVA+IuoR0C+cfH+wGWW/MnSwni57znvrn5rZwrfgM4YWhMq+YUlHG+BgUb7MJ2wNSWfeuxUUItAu191WLSVFcyIox1ECQh2q8NrBPddufyfn9lRZK12TJu5JsCguDgMKGQeu3Y1m/BFbiBBy6vAh1ucgZto8zBR9b0HaNxwScsyxkNSxKtRYjUV2rIb smueller@nb-smueller
EOF"

echo_b "Update linux Kernelmodule ..."
sudo mkdir -pv ${CHROOT_DIR}/lib/modules
sudo cp -r ./linux-sunxi/output/lib ${CHROOT_DIR}

echo_b "cleanup apt (armhf) cache ..."
sudo chroot ${CHROOT_DIR} apt-get clean -qq -y

echo_b "Installation/ Update Finished."
sudo touch ${CHROOT_DIR}/.chroot_config_done
cat <<EOF
Image creation successful

export image=docker-image.img
export card=/dev/loop
export part="1"
sudo losetup /dev/loop\${part}0 \${image}
sudo losetup --offset $[2048 * 512] \${card}\${part}1 \${image}
sudo losetup --offset $[43008 * 512] \${card}\${part}2 \${image}

export mnt=/tmp/disk\${part}
[[ ! -d \${mnt} ]] && sudo mkdir \${mnt}
sudo mount \${card}\${part}2 \${mnt}
sudo rsync -av arm-chroot/ \${mnt}

sudo umount \${mnt}
sudo losetup -d /dev/loop${part}{0,1,2}
dd if=\${image} | pv | sudo dd of=/dev/mmcblk0 bs=1M
EOF

echo_b "Or Docker Import"
echo
echo "sudo tar -C ${CHROOT_DIR} -c . | docker import - ${CHROOT_DIR}"

}



# Main part of the script

# Option parser
getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:hv
LONG=output:,help,verbose

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
		-h|--help)
			show_help
			shift # past argument
			;;
		--)
			shift
			break
			;;
		*)
			echo "Error: unknown parameter" # unknown option
			exit 3
			;;
	esac
done

# Parameter setup
# If output dir is not given as parameter, use the current dir .
[ x"${OUTPUT_DIR}" = x ] && OUTPUT_DIR="."
CHROOT_DIR=${OUTPUT_DIR}/base-image-sid


if [ -e "${CHROOT_DIR}/.chroot_is_done" ]; then
	echo_b "Chroot is already present go to configure it ..."
	config_chroot
else
	echo_b "Setting up the chroot environment"
	setup_arm_chroot
	config_chroot
fi


