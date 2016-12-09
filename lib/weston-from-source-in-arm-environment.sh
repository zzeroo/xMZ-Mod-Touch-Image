#!/bin/bash
# In diesem Script sind alle Aufgaben zusammengefasst die mit der Einrichtung
# des Betriebssystems und der Betriebssystem Dienste zu tun haben.
#
# Exit on error or variable unset
set -o errexit -o nounset

# Setup Umgebung
export WLD=/usr
#export LD_LIBRARY_PATH=$WLD/lib
export LD_LIBRARY_PATH=$WLD/lib/arm-linux-gnueabihf
export PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
export PATH=$WLD/bin:$PATH
export ACLOCAL_PATH=$WLD/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
mkdir -p $ACLOCAL_PATH
export MAKEFLAGS=$[`nproc` + 1] # max dynamic plus one


# libwayland:
## Vorbereitungen
apt-get update && apt-get upgrade -y
apt install -y git autoconf libtool libffi-dev libexpat1-dev libxml2-dev

# wayland
cd
[ ! -d wayland ] && git clone git://anongit.freedesktop.org/wayland/wayland && cd wayland
[ -d wayland ] && cd wayland && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc --disable-documentation
# make check
make && make install

# wayland-protocols
cd
[ ! -d wayland-protocols ] && git clone git://anongit.freedesktop.org/wayland/wayland-protocols && cd wayland-protocols
[ -d wayland-protocols ] && cd wayland-protocols && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc
# make check
make && make install

# Libinput übersetzen
## Vorbereitungen
apt install -y libmtdev-dev libudev-dev libevdev-dev libwacom-dev

## libinput
cd
[ ! -d libinput ] && git clone git://anongit.freedesktop.org/wayland/libinput && cd libinput
[ -d libinput ] && cd libinput && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc
# make check
make && make install


# Weston übersetzen
## Vorbereitungen
apt install -y libgles2-mesa-dev libxcb-composite0-dev libxcursor-dev \
libcairo2-dev libgbm-dev libpam0g-dev bison xkb-data # mesa-utils mesa-utils-extra

## xmacros
cd
[ ! -d macros ] && git clone http://anongit.freedesktop.org/git/xorg/util/macros.git && cd macros
[ -d macros ] && cd macros && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc
make install

## libxcommon
cd
[ ! -d libxkbcommon ] && git clone http://github.com/xkbcommon/libxkbcommon && cd libxkbcommon
[ -d libxkbcommon ] && cd libxkbcommon && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc --enable-docs=no --disable-x11
make && make install

## weston
cd
[ ! -d weston ] && git clone git://anongit.freedesktop.org/wayland/weston && cd weston
[ -d weston ] && cd weston && git pull ||:
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc \
    --disable-x11-compositor --disable-drm-compositor \
    --disable-wayland-compositor --enable-weston-launch \
    --disable-libunwind --disable-colord --disable-resize-optimization \
    --disable-xwayland-test \
    --enable-clients --enable-demo-clients-install \
    WESTON_NATIVE_BACKEND="fbdev-backend.so"
# make check
make && make install

echo "E N D! Weston successful builde from source."
