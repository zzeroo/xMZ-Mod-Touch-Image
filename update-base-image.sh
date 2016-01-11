#!/bin/bash
# Setup the build environment
# This script is heavy inspired by the one from: http://www.tomaz.me/2013/12/02/running-travis-ci-tests-on-arm.html
SCRIPTVERSION=0.4.5
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
function echo_b { echo ${bold}$1${normal}; }
function error { echo ${bold}${@}${normal}; exit 1; }

CHROOT_DIR=./base-image-sid

function in_chroot { sudo chroot ${CHROOT_DIR} bash -c "${@}"; }

alias make="make -j`getconf _NPROCESSORS_ONLN`"


# START
echo_b "Script version: $SCRIPTVERSION"

echo_b "Testing ${CHROOT_DIR} ..."
test -d ${CHROOT_DIR} || error "${CHROOT_DIR} not found!"
echo_b "Versioning ${CHROOT_DIR} ..."
sudo cp -r ${CHROOT_DIR} ${CHROOT_DIR}-${SCRIPTVERSION}
CHROOT_DIR=${CHROOT_DIR}-${SCRIPTVERSION}
echo "New chroot dir is: ${CHROOT_DIR}"

echo_b "Update apt repo ..."
in_chroot "cat >/etc/apt/sources.list" <<'EOF'
deb http://ftp.de.debian.org/debian unstable main contrib non-free
EOF
in_chroot "apt-get update -qq -y && apt-get dist-upgrade -qq -y" || error "apt-get update failed!"

# FIXME: This should made in the stage-1 script
echo_b "Enable mali drivers"
in_chroot "cat >>/etc/modules" <<'EOF'
mali
ump
mali_drm
EOF

# FIXME: Because of so oft falling 'git clone' commands, I've append a '|| true' ob every git clone.
#        This solves even the problem to run the commands again on a no clean base-image path.
echo_b "Install needed software packages ..."
in_chroot "apt-get install -qq -y vim zsh tmux git curl"                        || error "apt-get installation faild!"
in_chroot "apt-get install -qq -y libgtk-3-dev valac libgee-0.8-dev \
  build-essential automake"                                                     || error "apt-get installation faild!"
in_chroot "apt-get install -qq -y weston"                                       || error "apt-get installation faild!"


echo_b "Setup dotfiles ..."
in_chroot "cd /root \
  && git clone https://github.com/zzeroo/.dotfiles.git || true \
  && cd .dotfiles \
  && ./install.sh"                                                              || error "Dotfiles failed!"


echo_b "Compile and install xMZ-Mod-Touch-GUI ..."
in_chroot "cd /root \
  && git clone https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git || true \
  && cd xMZ-Mod-Touch-GUI \
  && ./autogen.sh --prefix=/usr \
  && make install"                                                              || error "xMZ-Mod-Touch-GUI failed!"

echo_b "Setup weston ..."
in_chroot "mkdir -p /root/.config/"
in_chroot "cat >/root/.config/weston.ini" <<'EOF'
[core]
backend=fbdev-backend.so

[shell]
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

if test -z "${XDG_RUNTIME_DIR}"; then
    export XDG_RUNTIME_DIR="/run/shm/wayland"
    if ! test -d "${XDG_RUNTIME_DIR}"; then
        mkdir "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
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
Environment="XDG_RUNTIME_DIR=/run/shm/wayland"
Environment="GDK_BACKEND=wayland"
Environment="XMZ_HARDWARE=0.1.0"
ExecStart=/usr/bin/xmz-mod-touch-gui
Restart=always
RestartSec=10

[Install]
Alias=xmz.service
WantedBy=graphical.target
EOF
in_chroot "systemctl enable xmz-mod-touch-gui.service"


echo_b "END"
in_chroot "echo ${SCRIPTVERSION} >/root/xmz-mod-touch-gui-base-image-version"


