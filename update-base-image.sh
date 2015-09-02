#!/bin/bash
# Setup the build environment
# This script is heavy inspired by the one from: http://www.tomaz.me/2013/12/02/running-travis-ci-tests-on-arm.html
SCRIPTVERSION=0.3.5
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
function echo_b { echo ${bold}$1${normal}; }
function error { echo ${bold}${@}${normal}; exit 1; }

CHROOT_DIR=./base-image-sid

function in_chroot { sudo chroot ${CHROOT_DIR} bash -c "${@}"; }

alias make="make -j`getconf _NPROCESSORS_ONLN`"

test -d ${CHROOT_DIR} || error "${CHROOT_DIR} not found!"

echo_b "Script version: $SCRIPTVERSION"
echo_b "Update apt repo ..."
in_chroot "apt-get update -qq -y && apt-get dist-upgrade -qq -y"

echo_b "Install needed software packages ..."
in_chroot "apt-get install -qq -y vim zsh tmux git curl"
in_chroot "apt-get install -qq -y libgtk-3-dev valac build-essential automake"
in_chroot "apt-get install -qq -y weston"

echo_b "Setup dotfiles ..."
in_chroot "cd /root \
  && git clone https://github.com/zzeroo/.dotfiles.git \
  && cd .dotfiles \
  && ./install.sh"

echo_b "Compile and install xMZ-Mod-Touch-GUI ..."
in_chroot "cd /root \
  && git clone https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git \
  && cd xMZ-Mod-Touch-GUI \
  && ./autogen.sh --prefix=/usr \
  && make install"

echo_b "Setup weston ..."
in_chroot "mkdir -p /root/.config/"
in_chroot "cat >/root/.config/weston.ini" <<'EOF'
[core]

[shell]
panel-location=none
locking=false
animation=zoom
startup-animation=fade

[input-method]
path=/usr/lib/weston/weston-keyboard
path=/usr/lib/ibus/ibus-wayland

[libinput]
enable_tap=true

[screen-share]
command=/usr/bin/weston --backend=rdp-backend.so --shell=fullscreen-shell.so --no-clients-resize
EOF

echo_b "Configure systemd to autostart weston ..."
in_chroot "cat >/etc/systemd/system/weston.service" <<'EOF'
#
# weston systemd service unit file
#

[Unit]
Description=Weston launcher
# Wants=syslog.target dbus.service
After=systemd-user-sessions.service

[Service]
Environment=PATH=/usr/bin:/bin:/usr/sbin:/sbin
Environment=HOME=/root
ExecStart=/root/weston.sh
Restart=always
RestartSec=10

[Install]
Alias=display-manager.service
WantedBy=graphical.target
EOF
in_chroot "systemctl enable weston.service"

in_chroot "cat >/root/weston.sh" <<'EOF'
#!/bin/bash
#
# Weston startup file.
#   Dieses Script erstellt die Umgebung und startet weston
export XDG_CONFIG_HOME="/etc"
export XORGCONFIG="/etc/xorg.conf"

if test -z "\${XDG_RUNTIME_DIR}"; then
    export XDG_RUNTIME_DIR="/run/shm/wayland"
    if ! test -d "\${XDG_RUNTIME_DIR}"; then
        mkdir "\${XDG_RUNTIME_DIR}"
        chmod 0700 "\${XDG_RUNTIME_DIR}"
    fi
fi

/usr/bin/weston --tty=1 --log=/var/log/weston.log
EOF
in_chroot "chmod +x /root/weston.sh"


echo_b "Configure systemd to autostart xMZ-Mod-Touch-GUI ..."
in_chroot "cat >/etc/systemd/system/xmz-mod-touch-gui.service" <<'EOF'
#
# xmz-mod-touch-gui systemd service unit file
#

[Unit]
Description=xMZ-Mod_Touch launcher
# Wants=syslog.target dbus.service
After=weston.service

[Service]
Environment=XDG_RUNTIME_DIR=/run/shm/wayland
Environment=PATH=/usr/bin:/bin:/usr/sbin:/sbin
Environment=HOME=/root
ExecStart=/usr/bin/xmz-mod-touch-gui
Restart=always
RestartSec=10

[Install]
Alias=xmz-mod-touch.service
WantedBy=graphical.target
EOF
in_chroot "systemctl enable xmz-mod-touch-gui.service"

echo_b "END"
in_chroot "cat >/root/done" <<'EOF'
It's done well!
EOF

