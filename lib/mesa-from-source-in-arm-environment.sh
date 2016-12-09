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

apt-get install -y ccache
export PATH=/usr/lib/ccache:$PATH


# drm Abhängigkeit
echo -e "Installiere xorg-macros"
cd
[ ! -d macros ] && git clone git://anongit.freedesktop.org/git/xorg/util/macros
cd macros
git pull
./autogen.sh --prefix=$WLD
make && make install

cd
[ ! -d drm ] && git clone git://anongit.freedesktop.org/mesa/drm
cd drm
git pull
./autogen.sh --prefix=$WLD
# ./autogen.sh --prefix=$WLD \
#     --disable-radeon \
#     --disable-amdgpu \
#     --disable-nouveau
make && make install

apt-get install -y bison flex python-pip libudev-dev

pip install mako

cd
[ ! -d mesa ] && git clone git://anongit.freedesktop.org/mesa/mesa
cd mesa
git pull
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc \
    --enable-gles2 --disable-gallium-egl \
    --with-egl-platforms=wayland \
    --with-dri-drivers=swrast --without-gallium-drivers \
    --disable-dri3
make && make install
