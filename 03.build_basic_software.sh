#!/bin/bash
# In diesem Script sind alle Schritte gesammelt die mit dem Basis Setup
# des Linux Betriebssystems und der Software Installation im Image
# zusammenhängen.
# Der erste Task dieses Skriptes legt ein btrfs Snapshot des systemd-containers
# an. In diesem werden dann die Aufgaben ausgeführt.
#
# Exit on error or variable unset
set -o errexit -o nounset

# Variablen

EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION="0.5.0"-$(git rev-parse --short HEAD)


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"
# include option parser
source "$(dirname $0)/lib/option_parser.sh" ||:


install_mesa(){
  debug "Install mesa ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} apt-get install -y libglapi-mesa libgles1-mesa libgles1-mesa-dev libgles2-mesa libgles2-mesa-dev libwayland-egl1-mesa libgles2-mesa"
}

install_weston(){
  debug "Install weston ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} apt-get install -y weston "
}

install_weston_wallpaper(){
  debug "Install weston wallpaper ..."
  run "sudo mkdir -p  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/usr/share/backgrounds/ra-gas/"
  run "sudo cp $(dirname $0)/share/Wallpaper-Desktop.png ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/usr/share/backgrounds/ra-gas/Wallpaper-Desktop.png"
  run "sudo chmod 644 ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/usr/share/backgrounds/ra-gas/Wallpaper-Desktop.png"
}

setup_weston(){
  debug "Setup weston ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/.config"
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/.config/weston.ini
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
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/etc/systemd/system/weston.service
[Unit]
Description=Weston launcher
RequiresMountsFor=/run
After=getty@tty1.service

[Service]
Restart=alway
RestartSec=10
User=root
EnvironmentFile=-/etc/default/weston
Environment=XDG_RUNTIME_DIR=/run/user/root
ExecStartPre=/bin/mkdir -p /run/user/root
ExecStartPre=/bin/chmod 0700 /run/user/root
ExecStart=/usr/bin/weston --tty=1 --log=/var/log/weston.log

[Install]
WantedBy=multi-user.target
EOF"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} systemctl enable weston.service"
}

# TODO Mach ein feines systemd unit file
create_weston_sh(){
  debug "Create weston.sh (weston start script) ..."
  run "cat <<-'EOF' | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/weston.sh
#!/bin/bash
#
# Weston startup file.
#   Dieses Script erstellt die Umgebung und startet weston
export XDG_CONFIG_HOME=\"/etc\"

if test -z \"\${XDG_RUNTIME_DIR}\"; then
    export XDG_RUNTIME_DIR=\"/run/user/root\"
    if ! test -d \"\${XDG_RUNTIME_DIR}\"; then
        mkdir \"\${XDG_RUNTIME_DIR}\"
        chmod 0700 \"\${XDG_RUNTIME_DIR}\"
    fi
fi

/usr/bin/weston --tty=1 --log=/var/log/weston.log
EOF"
  run "sudo chmod +x ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/weston.sh"
}

install_oh_my_zsh(){
  debug "Install oh-my-zsh ( https://github.com/robbyrussell/oh-my-zsh/ ) ..."
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y zsh git\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"sed -i '/env zsh/c\# env zsh' install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"chmod +x ./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"rm ./install.sh\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"sed -i '1s/^/DISABLE_UPDATE_PROMPT=\"true\"\n/' ~/.zshrc\""
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"sed -i '1s/^/DISABLE_AUTO_UPDATE=\"true\"\n/' ~/.zshrc\""
}

make_zsh_default(){
  debug "Make zsh default shell ..."
  run "sudo systemd-nspawn -D  ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"chsh -s /bin/zsh\""
}

install_rust(){
  debug "Install rust ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y curl git\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y\""
  run "echo export PATH="\\\$HOME/.cargo/bin:\\\$PATH"|sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH}/root/.zshrc"
}

install_libgtk_dev(){
  debug "Install libgtk-3-dev ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y libgtk-3-dev\""
}

install_libnanomsg(){
  debug "Install libnanomsg ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_${ARCH} /bin/bash -c \"apt-get install -y libnanomsg-dev\""
}



# Main part of the script
#install_mesa

install_weston

install_weston_wallpaper

setup_weston

setup_systemd_weston_unit

create_weston_sh

install_oh_my_zsh

make_zsh_default

install_rust

install_libgtk_dev

install_libnanomsg

_GENERIC_create_btrfs_snapshot
