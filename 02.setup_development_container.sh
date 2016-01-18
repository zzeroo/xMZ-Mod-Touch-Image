#!/bin/bash
#
# This script set up the systemd-nspawn development container
#
EXAMPLE="./`basename $0` -s"
#
# Parameters
# script verion, imcrement on change
SCRIPTVERSION=0.1.9


# include generic functions (echo_b(), and debug() and so on)
source "$(dirname $0)/lib/generic_functions.sh"



# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development
# sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/ && /bin/bash ./configure --prefix=/usr\"

install_dependencies(){
  debug "Install dependencies for tools and kernel ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y build-essential pkg-config u-boot-tools libusb-1.0-0-dev git wget fakeroot kernel-package zlib1g-dev libncurses5-dev"
}

# # OPTION1: all files in so named Board Support Package (BSP), NOT USED!
# build_bsp(){
#   debug "Board Support Package ..."
#   run "# https://github.com/LeMaker/lemaker-bsp"
# 	run "cd ${OUTPUT_DIR}"
# 	run "git clone https://github.com/LeMaker/lemaker-bsp.git || exit"
# 	run "cd lemaker-bsp"
# 	run "./configure BananaPro"
# 	run "make"
# }

# OPTION2: All following function are Option2, manual packege selection
build_uboot(){
  debug "Build U-Boot, boot loader ..."
  run "# https://github.com/LeMaker/u-boot-sunxi"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d u-boot-sunxi ]] && git clone https://github.com/LeMaker/u-boot-sunxi.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make BananaPro_config\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/u-boot-sunxi && make -j$(nproc)\""
}

build_sunxi_tools(){
  debug "Build sunxi tools a.k.a. sun4i ..."
  run "# https://github.com/LeMaker/sunxi-tools"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d sunxi-tools  ]] && git clone https://github.com/LeMaker/sunxi-tools.git || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/sunxi-tools && make -j$(nproc)\""
}

build_sunxi_boards(){
  debug "Fetch sunxi boards repo ..."
  run "# https://github.com/LeMaker/sunxi-boards"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d sunxi-boards ]] && git clone https://github.com/LeMaker/sunxi-boards.git || true\""
}

get_fex_configuration(){
  debug "Fetch fex_configuration files (fex and bin) ..."
  run "# https://github.com/LeMaker/fex_configuration"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d fex_configuration ]] && git clone https://github.com/LeMaker/fex_configuration.git || true\""
}

build_linux_kernel(){
  debug "Fetch and build the linux kernel ..."
  run "# https://github.com/LeMaker/linux-sunxi"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d linux-sunxi ]] && git clone https://github.com/LeMaker/linux-sunxi.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make sun7i_defconfig\""
  run "# FIXME: Include custom config"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make -j$(nproc) uImage modules\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/linux-sunxi && make INSTALL_MOD_PATH=output modules_install\""
}

build_libmodbus(){
  debug "Fetch and build libmodbus ..."
  run "# https://github.com/stephane/libmodbus.git"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y autoconf git-core build-essential libtool"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d libmodbus ]] && git clone https://github.com/stephane/libmodbus.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && ./autogen.sh\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && ./configure --prefix=/usr\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && make -j$(nproc)\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/libmodbus && make install\""
}

build_xmz(){
  debug "Fetch and build the xMZ-Mod-Touch GUI ..."
  run "# https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y intltool libgtk-3-dev gsettings-desktop-schemas-dev libgee-dev libsqlite3-dev libgirepository1.0-dev gnome-common valac"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d xMZ-Mod-Touch-GUI ]] && git clone https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git --depth=1 || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && git pull\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && ./autogen.sh --prefix=/usr\""
  run "# -j$(nproc) dosn't work!\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make dist\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/xMZ-Mod-Touch-GUI && make install\""
}

setup_systemd_xmz_unit(){
  debug "Configure systemd to autostart xMZ-Mod-Touch-GUI ..."
  run "echo \"
    #
    # xmz-mod-touch-gui systemd service unit file
    #

    [Unit]
    Description=xMZ-Mod_Touch launcher
    # Wants=syslog.target dbus.service
    After=weston.service

    [Service]
    Environment=\"XDG_RUNTIME_DIR=/run/shm/wayland\"
    Environment=\"GDK_BACKEND=wayland\"
    Environment=\"XMZ_HARDWARE=0.1.0\"
    ExecStart=/usr/bin/xmz
    Restart=always
    RestartSec=10

    [Install]
    Alias=xmz.service
    WantedBy=graphical.target\" | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/etc/systemd/system/xmz-mod-touch-gui.service"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development systemctl enable xmz-mod-touch-gui.service"
}

enable_mali_drivers(){
  debug "Enable mali drivers ..."
  run "echo \"
  mali
  ump
  mali_drm\" | sudo tee -a ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/etc/modules"
}

install_weston(){
  debug "Install weston ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -y weston"
}

setup_weston(){
  debug "Setup weston ..."
  run "sudo mkdir -p ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/.config"
  run "echo \"
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
    command=/usr/bin/weston --backend=rdp-backend.so --shell=fullscreen-shell.so --no-clients-resize\" | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/.config/weston.ini"
}

setup_systemd_weston_unit(){
  debug "Configure systemd to autostart weston ..."
  run "echo \"
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
    WantedBy=graphical.target\" | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/etc/systemd/system/weston.service"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development systemctl enable weston.service"
}

create_weston_sh(){
  debug "Create weston.sh (weston start script) ..."
  run "echo \"
    #!/bin/bash
    #
    # Weston startup file.
    #   Dieses Script erstellt die Umgebung und startet weston
    export XDG_CONFIG_HOME=\"/etc\"
    export XORGCONFIG=\"/etc/xorg.conf\"

    if test -z \"${XDG_RUNTIME_DIR}\"; then
        export XDG_RUNTIME_DIR=\"/run/shm/wayland\"
        if ! test -d \"${XDG_RUNTIME_DIR}\"; then
            mkdir \"${XDG_RUNTIME_DIR}\"
            chmod 0700 \"${XDG_RUNTIME_DIR}\"
        fi
    fi

    /usr/bin/weston --tty=1 --log=/var/log/weston.log \" | sudo tee ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development/root/weston.sh"
  run "chmod +x ${CONTAINER_DIR}/${DISTRIBUTION}/root/weston.sh"
}


setup_dotfiles(){
  debug "Setup dotfiles ..."
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development apt-get install -qq -y vim zsh tmux git curl"
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root && [[ ! -d .dotfiles ]] && git clone https://github.com/zzeroo/.dotfiles.git || true\""
  run "sudo systemd-nspawn -D ${CONTAINER_DIR}/${DISTRIBUTION}_armhf-development /bin/bash -c \"cd /root/.dotfiles && ./install.sh\""
}



# Main part of the script

# include option parser
source "$(dirname $0)/lib/option_parser.sh"



install_dependencies

# Option 1 BSP
# build_bsp

# Option 2
build_uboot

build_sunxi_tools

build_sunxi_boards

get_fex_configuration

build_linux_kernel

build_libmodbus

build_xmz

setup_systemd_xmz_unit

enable_mali_drivers

install_weston

setup_weston

setup_systemd_weston_unit

create_weston_sh

setup_dotfiles

