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



enable_apt_non_free(){
  debug "Aktiviere 'contrib non-free' Apt Repos ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/apt/sources.list
deb http://httpredir.debian.org/debian sid main contrib non-free
EOF"
}

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
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/default/locale
LANG=\"de_DE.UTF-8\"
LANGUAGE=\"de_DE:de\"
Lde_DE.UTF-8_CTYPE=\"de_DE.UTF-8\"
LC_NUMERIC=\"de_DE.UTF-8\"
LC_TIME=\"de_DE.UTF-8\"
LC_COLLATE=\"de_DE.UTF-8\"
LC_MONETARY=\"de_DE.UTF-8\"
LC_MESSAGES=\"de_DE.UTF-8\"
LC_PAPER=\"de_DE.UTF-8\"
LC_NAME=\"de_DE.UTF-8\"
LC_ADDRESS=\"de_DE.UTF-8\"
LC_TELEPHONE=\"de_DE.UTF-8\"
LC_MEASUREMENT=\"de_DE.UTF-8\"
LC_IDENTIFICATION=\"de_DE.UTF-8\"
LC_ALL=C
EOF"
}

disable_systemd_logging_to_disk() {
  debug "Disable logging to disk ..."
  run "# http://bikealive.nl/tips-tricks.html"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo \"Storage=volatile\" >> /etc/systemd/journald.conf\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo \"SystemMaxUse=2M\" >> /etc/systemd/journald.conf\""
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

# TODO Mach ein feines systemd unit file
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
	debug "Disable getty's ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"systemctl disable getty@.service\""
}

# TODO Make hostname dynamic
setup_hostname() {
  debug "Set hostname ..."
  run "echo ${DEFAULT_HOSTNAME} | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/etc/hostname"
}

install_wlan_tools(){
  debug "Installiere WLAN Subsystem ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf apt-get install -y wpasupplicant net-tools wireless-tools isc-dhcp-client firmware-brcm80211"
}

setup_wlan(){
  debug "Configure wlan subsystem ..."
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

network={
        ssid=\"pinky\"
        #psk=\"eeepcwlanAThome2016\"
        psk=150271e402147111d16e4aaaa952adac37567323eb0b40642478e9d0fb1fe359
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

install_oh_my_zsh(){
  debug "Install oh-my-zsh ( https://github.com/robbyrussell/oh-my-zsh/ ) ..."
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"chmod +x ./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"rm ./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo DISABLE_UPDATE_PROMPT=\"true\">>/root/.zshrc\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"echo DISABLE_AUTO_UPDATE=\"true\">>/root/.zshrc\""
}

make_zsh_default(){
  debug "Make zsh default shell ..."
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"chsh -s /bin/zsh\""
}

install_rust(){
  debug "Install rust ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"apt-get install -y curl git\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"curl https://sh.rustup.rs -sSf > /root/rustup.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"chmod +x /root/rustup.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"./root/rustup.sh --default-toolchain nightly -y\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"rm /root/rustup.sh\""
  run "echo export PATH="\\\$HOME/.cargo/bin:\\\$PATH"|sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf/root/.zshrc"
}

install_libgtk_dev(){
  debug "Install libgtk-3-dev ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"apt-get install -y libgtk-3-dev\""
}

install_libnanomsg(){
  debug "Install libnanomsg ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf /bin/bash -c \"apt-get install -y libnanomsg-dev\""
}



# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:



enable_apt_non_free

install_dependencies

setup_locales

disable_systemd_logging_to_disk

#install_mesa

install_weston

install_weston_wallpaper

setup_weston

setup_systemd_weston_unit

create_weston_sh

setup_hostname

install_wlan_tools

setup_wlan

setup_network_interfaces

install_ssh_server

setup_remote_access

install_oh_my_zsh

make_zsh_default

install_rust

install_libgtk_dev

install_libnanomsg
