#!/bin/bash
# In diesem Script sind alle Aufgaben zusammengefasst die mit der Einrichtung
# des Betriebssystems und der Betriebssystem Dienste zu tun haben.
#
# Exit on error or variable unset
set -o errexit -o nounset

# Setup Umgebung
export WLD=/usr
export LD_LIBRARY_PATH=$WLD/lib
export PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
export PATH=$WLD/bin:$PATH
export ACLOCAL_PATH=$WLD/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
mkdir -p $ACLOCAL_PATH
export MAKEFLAGS=$[`nproc` + 1] # max dynamic plus one

# libwayland:
## Vorbereitungen
apt-get update && apt-get dist-upgrade -y
apt install -y git autoconf libtool libffi-dev libexpat1-dev libxml2-dev

# wayland
cd
git clone git://anongit.freedesktop.org/wayland/wayland
cd wayland
./autogen.sh --prefix=$WLD --disable-documentation
# make check # geht nicht richtig unter quemu chroot
make && make install

# wayland-protocols
cd
git clone git://anongit.freedesktop.org/wayland/wayland-protocols
cd wayland-protocols
./autogen.sh --prefix=$WLD
# make check # geht nicht richtig unter quemu chroot
make && make install

# Libinput übersetzen
## Vorbereitungen
apt install -y libmtdev-dev libudev-dev libevdev-dev libwacom-dev

## libinput
cd
git clone git://anongit.freedesktop.org/wayland/libinput
cd libinput
./autogen.sh --prefix=$WLD
# make check # geht nicht richtig unter quemu chroot
make && make install


# Weston übersetzen
## Vorbereitungen
apt install -y libgles2-mesa-dev libxcb-composite0-dev libxcursor-dev \
libcairo2-dev libgbm-dev libpam0g-dev bison xkb-data # mesa-utils-extr

## xmacros
cd
git clone http://anongit.freedesktop.org/git/xorg/util/macros.git
cd macros
./autogen.sh --prefix=$WLD
make install

## libxcommon
cd
git clone http://github.com/xkbcommon/libxkbcommon
cd libxkbcommon
./autogen.sh --prefix=$WLD --enable-docs=no --disable-x11
make && make install

## weston
cd
git clone git://anongit.freedesktop.org/wayland/weston
cd weston
./autogen.sh --prefix=$WLD \
    --disable-x11-compositor --disable-drm-compositor \
    --disable-wayland-compositor --enable-weston-launch \
    --disable-libunwind --disable-colord --disable-resize-optimization \
    --disable-xwayland-test \
    --enable-clients --enable-demo-clients-install \
    WESTON_NATIVE_BACKEND="fbdev-backend.so"
# make check # geht nicht richtig unter quemu chroot
make && make install

echo "E N D! Weston successful builde from source."
