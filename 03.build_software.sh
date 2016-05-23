#!/bin/bash

#
# This script set up the systemd-nspawn development container
#
EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.2.1


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"



install_dependencies(){
  debug "Install dependencies ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"apt-get update && apt-get upgrade -y\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y zsh tmux git curl"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y aptitude build-essential pkg-config libusb-1.0-0-dev zlib1g-dev"
}

setup_locales() {
	debug "Setup german locales ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"apt-get install -y locales\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"locale-gen --purge de_DE.UTF-8\""
	run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo -e 'LANG=\"de_DE.UTF-8\"\nLANGUAGE=\"de_DE:en\"\n' > /etc/default/locale\""
}


enable_mali_drivers(){
  debug "Enable mali drivers ..."
  if [ z${DISTRIBUTION} = "zjessie" ]; then
  run "cat <<-'EOF' | sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/modules
mali
ump
mali_drm
EOF"
  fi
}

install_mesa(){
  debug "Install mesa ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y libglapi-mesa libgles1-mesa libgles1-mesa-dev libgles2-mesa libgles2-mesa-dev libwayland-egl1-mesa libgles2-mesa"
}

install_weston(){
  debug "Install weston ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y weston "
}

install_weston_wallpaper(){
  debug "Install weston wallpaper ..."
  run "sudo mkdir -p  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/usr/share/backgrounds/ra-gas/"
  run "sudo cp $(dirname $0)/share/Wallpaper-Desktop.png ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/usr/share/backgrounds/ra-gas/Wallpaper-Desktop.png"
  run "sudo chmod 644 ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/usr/share/backgrounds/ra-gas/Wallpaper-Desktop.png"
}

setup_weston(){
  debug "Setup weston ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.config"
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.config/weston.ini
[core]
backend=fbdev-backend.so
idle-time=0

[shell]
background-image=/usr/share/backgrounds/ra-gas/Wallpaper-Desktop.png
background-type=tile
panel-location=none
locking=false
animation=zoom
startup-animation=fade

[input-method]
path=/usr/lib/weston/weston-keyboard

[libinput]
enable_tap=true

[screen-share]
command=/usr/bin/weston --backend=rdp-backend.so --shell=fullscreen-shell.so --no-clients-resize
EOF"
}

setup_systemd_weston_unit(){
  debug "Configure systemd to autostart weston ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/systemd/system/weston.service
[Unit]
Description=Weston launcher
After=getty@tty1.service

[Service]
Environment=PATH=/usr/bin:/bin:/usr/sbin:/sbin
Environment=HOME=/root
ExecStart=/root/weston.sh
Restart=always
RestartSec=10

[Install]
Alias=display-manager.service
WantedBy=graphical.target
EOF"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf systemctl enable weston.service"
}

create_weston_sh(){
  debug "Create weston.sh (weston start script) ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/weston.sh
#!/bin/bash
#
# Weston startup file.
#   Dieses Script erstellt die Umgebung und startet weston
export XDG_CONFIG_HOME=\"/etc\"
export XORGCONFIG=\"/etc/xorg.conf\"

if test -z \"\${XDG_RUNTIME_DIR}\"; then
    export XDG_RUNTIME_DIR=\"/run/shm/wayland\"
    if ! test -d \"\${XDG_RUNTIME_DIR}\"; then
        mkdir \"\${XDG_RUNTIME_DIR}\"
        chmod 0700 \"\${XDG_RUNTIME_DIR}\"
    fi
fi

/usr/bin/weston --tty=1 --log=/var/log/weston.log
EOF"
  run "sudo chmod +x ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/weston.sh"
}
disable_getty(){
  if [ z${DISTRIBUTION} = "zsid" ]; then
    debug "Disable getty's ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"systemctl disable getty@.service\""
  fi
}
setup_hostname() {
  debug "Set hostname ..."
  run "echo xmz-mod-touch | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/hostname"
}
install_wlan(){
  debug "Install wlan subsystem ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y wpasupplicant net-tools wireless-tools isc-dhcp-client"
}
install_wlan_firmware(){
  if [ z${DISTRIBUTION} = "zsid" ]; then
    debug "Install Broadcom Firmware ..."
    run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/lib/firmware/brcm"
    run "sudo wget -O ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/lib/firmware/brcm/brcmfmac43362-sdio.txt http://dl.cubieboard.org/public/Cubieboard/benn/firmware/ap6210/nvram_ap6210.txt"
  fi
}
setup_wlan(){
  debug "Configure wlan subsystem ..."
  if [ z${DISTRIBUTION} = "zjessie" ]; then
    run "echo ap6210 | sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/modules"
  fi
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/wpa_supplicant/wpa_supplicant.conf
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
}
setup_network_interfaces(){
  debug "Seting up network interfaces ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/network/interfaces
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
   run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y openssh-server"
}

setup_remote_access(){
  debug "Confiure remote access via ssh ..."
  run "sudo mkdir ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.ssh"
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3Igwfs5fS9EPXDyHohTW72z4WfCu44nGl40j9wxqs/yn5Nc2csTILYJCRcZPB+I0qly+YlohCnQvd1/It2JWp8n2kGK1TS6Vy3C0IEWXSsvb4ZX5xFX699r9rlELOWOZyxHMeRByQ4pk2C+O0QiiUlJhYxdVA+IuoR0C+cfH+wGWW/MnSwni57znvrn5rZwrfgM4YWhMq+YUlHG+BgUb7MJ2wNSWfeuxUUItAu191WLSVFcyIox1ECQh2q8NrBPddufyfn9lRZK12TJu5JsCguDgMKGQeu3Y1m/BFbiBBy6vAh1ucgZto8zBR9b0HaNxwScsyxkNSxKtRYjUV2rIb smueller@nb-smueller
EOF"
}

# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"



install_dependencies

setup_locales

#enable_mali_drivers

#install_mesa

install_weston

install_weston_wallpaper

setup_weston

setup_systemd_weston_unit

create_weston_sh

setup_hostname

install_wlan

install_wlan_firmware

setup_wlan

setup_network_interfaces

install_ssh_server

setup_remote_access
