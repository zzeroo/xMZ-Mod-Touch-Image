# Als root filesystem dient das Dateisystem Image aus dem auch das Baseimage gebaut wird
sudo btrfs subvolume snapshot /var/lib/container/sid_armhf /var/lib/container/sid_armhf-crosscompile-environment
export ROOTFS="/var/lib/container/sid_armhf-crosscompile-environment"

# Jetzt wechseln wir in das Root Filesystem und installieren die Abhängigkeiten
sudo systemd-nspawn -D $ROOTFS
apt-get update && apt-get upgrade -y
apt install -y git autoconf libtool libffi-dev libexpat1-dev libxml2-dev


./autogen.sh --prefix=$SYSROOT --libdir=/usr/lib --sysconfdir=/etc --disable-documentation \
  --host=arm-linux-gnueabihf

# !!Wieder auf dem Build System
# wayland
cd
[ ! -d wayland ] && git clone git://anongit.freedesktop.org/wayland/wayland && cd wayland
[ -d wayland ] && cd wayland && git pull ||:
# ./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc --disable-documentation --disable-scanner --build=arm-linux --host=arm-linux-gnueabihf --with-header=$ROOTFS/usr/include
./autogen.sh --prefix=$WLD --libdir=/usr/lib --sysconfdir=/etc --disable-documentation \
  --build=arm-linux --host=arm-linux-gnueabihf \
  PKG_CONFIG_PATH=$ROOTFS/usr/lib/arm-linux-gnueabihf/pkgconfig \
  PKG_CONFIG_LIBDIR=$ROOTFS/usr/lib/arm-linux-gnueabihf \
  CPPFLAGS=-I$ROOTFS/usr/include/arm-linux-gnueabihf \
  LDFLAGS=-L$ROOTFS/usr/lib/arm-linux-gnueabihf \
  LD_LIBRARY_PATH=$ROOTFS/usr/lib/arm-linux-gnueabihf

make
make ARCH=arm CROSS_COMPILE=$ROOTFS/usr/bin/arm-linux-gnueabihf-


SYSROOT="$ROOTFS" \
INCLUDEDIR="$ROOTFS/usr/include/arm-linux-gnueabihf" \
LIBDIR="$ROOTFS/usr/lib/arm-linux-gnueabihf" \
BINDIR="$ROOTFS/usr/bin" \
make ARCH=arm CROSS_COMPILE=$ROOTFS/usr/bin/arm-linux-gnueabihf-

make ARCH=arm CROSS_COMPILE=$ROOTFS/usr/bin/arm-linux-gnueabihf- \
CC="/usr/bin/arm-linux-gnueabihf-gcc --sysroot=$ROOTFS \
-I$ROOTFS/usr/include/arm-linux-gnueabihf \
-L$ROOTFS/usr/lib/arm-linux-gnueabihf \
-B$ROOTFS/usr/bin"
