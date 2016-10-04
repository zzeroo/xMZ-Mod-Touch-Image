#!/bin/bash
# In diesem Script sind alle Aufgaben zusammengefasst die mit der Einrichtung
# des Betriebssystems und der Betriebssystem Dienste zu tun haben.
#
# Exit on error or variable unset
set -o errexit -o nounset

# Variablen

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.5.1"-$(git rev-parse --short HEAD)


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"
# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:


enable_apt_non_free(){
  debug "Aktiviere 'contrib non-free' Apt Repos ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/apt/sources.list
# deb http://httpredir.debian.org/debian sid main contrib non-free
# deb http://ftp.de.debian.org/debian sid main contrib non-free
# deb http://ftp.de.debian.org/debian sid main # geht nicht da die WLAN Treiber nur in sind sind
deb http://ftp.de.debian.org/debian unstable main contrib non-free 
EOF"
}

install_dependencies(){
  debug "Install dependencies ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get update && apt-get upgrade -y\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y zsh tmux git curl\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y aptitude build-essential pkg-config libusb-1.0-0-dev zlib1g-dev\""
}

setup_locales() {
  debug "Richte Timezone und Locale ein ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y locales\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"echo \"Europe/Berlin\" > /etc/timezone\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"dpkg-reconfigure --frontend=noninteractive tzdata\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"echo 'LANG=\"de_DE.UTF-8\"'>/etc/default/locale\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"dpkg-reconfigure --frontend=noninteractive locales\""
}

disable_systemd_logging_to_disk() {
  debug "Disable logging to disk ..."
  run "# http://bikealive.nl/tips-tricks.html"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"echo \"Storage=volatile\" >> /etc/systemd/journald.conf\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"echo \"SystemMaxUse=2M\" >> /etc/systemd/journald.conf\""
}

disable_getty(){
	debug "Disable getty's ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"systemctl disable getty@.service\""
}

setup_fstab(){
  debug "Setup fstab ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/fstab
/dev/mmcblk0p2 / btrfs rw,relatime,ssd,noacl,space_cache,subvolid=5,subvol=/ 0 0
EOF"
}

# TODO: Obsolete? Brauchen wir das noch?
disable_screenblank(){
  debug "disable screen blanking ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/issue
\033[9;0]
EOF"
}

# TODO Make hostname dynamic
setup_hostname() {
  debug "Set hostname ..."
  run "echo ${DEFAULT_HOSTNAME} | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/hostname"
}

install_wlan_tools(){
  debug "Installiere WLAN Subsystem ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} apt-get install -y wpasupplicant net-tools wireless-tools isc-dhcp-client firmware-brcm80211"
}

setup_wlan(){
  debug "Configure wlan subsystem ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/wpa_supplicant/wpa_supplicant.conf
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

network={
        ssid=\"pinky\"
        #psk=\"eeepcwlanAThome2016\"
        psk=150271e402147111d16e4aaaa952adac37567323eb0b40642478e9d0fb1fe359
}
EOF"
}

setup_network_interfaces(){
  debug "Seting up network interfaces ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/network/interfaces
# /etc/network/interfaces
auto lo
iface lo inet loopback

# auto eth0
# iface eth0 inet dhcp

# auto eth0:1
# iface eth0:1 inet static
#   address 192.168.1.65
#   netmask 255.255.255.0

auto wlan0
allow-hotplug wlan0
iface wlan0 inet manual
  wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

iface default inet dhcp
EOF"
}

install_ssh_server(){
  debug "Install OpenSSH Server ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} apt-get install -y openssh-server"
}

setup_remote_access(){
  debug "Confiure remote access via ssh ..."
  run "sudo mkdir ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/.ssh"
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3Igwfs5fS9EPXDyHohTW72z4WfCu44nGl40j9wxqs/yn5Nc2csTILYJCRcZPB+I0qly+YlohCnQvd1/It2JWp8n2kGK1TS6Vy3C0IEWXSsvb4ZX5xFX699r9rlELOWOZyxHMeRByQ4pk2C+O0QiiUlJhYxdVA+IuoR0C+cfH+wGWW/MnSwni57znvrn5rZwrfgM4YWhMq+YUlHG+BgUb7MJ2wNSWfeuxUUItAu191WLSVFcyIox1ECQh2q8NrBPddufyfn9lRZK12TJu5JsCguDgMKGQeu3Y1m/BFbiBBy6vAh1ucgZto8zBR9b0HaNxwScsyxkNSxKtRYjUV2rIb smueller@nb-smueller
EOF"
}


# Main part of the script
enable_apt_non_free

install_dependencies

setup_locales

disable_systemd_logging_to_disk

disable_getty

setup_fstab

disable_screenblank

setup_hostname

install_wlan_tools

setup_wlan

setup_network_interfaces

install_ssh_server

setup_remote_access

_GENERIC_create_btrfs_snapshot
